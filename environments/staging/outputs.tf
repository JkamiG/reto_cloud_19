output "vpc_id" {
  description = "ID of the staging VPC"
  value       = module.networking.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the staging VPC"
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
  description = "IDs of the private route tables"
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

output "peering_connection_id" {
  description = "ID of the VPC peering connection between dev and staging"
  value       = module.peering_dev_staging.peering_connection_id
}

output "peering_status" {
  description = "Status of the VPC peering connection"
  value       = module.peering_dev_staging.peering_status
}
