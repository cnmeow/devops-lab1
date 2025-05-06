#!/bin/bash

# Script kiểm tra hạ tầng AWS được triển khai bởi CloudFormation
# Cách sử dụng: ./test.sh

# Load configuration from config.env file
if [ -f "./config.env" ]; then
    source ./config.env
else
    echo "Error: config.env file not found!"
    exit 1
fi

# Màu sắc để hiển thị kết quả
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Lấy output từ CloudFormation stack
echo -e "${YELLOW}Retrieving resource IDs from stack outputs...${NC}"
VPC_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='VPCId'].OutputValue" --output text --region $REGION)
PUBLIC_SUBNET_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PublicSubnetId'].OutputValue" --output text --region $REGION)
PRIVATE_SUBNET_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PrivateSubnetId'].OutputValue" --output text --region $REGION)
INTERNET_GATEWAY_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='InternetGatewayId'].OutputValue" --output text --region $REGION)
NAT_GATEWAY_ID=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='NATGatewayId'].OutputValue" --output text --region $REGION)
PUBLIC_EC2_IP=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PublicEC2IP'].OutputValue" --output text --region $REGION)
PRIVATE_EC2_IP=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].Outputs[?OutputKey=='PrivateEC2IP'].OutputValue" --output text --region $REGION)

# In ra các ID đã lấy
echo "VPC ID: $VPC_ID"
echo "Public Subnet ID: $PUBLIC_SUBNET_ID"
echo "Private Subnet ID: $PRIVATE_SUBNET_ID"
echo "Internet Gateway ID: $INTERNET_GATEWAY_ID"
echo "NAT Gateway ID: $NAT_GATEWAY_ID"
echo "Public EC2 IP: $PUBLIC_EC2_IP"
echo "Private EC2 IP: $PRIVATE_EC2_IP"

echo -e "${YELLOW}Testing individual resources...${NC}"

# Kiểm tra CloudFormation Stack
echo -e "\n${YELLOW}Kiểm tra CloudFormation stack $STACK_NAME...${NC}"
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query "Stacks[0].StackStatus" --output text --region $REGION 2>/dev/null)
if [[ "$STACK_STATUS" == "CREATE_COMPLETE" || "$STACK_STATUS" == "UPDATE_COMPLETE" ]]; then
    echo -e "${GREEN}✅ CloudFormation stack $STACK_NAME tồn tại và có trạng thái: $STACK_STATUS${NC}"
else
    echo -e "${RED}❌ CloudFormation stack $STACK_NAME không ở trạng thái hoàn tất (Trạng thái: $STACK_STATUS)${NC}"
fi

# Kiểm tra VPC
echo -e "\n${YELLOW}Kiểm tra VPC...${NC}"
if [ -z "$VPC_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy VPC ID trong output.${NC}"
else
    VPC_STATUS=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].State' --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$VPC_STATUS" == "available" ]; then
        echo -e "${GREEN}✅ VPC $VPC_ID tồn tại và có trạng thái: $VPC_STATUS${NC}"

        # Lấy CIDR block của VPC
        VPC_CIDR=$(aws ec2 describe-vpcs --vpc-ids $VPC_ID --query 'Vpcs[0].CidrBlock' --output text)
        echo -e "   CIDR: $VPC_CIDR"
    else
        echo -e "${RED}❌ VPC $VPC_ID không tồn tại hoặc có vấn đề.${NC}"
    fi
fi

# Kiểm tra Public Subnet
echo -e "\n${YELLOW}Kiểm tra Public Subnet...${NC}"
if [ -z "$PUBLIC_SUBNET_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy Public Subnet ID trong output stack.${NC}"
else
    SUBNET_STATUS=$(aws ec2 describe-subnets --subnet-ids $PUBLIC_SUBNET_ID --query 'Subnets[0].State' --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$SUBNET_STATUS" == "available" ]; then
        echo -e "${GREEN}✅ Public Subnet $PUBLIC_SUBNET_ID tồn tại và có trạng thái: $SUBNET_STATUS${NC}"

        # Lấy CIDR và MapPublicIpOnLaunch của subnet
        SUBNET_CIDR=$(aws ec2 describe-subnets --subnet-ids $PUBLIC_SUBNET_ID --query 'Subnets[0].CidrBlock' --output text)
        MAP_PUBLIC_IP=$(aws ec2 describe-subnets --subnet-ids $PUBLIC_SUBNET_ID --query 'Subnets[0].MapPublicIpOnLaunch' --output text)
        echo -e "   CIDR: $SUBNET_CIDR"
        echo -e "   MapPublicIpOnLaunch: $MAP_PUBLIC_IP"
    else
        echo -e "${RED}❌ Public Subnet $PUBLIC_SUBNET_ID không tồn tại hoặc có vấn đề.${NC}"
    fi
fi

# Kiểm tra Private Subnet
echo -e "\n${YELLOW}Kiểm tra Private Subnet...${NC}"
if [ -z "$PRIVATE_SUBNET_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy Private Subnet ID trong output stack.${NC}"
else
    SUBNET_STATUS=$(aws ec2 describe-subnets --subnet-ids $PRIVATE_SUBNET_ID --query 'Subnets[0].State' --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$SUBNET_STATUS" == "available" ]; then
        echo -e "${GREEN}✅ Private Subnet $PRIVATE_SUBNET_ID tồn tại và có trạng thái: $SUBNET_STATUS${NC}"

        # Lấy CIDR và MapPublicIpOnLaunch của subnet
        SUBNET_CIDR=$(aws ec2 describe-subnets --subnet-ids $PRIVATE_SUBNET_ID --query 'Subnets[0].CidrBlock' --output text)
        MAP_PUBLIC_IP=$(aws ec2 describe-subnets --subnet-ids $PRIVATE_SUBNET_ID --query 'Subnets[0].MapPublicIpOnLaunch' --output text)
        echo -e "   CIDR: $SUBNET_CIDR"
        echo -e "   MapPublicIpOnLaunch: $MAP_PUBLIC_IP"
    else
        echo -e "${RED}❌ Private Subnet $PRIVATE_SUBNET_ID không tồn tại hoặc có vấn đề.${NC}"
    fi
fi

# Kiểm tra Internet Gateway
echo -e "\n${YELLOW}Kiểm tra Internet Gateway...${NC}"
if [ -z "$INTERNET_GATEWAY_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy Internet Gateway ID trong output stack.${NC}"
else
    # Kiểm tra xem Internet Gateway có gắn với VPC không
    IG_ATTACHMENT=$(aws ec2 describe-internet-gateways --internet-gateway-ids $INTERNET_GATEWAY_ID --query "InternetGateways[0].Attachments[?VpcId=='$VPC_ID'].State" --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$IG_ATTACHMENT" == "available" ]; then
        echo -e "${GREEN}✅ Internet Gateway $INTERNET_GATEWAY_ID tồn tại và được gắn với VPC $VPC_ID${NC}"
    else
        echo -e "${RED}❌ Internet Gateway $INTERNET_GATEWAY_ID không tồn tại hoặc không gắn với VPC $VPC_ID.${NC}"
    fi
fi

# Kiểm tra NAT Gateway
echo -e "\n${YELLOW}Kiểm tra NAT Gateway...${NC}"
if [ -z "$NAT_GATEWAY_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy NAT Gateway ID trong output stack.${NC}"
else
    NAT_STATUS=$(aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --query 'NatGateways[0].State' --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$NAT_STATUS" == "available" ]; then
        echo -e "${GREEN}✅ NAT Gateway $NAT_GATEWAY_ID tồn tại và có trạng thái: $NAT_STATUS${NC}"
    else
        echo -e "${RED}❌ NAT Gateway $NAT_GATEWAY_ID không tồn tại hoặc có vấn đề.${NC}"
    fi
fi

# Kiểm tra Route Tables
echo -e "\n${YELLOW}Kiểm tra Route Tables...${NC}"

# Lấy Route Table IDs
PUBLIC_RT=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.subnet-id,Values=$PUBLIC_SUBNET_ID" --query "RouteTables[0].RouteTableId" --output text --region $REGION)
PRIVATE_RT=$(aws ec2 describe-route-tables --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.subnet-id,Values=$PRIVATE_SUBNET_ID" --query "RouteTables[0].RouteTableId" --output text --region $REGION)

echo -e "${YELLOW}Kiểm tra Route Table cho Public Subnet...${NC}"
if [ -n "$PUBLIC_RT" ] && [ "$PUBLIC_RT" != "None" ]; then
    echo -e "${GREEN}✅ Route Table $PUBLIC_RT được liên kết với Public Subnet $PUBLIC_SUBNET_ID${NC}"

    # Kiểm tra route đến Internet Gateway
    ROUTE_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $PUBLIC_RT --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].GatewayId" --output text 2>/dev/null)
    if [ -n "$ROUTE_EXISTS" ] && [ "$ROUTE_EXISTS" == "$INTERNET_GATEWAY_ID" ]; then
        echo -e "${GREEN}✅ Route Table có route 0.0.0.0/0 đến Internet Gateway $ROUTE_EXISTS${NC}"
    else
        echo -e "${RED}❌ Route Table không có route 0.0.0.0/0 đến Internet Gateway.${NC}"
    fi
else
    echo -e "${RED}❌ Không tìm thấy Route Table được liên kết với Public Subnet $PUBLIC_SUBNET_ID.${NC}"
fi

echo -e "\n${YELLOW}Kiểm tra Route Table cho Private Subnet...${NC}"
if [ -n "$PRIVATE_RT" ] && [ "$PRIVATE_RT" != "None" ]; then
    echo -e "${GREEN}✅ Route Table $PRIVATE_RT được liên kết với Private Subnet $PRIVATE_SUBNET_ID${NC}"

    # Kiểm tra route đến NAT Gateway
    ROUTE_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $PRIVATE_RT --query "RouteTables[0].Routes[?DestinationCidrBlock=='0.0.0.0/0'].NatGatewayId" --output text 2>/dev/null)
    if [ -n "$ROUTE_EXISTS" ] && [ "$ROUTE_EXISTS" == "$NAT_GATEWAY_ID" ]; then
        echo -e "${GREEN}✅ Route Table có route 0.0.0.0/0 đến NAT Gateway $ROUTE_EXISTS${NC}"
    else
        echo -e "${RED}❌ Route Table không có route 0.0.0.0/0 đến NAT Gateway.${NC}"
    fi
else
    echo -e "${RED}❌ Không tìm thấy Route Table được liên kết với Private Subnet $PRIVATE_SUBNET_ID.${NC}"
fi

# Lấy ID của Public EC2 instance
PUBLIC_EC2_ID=$(aws ec2 describe-instances --filters "Name=network-interface.addresses.association.public-ip,Values=$PUBLIC_EC2_IP" --query "Reservations[0].Instances[0].InstanceId" --output text --region $REGION 2>/dev/null)

# Kiểm tra Public EC2 Instance
echo -e "\n${YELLOW}Kiểm tra Public EC2 Instance...${NC}"
if [ -z "$PUBLIC_EC2_IP" ]; then
    echo -e "${RED}❌ Không tìm thấy Public EC2 Instance IP trong output stack.${NC}"
else
    if [ -n "$PUBLIC_EC2_ID" ] && [ "$PUBLIC_EC2_ID" != "None" ]; then
        EC2_STATUS=$(aws ec2 describe-instances --instance-ids $PUBLIC_EC2_ID --query "Reservations[0].Instances[0].State.Name" --output text --region $REGION 2>/dev/null)
        if [ "$EC2_STATUS" == "running" ]; then
            echo -e "${GREEN}✅ Public EC2 Instance $PUBLIC_EC2_ID tồn tại và có trạng thái: $EC2_STATUS${NC}"
            echo -e "   Public IP: $PUBLIC_EC2_IP"

            # Thử ping đến Public EC2 Instance
            echo -e "\n${YELLOW}Thử ping đến Public EC2 Instance...${NC}"
            ping -c 3 $PUBLIC_EC2_IP > /dev/null
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Ping đến Public EC2 Instance thành công.${NC}"
            else
                echo -e "${RED}❌ Không thể ping đến Public EC2 Instance. Có thể do Security Group không cho phép ICMP hoặc instance không hoạt động.${NC}"
            fi

            # Kiểm tra kết nối SSH
            echo -e "\n${YELLOW}Kiểm tra kết nối SSH đến Public EC2 Instance...${NC}"
            nc -zv $PUBLIC_EC2_IP 22 -w 5 > /dev/null 2>&1
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ Cổng SSH (22) trên Public EC2 Instance đang mở.${NC}"
                echo -e "   Bạn có thể kết nối bằng: ssh -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP"
            else
                echo -e "${RED}❌ Không thể kết nối đến cổng SSH (22) trên Public EC2 Instance.${NC}"
            fi
        else
            echo -e "${RED}❌ Public EC2 Instance $PUBLIC_EC2_ID không ở trạng thái running.${NC}"
        fi
    else
        echo -e "${RED}❌ Không tìm thấy Public EC2 Instance với IP $PUBLIC_EC2_IP.${NC}"
    fi
fi

# Lấy ID của Private EC2 instance
PRIVATE_EC2_ID=$(aws ec2 describe-instances --filters "Name=private-ip-address,Values=$PRIVATE_EC2_IP" --query "Reservations[0].Instances[0].InstanceId" --output text --region $REGION 2>/dev/null)

# Kiểm tra Private EC2 Instance
echo -e "\n${YELLOW}Kiểm tra Private EC2 Instance...${NC}"
if [ -z "$PRIVATE_EC2_IP" ]; then
    echo -e "${RED}❌ Không tìm thấy Private EC2 Instance IP trong output stack.${NC}"
else
    if [ -n "$PRIVATE_EC2_ID" ] && [ "$PRIVATE_EC2_ID" != "None" ]; then
        EC2_STATUS=$(aws ec2 describe-instances --instance-ids $PRIVATE_EC2_ID --query "Reservations[0].Instances[0].State.Name" --output text --region $REGION 2>/dev/null)
        if [ "$EC2_STATUS" == "running" ]; then
            echo -e "${GREEN}✅ Private EC2 Instance $PRIVATE_EC2_ID tồn tại và có trạng thái: $EC2_STATUS${NC}"
            echo -e "   Private IP: $PRIVATE_EC2_IP"
            echo -e "   Để kết nối đến Private Instance, bạn cần kết nối qua Public Instance:"
            echo -e "   1. ssh -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP"
            echo -e "   2. Từ Public Instance: ssh -i ~/.ssh/id_rsa ec2-user@$PRIVATE_EC2_IP"

            # Kiểm tra kết nối SSH từ public đến private (nếu key file tồn tại)
            if [ -f "$KEY_PAIR_NAME.pem" ]; then
                echo -e "\n${YELLOW}Kiểm tra kết nối từ Public đến Private Instance...${NC}"
                echo -e "Sao chép key vào Public Instance..."

                # Sao chép key vào public instance
                scp -o StrictHostKeyChecking=no -i $KEY_PAIR_NAME.pem $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP:/home/ec2-user/.ssh/id_rsa > /dev/null 2>&1
                if [ $? -eq 0 ]; then
                    # Đặt quyền cho key
                    ssh -o StrictHostKeyChecking=no -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP "chmod 400 ~/.ssh/id_rsa" > /dev/null 2>&1

                    # Thử kết nối từ public đến private
                    CONNECTION_TEST=$(ssh -o StrictHostKeyChecking=no -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ec2-user@$PRIVATE_EC2_IP 'echo CONNECTION_SUCCESS'" 2>/dev/null)
                    if [[ "$CONNECTION_TEST" == *"CONNECTION_SUCCESS"* ]]; then
                        echo -e "${GREEN}✅ Kết nối từ Public đến Private Instance thành công.${NC}"
                    else
                        echo -e "${RED}❌ Không thể kết nối từ Public đến Private Instance.${NC}"
                    fi
                else
                    echo -e "${RED}❌ Không thể sao chép key vào Public Instance.${NC}"
                fi
            else
                echo -e "\n${YELLOW}Bỏ qua kiểm tra kết nối từ Public đến Private Instance - key file không tồn tại.${NC}"
            fi
        else
            echo -e "${RED}❌ Private EC2 Instance $PRIVATE_EC2_ID không ở trạng thái running.${NC}"
        fi
    else
        echo -e "${RED}❌ Không tìm thấy Private EC2 Instance với IP $PRIVATE_EC2_IP.${NC}"
    fi
fi

# Kiểm tra kết nối ra Internet từ Private Instance (thông qua NAT Gateway)
if [ -f "$KEY_PAIR_NAME.pem" ]; then
    echo -e "\n${YELLOW}Kiểm tra kết nối Internet từ Private Instance (qua NAT Gateway)...${NC}"

    # Thử ping từ private instance đến 8.8.8.8
    PING_TEST=$(ssh -o StrictHostKeyChecking=no -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ec2-user@$PRIVATE_EC2_IP 'ping -c 2 8.8.8.8'" 2>/dev/null)
    if [[ "$PING_TEST" == *"2 received"* ]]; then
        echo -e "${GREEN}✅ Private Instance có thể ping ra Internet qua NAT Gateway.${NC}"
    else
        echo -e "${RED}❌ Private Instance không thể ping ra Internet.${NC}"
    fi

    # Thử curl từ private instance đến example.com
    CURL_TEST=$(ssh -o StrictHostKeyChecking=no -i $KEY_PAIR_NAME.pem ec2-user@$PUBLIC_EC2_IP "ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ec2-user@$PRIVATE_EC2_IP 'curl -s example.com -m 5 | grep -c Example'" 2>/dev/null)
    if [ "$CURL_TEST" -gt 0 ]; then
        echo -e "${GREEN}✅ Private Instance có thể truy cập HTTP ra Internet qua NAT Gateway.${NC}"
    else
        echo -e "${RED}❌ Private Instance không thể truy cập HTTP ra Internet.${NC}"
    fi
else
    echo -e "\n${YELLOW}Bỏ qua kiểm tra kết nối Internet từ Private Instance - key file không tồn tại.${NC}"
fi

# Kiểm tra Security Group
echo -e "\n${YELLOW}Kiểm tra Security Group Restrictions...${NC}"
if [ -f "$KEY_PAIR_NAME.pem" ]; then
    echo -e "${YELLOW}Kiểm tra truy cập trực tiếp đến Private Instance (nên thất bại)...${NC}"
    nc -zv $PRIVATE_EC2_IP 22 -w 5 > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "${RED}❌ SECURITY ISSUE: Có thể truy cập trực tiếp đến Private Instance từ bên ngoài!${NC}"
    else
        echo -e "${GREEN}✅ Security Groups hoạt động đúng: Không thể truy cập trực tiếp đến Private Instance từ bên ngoài.${NC}"
    fi
else
    echo -e "${YELLOW}Bỏ qua kiểm tra Security Group - key file không tồn tại.${NC}"
fi

# Hiển thị tổng kết
echo -e "\n${YELLOW}=================================================================${NC}"
echo -e "${GREEN}✅ Kiểm tra hạ tầng AWS CloudFormation hoàn tất ${NC}"
echo -e "${YELLOW}Vui lòng kiểm tra các thông báo lỗi phía trên để khắc phục nếu cần.${NC}"
echo -e "${YELLOW}=================================================================${NC}"
