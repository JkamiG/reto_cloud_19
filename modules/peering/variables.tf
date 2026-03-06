variable "requester_vpc_id" {
  description = "ID of the requester VPC"
  type        = string
}

variable "accepter_vpc_id" {
  description = "ID of the accepter VPC"
  type        = string
}

variable "requester_vpc_cidr" {
  description = "CIDR block of the requester VPC"
  type        = string
}

variable "accepter_vpc_cidr" {
  description = "CIDR block of the accepter VPC"
  type        = string
}

variable "requester_route_table_ids" {
  description = "List of route table IDs in the requester VPC to add routes to"
  type        = list(string)
}

variable "accepter_route_table_ids" {
  description = "List of route table IDs in the accepter VPC to add routes to"
  type        = list(string)
}

variable "requester_env" {
  description = "Name of the requester environment (used in naming)"
  type        = string
}

variable "accepter_env" {
  description = "Name of the accepter environment (used in naming)"
  type        = string
}
