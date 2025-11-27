output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.web.id
}

output "instance_arn" {
  description = "The ARN of the EC2 instance"
  value       = aws_instance.web.arn
}

output "public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.web.private_ip
}

output "security_group_id" {
  description = "The ID of the security group"
  value       = aws_security_group.ec2_sg.id
}

output "security_group_name" {
  description = "The name of the security group"
  value       = aws_security_group.ec2_sg.name
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.enable_public_ip ? "ssh -i <your-key.pem> ec2-user@${aws_instance.web.public_ip}" : "Instance does not have a public IP"
}
