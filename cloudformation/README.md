# AWS Infrastructure with CloudFormation

Thư mục này chứa các template CloudFormation để triển khai cơ sở hạ tầng AWS tự động, bao gồm VPC, subnet, route table, security group và EC2 instance.

## Kiến trúc tổng quan

Kiến trúc được xây dựng theo mô hình module hóa, bao gồm:

1. **VPC**: Tạo VPC với public và private subnet
2. **Route Tables**: Tạo và quản lý luồng dữ liệu giữa subnet và internet
3. **NAT Gateway**: Cho phép private subnet truy cập internet
4. **Security Groups**: Quản lý luồng dữ liệu vào/ra của EC2 instance
5. **EC2 Instances**: Tạo và quản lý EC2 instance trong public và private subnet

## Cấu trúc thư mục

```
cloudformation/
├── .gitignore               # File .gitignore
├── config.env.example       # File cấu hình mẫu
├── modules/                 # Thư mục chứa các module CloudFormation
│   ├── vpc.yaml             # Module tạo VPC
│   ├── route-tables.yaml    # Module tạo Route Tables và NAT Gateway
│   ├── security-groups.yaml # Module tạo Security Groups
│   └── ec2-instance.yaml    # Module tạo EC2 instances
├── main.yaml                # Template chính gọi các module khác
├── deploy.sh                # Script để triển khai stack CloudFormation
└── test.sh                  # Script test
└── README.md                #  Readme hướng dẫn
```

## Cách sử dụng

### 1. Chuẩn bị

Đầu tiên, tạo file `config.env` với nội dung sau:

```
BUCKET_NAME=<name-bucket-s3>
STACK_NAME=<name-stack>
REGION=ap-southeast-1
KEY_PAIR_NAME=<name-keypair>
AVAILABILITY_ZONE=ap-southeast-1a
SSH_LOCATION=0.0.0.0/0
```
Tham khảo file `config.env.example`

### 2. Cấp quyền thực thi cho script

```bash
chmod +x deploy.sh
chmod +x test.sh
```

### 3. Triển khai stack

```bash
./deploy.sh
```

Script sẽ tự động:
- Tạo S3 bucket nếu chưa tồn tại
- Upload template lên S3
- Tạo key pair nếu chưa tồn tại
- Tạo hoặc cập nhật CloudFormation stack

### 4. Test stack

Sau khi triển khai thành công, bạn có thể chạy script test để kiểm tra các thành phần:

```bash
./test.sh
```

## Chi tiết các module

### 1. VPC Module (modules/vpc.yaml)
- Tạo VPC
- Tạo Public Subnet với khả năng tự động gán Public IP
- Tạo Private Subnet không có Public IP
- Tạo và gắn Internet Gateway
- Tạo Default Security Group

### 2. Route Tables Module (modules/route-tables.yaml)
- Tạo Public Route Table định tuyến internet thông qua Internet Gateway
- Tạo Private Route Table định tuyến internet thông qua NAT Gateway
- Tạo NAT Gateway và Elastic IP

### 3. Security Groups Module (modules/security-groups.yaml)
- Tạo Public Security Group cho phép SSH từ IP xác định
- Tạo Private Security Group chỉ cho phép kết nối từ Public instance

### 4. EC2 Instance Module (modules/ec2-instance.yaml)
- Tạo EC2 instance trong Public Subnet
- Tạo EC2 instance trong Private Subnet

## Các kết quả đầu ra (Outputs)

Sau khi stack được tạo thành công, bạn sẽ nhận được các kết quả sau:
- VPC ID
- Internet Gateway ID
- Public và Private Subnet ID
- NAT Gateway ID
- Public IP của EC2 instance trong public subnet
- Private IP của EC2 instance trong private subnet

## Lưu ý

- Đảm bảo có đủ quyền IAM để tạo các tài nguyên AWS
- Lưu file key pair (.pem) an toàn, vì nó sẽ không thể tải lại
- Kiểm tra cài đặt AWS CLI và xác thực trước khi chạy script
