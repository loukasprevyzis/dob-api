output "vpc_id" {
  value = aws_vpc.primary.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public.id,
    aws_subnet.public_az2.id,
    aws_subnet.public_az3.id,
  ]
}

output "private_app_subnet_ids" {
  value = [
    aws_subnet.private_app.id
  ]
}

output "private_db_subnet_ids" {
  value = [
    aws_subnet.private_db.id
  ]
}

output "security_group_app_id" {
  value = aws_security_group.sg_app.id
}

output "security_group_db_id" {
  value = aws_security_group.sg_db.id
}

output "security_group_alb_id" {
  value = aws_security_group.sg_alb.id
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "alb_zone_id" {
  value = aws_lb.alb.zone_id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gw.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "route_table_public_id" {
  value = aws_route_table.public.id
}

output "route_table_private_app_id" {
  value = aws_route_table.private_app_rt.id
}

output "route_table_private_db_id" {
  value = aws_route_table.private_db_rt.id
}

output "alb_target_group_arn" {
  value = aws_lb_target_group.tg_app.arn
}

output "alb_listener_arn" {
  value = aws_lb_listener.listener_http_alb.arn
}