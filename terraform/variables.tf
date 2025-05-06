variable "project_name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidr" {
  type = string
}

variable "private_subnet_cidr" {
  type = string
}

variable "ami_id" {
  type = string
}

variable "ec2_instance_type" {
  type = string
}

variable "allow_ssh_ip" {
  type = list(string)
}

variable "key_name" {
  type = string
}