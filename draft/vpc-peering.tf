resource "aws_vpc_peering_connection" "db_replication" {
  provider    = aws.primary
  vpc_id      = data.aws_vpc.primary.id
  peer_vpc_id = data.aws_vpc.secondary.id
  peer_region = "eu-central-1"
  auto_accept = true
  tags = {
    Name = "${var.cluster_name}-db-replication-peering"
  }
}

resource "aws_route" "primary_to_secondary" {
  provider                  = aws.primary
  route_table_id            = var.primary_route_table_id
  destination_cidr_block    = data.aws_vpc.secondary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.db_replication.id
}

resource "aws_route" "secondary_to_primary" {
  provider                  = aws.secondary
  route_table_id            = var.secondary_route_table_id
  destination_cidr_block    = data.aws_vpc.primary.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.db_replication.id
}