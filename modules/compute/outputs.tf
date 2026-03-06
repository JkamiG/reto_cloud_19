output "instance_id" {
  description = "ID of the EC2 instance (empty string if using ASG)"
  value       = var.use_asg ? "" : (length(aws_instance.main) > 0 ? aws_instance.main[0].id : "")
}

output "asg_name" {
  description = "Name of the Auto Scaling Group (empty string if using single instance)"
  value       = var.use_asg ? aws_autoscaling_group.main[0].name : ""
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "private_ip" {
  description = "Private IP of the EC2 instance (empty string if using ASG)"
  value       = var.use_asg ? "" : (length(aws_instance.main) > 0 ? aws_instance.main[0].private_ip : "")
}
