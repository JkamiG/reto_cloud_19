variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "reto19"
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway for private subnets"
  type        = bool
  default     = true
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets (2 elements)"
  type        = list(string)
  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Exactly 2 public subnet CIDRs are required."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets (2 elements)"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Exactly 2 private subnet CIDRs are required."
  }
}
