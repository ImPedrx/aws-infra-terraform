output "ec2_public_ip" {
  description = "IP publico da instancia"
  value       = data.aws_eip.eip.public_ip
}

output "ec2_instance_id" {
  description = "ID da instancia EC2"
  value       = aws_instance.ec2.id
}

output "security_group_id" {
  description = "ID do Security Group"
  value       = aws_security_group.sg.id
}