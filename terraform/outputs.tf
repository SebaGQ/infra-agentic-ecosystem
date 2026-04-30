output "instance_id" {
  description = "EC2 instance ID for the k3s single-node server."
  value       = aws_instance.k3s.id
}

output "instance_private_ip" {
  description = "Private IP address of the k3s instance."
  value       = aws_instance.k3s.private_ip
}

output "instance_public_ip" {
  description = "Public IP used only for outbound internet access. No inbound rules are open."
  value       = aws_instance.k3s.public_ip
}

output "security_group_id" {
  description = "Security Group ID. Its inbound rule set should be empty."
  value       = aws_security_group.k3s.id
}

output "ssm_start_session_command" {
  description = "Command to connect administratively through AWS Systems Manager Session Manager."
  value       = "aws ssm start-session --target ${aws_instance.k3s.id}"
}

