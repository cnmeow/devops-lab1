# AWS Infrastructure with Terraform and CloudFormation
Dùng Terraform và CloudFormation để triển khai cơ sở hạ tầng AWS tự động, bao gồm VPC, subnet, route table, security group và EC2 instance.

## Kiến trúc tổng quan
Kiến trúc được xây dựng theo mô hình module hóa, bao gồm:

- VPC: Tạo VPC với public và private subnet
- Route Tables: Tạo và quản lý luồng dữ liệu giữa subnet và internet
- NAT Gateway: Cho phép private subnet truy cập internet
- Security Groups: Quản lý luồng dữ liệu vào/ra của EC2 instance
- EC2 Instances: Tạo và quản lý EC2 instance trong public và private subnet

## Cấu trúc thư mục
```
├── cloudformation/
├── terraform/
```
