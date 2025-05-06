#!/bin/bash

# Script kiểm tra hạ tầng AWS được triển khai bởi CloudFormation
# Cách sử dụng: ./test.sh 

# Màu sắc để hiển thị kết quả
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

NAT_GATEWAY_ID="nat-06b9dc890cbb2ce65"
PRIVATE_EC2_ID="i-008e2e113612ee513"
PRIVATE_EC2_IP="10.0.1.68"
PRIVATE_SUBNET_ID="subnet-0b3bd59d24591361d"
PUBLIC_EC2_ID="i-0aa5ace7ac690d5f6"
PUBLIC_EC2_IP="13.212.124.181"
PUBLIC_SUBNET_ID="subnet-0eee90e79f251f331"
VPC_ID="vpc-0bb961ad6293b573d"

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
IG_ID=$(aws ec2 describe-internet-gateways --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
if [ $? -eq 0 ] && [ "$IG_ID" != "None" ]; then
    echo -e "${GREEN}✅ Internet Gateway $IG_ID tồn tại và được gắn với VPC $VPC_ID${NC}"
else
    echo -e "${RED}❌ Không tìm thấy Internet Gateway được gắn với VPC $VPC_ID.${NC}"
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
echo -e "${YELLOW}Kiểm tra Route Table cho Public Subnet...${NC}"
RT_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$PUBLIC_SUBNET_ID" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null)
if [ $? -eq 0 ] && [ "$RT_ID" != "None" ]; then
    echo -e "${GREEN}✅ Route Table $RT_ID được liên kết với Public Subnet $PUBLIC_SUBNET_ID${NC}"

    # Kiểm tra route đến Internet Gateway
    ROUTE_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $RT_ID --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`].GatewayId' --output text 2>/dev/null)
    if [ -n "$ROUTE_EXISTS" ]; then
        echo -e "${GREEN}✅ Route Table có route 0.0.0.0/0 đến Internet Gateway $ROUTE_EXISTS${NC}"
    else
        echo -e "${RED}❌ Route Table không có route 0.0.0.0/0 đến Internet Gateway.${NC}"
    fi
else
    echo -e "${RED}❌ Không tìm thấy Route Table được liên kết với Public Subnet $PUBLIC_SUBNET_ID.${NC}"
fi

echo -e "\n${YELLOW}Kiểm tra Route Table cho Private Subnet...${NC}"
RT_ID=$(aws ec2 describe-route-tables --filters "Name=association.subnet-id,Values=$PRIVATE_SUBNET_ID" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null)
if [ $? -eq 0 ] && [ "$RT_ID" != "None" ]; then
    echo -e "${GREEN}✅ Route Table $RT_ID được liên kết với Private Subnet $PRIVATE_SUBNET_ID${NC}"

    # Kiểm tra route đến NAT Gateway
    ROUTE_EXISTS=$(aws ec2 describe-route-tables --route-table-ids $RT_ID --query 'RouteTables[0].Routes[?DestinationCidrBlock==`0.0.0.0/0`].NatGatewayId' --output text 2>/dev/null)
    if [ -n "$ROUTE_EXISTS" ]; then
        echo -e "${GREEN}✅ Route Table có route 0.0.0.0/0 đến NAT Gateway $ROUTE_EXISTS${NC}"
    else
        echo -e "${RED}❌ Route Table không có route 0.0.0.0/0 đến NAT Gateway.${NC}"
    fi
else
    echo -e "${RED}❌ Không tìm thấy Route Table được liên kết với Private Subnet $PRIVATE_SUBNET_ID.${NC}"
fi

# Kiểm tra Public EC2 Instance
echo -e "\n${YELLOW}Kiểm tra Public EC2 Instance...${NC}"
if [ -z "$PUBLIC_EC2_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy Public EC2 Instance ID trong output stack.${NC}"
else
    EC2_STATUS=$(aws ec2 describe-instances --instance-ids $PUBLIC_EC2_ID --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$EC2_STATUS" == "running" ]; then
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

        # Kiểm tra SSH port
        echo -e "\n${YELLOW}Kiểm tra kết nối SSH đến Public EC2 Instance...${NC}"
        nc -zv $PUBLIC_EC2_IP 22 -w 5 > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Cổng SSH (22) trên Public EC2 Instance đang mở.${NC}"
            echo -e "   Bạn có thể kết nối bằng: ssh -i your-key.pem ec2-user@$PUBLIC_EC2_IP"
        else
            echo -e "${RED}❌ Không thể kết nối đến cổng SSH (22) trên Public EC2 Instance.${NC}"
        fi
    else
        echo -e "${RED}❌ Public EC2 Instance $PUBLIC_EC2_ID không tồn tại hoặc không ở trạng thái running.${NC}"
    fi
fi

# Kiểm tra Private EC2 Instance
echo -e "\n${YELLOW}Kiểm tra Private EC2 Instance...${NC}"
if [ -z "$PRIVATE_EC2_ID" ]; then
    echo -e "${RED}❌ Không tìm thấy Private EC2 Instance ID trong output stack.${NC}"
else
    EC2_STATUS=$(aws ec2 describe-instances --instance-ids $PRIVATE_EC2_ID --query 'Reservations[0].Instances[0].State.Name' --output text 2>/dev/null)
    if [ $? -eq 0 ] && [ "$EC2_STATUS" == "running" ]; then
        echo -e "${GREEN}✅ Private EC2 Instance $PRIVATE_EC2_ID tồn tại và có trạng thái: $EC2_STATUS${NC}"
        echo -e "   Private IP: $PRIVATE_EC2_IP"
        echo -e "   Để kết nối đến Private Instance, bạn cần kết nối qua Public Instance:"
        echo -e "   1. ssh -i your-key.pem ec2-user@$PUBLIC_EC2_IP"
        echo -e "   2. Từ Public Instance: ssh -i your-key.pem ec2-user@$PRIVATE_EC2_IP"
    else
        echo -e "${RED}❌ Private EC2 Instance $PRIVATE_EC2_ID không tồn tại hoặc không ở trạng thái running.${NC}"
    fi
fi

# Hiển thị tổng kết
echo -e "\n${YELLOW}=================================================================${NC}"
echo -e "${GREEN}✅ Kiểm tra hạ tầng AWS hoàn tất ${NC}"
echo -e "${YELLOW}Vui lòng kiểm tra các thông báo lỗi phía trên để khắc phục nếu cần.${NC}"
echo -e "${YELLOW}=================================================================${NC}"
