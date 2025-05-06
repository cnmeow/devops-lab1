output "id" {
  description = "Security group ID"
  value       = aws_security_group.sg.id
}

output "name" {
  description = "Security group name"
  value       = aws_security_group.sg.name
}
