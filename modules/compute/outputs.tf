output "instance_id" {
  description = "The ID of the EC2 Instance"
  value       = aws_instance.app.id
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 Instance"
  value       = aws_instance.app.private_ip
}

output "instance_public_ip" {
  description = "The public IP address of the EC2 Instance (if associated)"
  value       = aws_instance.app.public_ip
}

output "iam_instance_profile_arn" {
  description = "The ARN of the IAM Instance Profile attached to the EC2 Instance"
  value       = aws_iam_instance_profile.ssm_profile.arn
}

output "security_group_id" {
  description = "The ID of the EC2 Security Group"
  value       = aws_security_group.ec2_sg.id
}
