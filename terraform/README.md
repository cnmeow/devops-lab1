## Introduction
This project uses Terraform to provision a complete AWS infrastructure, meeting the following key requirements:
- Create a **VPC** with both Public and Private Subnets, enabling Internet access via an Internet Gateway and a **NAT Gateway**.
- Configure **Route Tables** to route traffic correctly for each subnet type.
- Set up **Security Groups** to ensure:
  - The Public EC2 instance allows SSH access only from a specific IP (e.g., the user’s IP).
  - The Private EC2 instance is accessible only from the Public EC2 instance via SSH or other internal methods.
- Launch two EC2 instances:
  - One in the Public Subnet, accessible from the Internet via SSH.
  - One in the Private Subnet, accessible only through the Public instance.

## Project structure
```
./terraform
├── main.tf
├── variables.tf
├── terraform.tfvars
├── outputs.tf
├── test.sh  # File for testing
├── modules/
│   ├── vpc/
│   ├── ec2/
|   ├── nat_gateway/
|   ├── route_tables/
│   └── security_groups/
```
## Deployment
1. Clone this repository
```
gh repo clone cnmeow/devops-lab1
```

2. Configure [terraform.tfvars](/terraform/terraform.tfvars) to match your environment

3. Initialize Terraform and apply the configuration
```
cd devops-lab1/terraform
terraform init
terraform plan
terraform apply
```

## Testing
After the process completes, Terraform will output necessary values such as:
- NAT_GATEWAY_ID
- PRIVATE_EC2_ID
- PRIVATE_EC2_IP
- PRIVATE_SUBNET_ID
- PUBLIC_EC2_ID
- PUBLIC_EC2_IP
- PUBLIC_SUBNET_ID
- VPC_ID

Update [test.sh](/terraform/test.sh) with Terraform outputs, then run the script
```
chmod +x test.sh
./test.sh
```
