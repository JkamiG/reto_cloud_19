variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
}

variable "project" {
  description = "Project name used in resource naming and tagging"
  type        = string
  default     = "reto19"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 instance will be deployed (single instance mode)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs for the ASG to span multiple availability zones (ASG mode). Defaults to [subnet_id] if not provided."
  type        = list(string)
  default     = []
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 20
}

variable "use_asg" {
  description = "Whether to use an Auto Scaling Group instead of a single EC2 instance"
  type        = bool
  default     = false
}

variable "asg_min" {
  description = "Minimum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_max" {
  description = "Maximum number of instances in the ASG"
  type        = number
  default     = 1
}

variable "asg_desired" {
  description = "Desired number of instances in the ASG"
  type        = number
  default     = 1
}

variable "ingress_rules" {
  description = "List of ingress rules for the security group"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = []
}
