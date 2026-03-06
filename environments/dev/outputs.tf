output "vpc_id" {
  description = "ID of the dev VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the dev VPC"
  value       = module.networking.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.networking.private_subnet_ids
}

output "private_route_table_ids" {
  description = "IDs of the private route tables (used for peering)"
  value       = module.networking.private_route_table_ids
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "security_group_id" {
  description = "ID of the compute security group"
  value       = module.compute.security_group_id
}
