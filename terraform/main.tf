provider "aws" {
  region = var.region
}

module "vpc" {
  source = "./modules/vpc"

  vpc_name            = var.project_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr
}

module "route_tables" {
  source = "./modules/route_tables"

  vpc_name            = module.vpc.vpc_name
  vpc_id              = module.vpc.vpc_id
  public_subnet_id    = module.vpc.public_subnet_id
  private_subnet_id   = module.vpc.private_subnet_id
  internet_gateway_id = module.vpc.internet_gateway_id
  nat_gateway_id      = module.nat_gateway.nat_gateway_id
}

module "nat_gateway" {
  source = "./modules/nat_gateway"

  vpc_name         = module.vpc.vpc_name
  public_subnet_id = module.vpc.public_subnet_id
}

module "public_ec2" {
  source = "./modules/ec2"

  name                        = "public-${var.project_name}"
  vpc_name                    = module.vpc.vpc_name
  ami_id                      = var.ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = module.vpc.public_subnet_id
  vpc_security_group_ids      = [module.public_security_groups.id]
  associate_public_ip_address = true
  key_name                    = var.key_name
}

module "private_ec2" {
  source = "./modules/ec2"

  name                        = "private-${var.project_name}"
  vpc_name                    = module.vpc.vpc_name
  ami_id                      = var.ami_id
  instance_type               = var.ec2_instance_type
  subnet_id                   = module.vpc.private_subnet_id
  vpc_security_group_ids      = [module.private_security_groups.id]
  associate_public_ip_address = false
  key_name                    = var.key_name
}

module "public_security_groups" {
  source = "./modules/security_groups"

  name        = "public-sg-${var.project_name}"
  description = "Security group for public instances"
  vpc_name    = module.vpc.vpc_name
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description = "Allow SSH from my IP"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.allow_ssh_ip
    },
    {
      description = "Allow ping from my IP"
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = var.allow_ssh_ip
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "private_security_groups" {
  source = "./modules/security_groups"

  name        = "private-sg-${var.project_name}"
  description = "Security group for private instances"
  vpc_name    = module.vpc.vpc_name
  vpc_id      = module.vpc.vpc_id

  ingress_rules = [
    {
      description               = "Allow SSH from public security groups"
      from_port                 = 22
      to_port                   = 22
      protocol                  = "tcp"
      referenced_security_group = module.public_security_groups.id
    }
  ]

  egress_rules = [
    {
      description = "Allow all outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

