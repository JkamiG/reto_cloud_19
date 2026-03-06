locals {
  peering_name = "peering-${var.requester_env}-${var.accepter_env}"
}

resource "aws_vpc_peering_connection" "main" {
  vpc_id      = var.requester_vpc_id
  peer_vpc_id = var.accepter_vpc_id
  # auto_accept = true requires both VPCs to be in the same AWS account and region.
  # For cross-account or cross-region peering, remove auto_accept and use a separate
  # aws_vpc_peering_connection_accepter resource with the appropriate provider alias.
  auto_accept = true

  tags = {
    Name      = local.peering_name
    ManagedBy = "Terraform"
  }
}

# Routes in requester route tables pointing to accepter VPC CIDR
resource "aws_route" "requester_to_accepter" {
  count                     = length(var.requester_route_table_ids)
  route_table_id            = var.requester_route_table_ids[count.index]
  destination_cidr_block    = var.accepter_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}

# Routes in accepter route tables pointing to requester VPC CIDR
resource "aws_route" "accepter_to_requester" {
  count                     = length(var.accepter_route_table_ids)
  route_table_id            = var.accepter_route_table_ids[count.index]
  destination_cidr_block    = var.requester_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id
}
