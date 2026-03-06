variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "reto19"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets"
  type        = list(string)
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT Gateway"
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 50
}

variable "use_asg" {
  description = "Whether to use an Auto Scaling Group"
  type        = bool
  default     = true
}

variable "asg_min" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 6
}

variable "asg_desired" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 2
}
