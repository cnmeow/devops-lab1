#!/bin/bash

# Deployment script for AWS CloudFormation modular approach
# This script uploads templates to S3 and deploys the CloudFormation stack

# Load configuration from config.env file
if [ -f "./config.env" ]; then
    echo "Loading configuration from config.env..."
    source ./config.env
else
    echo "Error: config.env file not found!"
    echo "Please create a config.env file with the required variables:"
    echo "BUCKET_NAME, STACK_NAME, REGION, KEY_PAIR_NAME, AVAILABILITY_ZONE, SSH_LOCATION"
    exit 1
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting deployment process...${NC}"

# Check if S3 bucket exists, create if not
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'
then
    echo -e "${YELLOW}Bucket does not exist. Creating S3 bucket: $BUCKET_NAME${NC}"
    aws s3 mb "s3://$BUCKET_NAME" --region $REGION
    # Make sure the bucket is created before continuing
    sleep 5
else
    echo -e "${GREEN}S3 bucket already exists: $BUCKET_NAME${NC}"
fi

# Upload templates to S3 bucket
echo -e "${YELLOW}Uploading CloudFormation templates to S3...${NC}"

# Use the files from approach-modular directory
aws s3 cp modules/ "s3://$BUCKET_NAME/modules/" --recursive --region $REGION
aws s3 cp main.yaml "s3://$BUCKET_NAME/" --region $REGION

echo -e "${GREEN}Templates uploaded successfully${NC}"

# Check if key pair exists, create if not
echo -e "${YELLOW}Checking if key pair '$KEY_PAIR_NAME' exists...${NC}"
if aws ec2 describe-key-pairs --key-names $KEY_PAIR_NAME --region $REGION 2>&1 | grep -q 'InvalidKeyPair.NotFound'; then
    echo -e "${YELLOW}Key pair '$KEY_PAIR_NAME' does not exist. Creating new key pair...${NC}"

    # Create a new key pair and save to file
    aws ec2 create-key-pair --key-name $KEY_PAIR_NAME --query 'KeyMaterial' --output text --region $REGION > $KEY_PAIR_NAME.pem

    # Set proper permissions for the key file
    chmod 400 $KEY_PAIR_NAME.pem

    echo -e "${GREEN}Key pair '$KEY_PAIR_NAME' created and saved to $KEY_PAIR_NAME.pem${NC}"
    echo -e "${YELLOW}!!! IMPORTANT: Keep this key file secure. You will not be able to download it again !!!${NC}"
else
    echo -e "${GREEN}Key pair '$KEY_PAIR_NAME' already exists.${NC}"
    echo -e "${YELLOW}Make sure you have the corresponding .pem file to connect to instances.${NC}"
fi

# Check if stack exists - improved check with clearer output
echo -e "${YELLOW}Checking if stack '$STACK_NAME' exists...${NC}"
STACK_EXISTS=false

if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION 2>&1 | grep -q 'Stack with id'; then
    STACK_EXISTS=false
    echo -e "${RED}Stack '$STACK_NAME' does not exist. Will create new stack.${NC}"
else
    # Further check stack status to ensure it's not in DELETE_COMPLETE state
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text --region $REGION 2>/dev/null)

    if [ $? -eq 0 ] && [ "$STACK_STATUS" != "DELETE_COMPLETE" ]; then
        STACK_EXISTS=true
        echo -e "${GREEN}Stack '$STACK_NAME' exists with status: $STACK_STATUS. Will update existing stack.${NC}"
    else
        STACK_EXISTS=false
        echo -e "${YELLOW}Stack '$STACK_NAME' does not exist or is in DELETE_COMPLETE state. Will create new stack.${NC}"
    fi
fi

# Create or update stack based on existence
if [ "$STACK_EXISTS" = true ]; then
    # Update existing stack
    echo -e "${YELLOW}Updating existing CloudFormation stack: $STACK_NAME${NC}"

    aws cloudformation update-stack \
      --stack-name $STACK_NAME \
      --template-url "https://$BUCKET_NAME.s3.$REGION.amazonaws.com/main.yaml" \
      --parameters \
        ParameterKey=KeyName,ParameterValue=$KEY_PAIR_NAME \
        ParameterKey=AvailabilityZone,ParameterValue=$AVAILABILITY_ZONE \
        ParameterKey=SSHLocation,ParameterValue=$SSH_LOCATION \
        ParameterKey=BucketName,ParameterValue=$BUCKET_NAME \
      --capabilities CAPABILITY_IAM \
      --region $REGION

    # Check if update was initiated successfully
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Stack update initiated. Waiting for update to complete...${NC}"
        # Set operation type for later use
        OPERATION_TYPE="update"
    else
        echo -e "${RED}Stack update failed to initiate. This might be due to no changes to apply.${NC}"
        echo -e "${YELLOW}Exiting script...${NC}"
        exit 1
    fi
else
    # Create new stack
    echo -e "${YELLOW}Creating new CloudFormation stack: $STACK_NAME${NC}"

    aws cloudformation create-stack \
      --stack-name $STACK_NAME \
      --template-url "https://$BUCKET_NAME.s3.$REGION.amazonaws.com/main.yaml" \
      --parameters \
        ParameterKey=KeyName,ParameterValue=$KEY_PAIR_NAME \
        ParameterKey=AvailabilityZone,ParameterValue=$AVAILABILITY_ZONE \
        ParameterKey=SSHLocation,ParameterValue=$SSH_LOCATION \
        ParameterKey=BucketName,ParameterValue=$BUCKET_NAME \
      --capabilities CAPABILITY_IAM \
      --region $REGION

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Stack creation initiated. Waiting for creation to complete...${NC}"
        # Set operation type for later use
        OPERATION_TYPE="create"
    else
        echo -e "${RED}Stack creation failed. See error message above.${NC}"
        exit 1
    fi
fi

# Wait for stack operation to complete
echo -e "${YELLOW}Waiting for stack $OPERATION_TYPE to complete (this may take several minutes)...${NC}"

if [ "$OPERATION_TYPE" = "create" ]; then
    # Wait for stack creation
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME --region $REGION
    WAIT_RESULT=$?
else
    # Wait for stack update
    aws cloudformation wait stack-update-complete --stack-name $STACK_NAME --region $REGION
    WAIT_RESULT=$?
fi

# Check if stack operation was successful
if [ $WAIT_RESULT -eq 0 ] && aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text --region $REGION | grep -E 'CREATE_COMPLETE|UPDATE_COMPLETE'; then
    echo -e "${GREEN}Stack $OPERATION_TYPE completed successfully!${NC}"

    # Get outputs from the stack
    echo -e "${YELLOW}Stack Outputs:${NC}"
    aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs" --output table --region $REGION

    # Get Public EC2 Instance IP specifically for easy access
    PUBLIC_IP=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PublicEC2IP'].OutputValue" --output text --region $REGION)
    PRIVATE_IP=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PrivateEC2IP'].OutputValue" --output text --region $REGION)

    if [ -n "$PUBLIC_IP" ]; then
        echo -e "${GREEN}To connect to the public instance:${NC}"
        echo -e "ssh -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_IP"

        if [ -n "$PRIVATE_IP" ]; then
            echo -e "${GREEN}Then, to connect to the private instance:${NC}"
            echo -e "ssh -i $KEY_PAIR_NAME.pem ec2-user@$PRIVATE_IP"
        fi
    fi
else
    echo -e "${RED}Stack $OPERATION_TYPE failed or is still in progress.${NC}"
    echo -e "${YELLOW}Current stack status:${NC}"
    aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text --region $REGION 2>/dev/null || echo "Unable to retrieve stack status"

    # Get stack events to help debug
    echo -e "${YELLOW}Recent stack events (newest first):${NC}"
    aws cloudformation describe-stack-events --stack-name $STACK_NAME --query "StackEvents[0:5].[Timestamp,LogicalResourceId,ResourceStatus,ResourceStatusReason]" --output table --region $REGION 2>/dev/null || echo "Unable to retrieve stack events"

    echo -e "${YELLOW}Check the AWS CloudFormation console for more details.${NC}"
    exit 1
fi

echo -e "${GREEN}Deployment script completed${NC}"
