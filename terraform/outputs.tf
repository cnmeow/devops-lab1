output "VPC_ID" {
  value       = module.vpc.vpc_id
}

output "PUBLIC_SUBNET_ID" {
  value       = module.vpc.public_subnet_id
}

output "PRIVATE_SUBNET_ID" {
  value       = module.vpc.private_subnet_id
}

output "PUBLIC_EC2_ID" {
  description = "ID of the public EC2 instance"
  value       = module.public_ec2.id
}

output "PUBLIC_EC2_IP" {
  description = "Public IP of the public EC2 instance"
  value       = module.public_ec2.public_ip
}

output "PRIVATE_EC2_ID" {
  description = "ID of the private EC2 instance"
  value       = module.private_ec2.id
}

output "PRIVATE_EC2_IP" {
  description = "Private IP of the private EC2 instance"
  value       = module.private_ec2.private_ip
}

/*
output "public_security_groups_id" {
  value       = module.public_security_groups.id
}

output "private_security_groups_id" {
  value       = module.private_security_groups.id
}
*/

output "NAT_GATEWAY_ID" {
  value       = module.nat_gateway.nat_gateway_id
}