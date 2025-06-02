output "route53_zone_id" {
  value = aws_route53_zone.primary.zone_id
}

output "route53_health_check_id" {
  value = aws_route53_health_check.primary.id
}

output "alb_dns_name" {
  value = var.alb_dns_name
}