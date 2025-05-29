data "aws_route53_zone" "main" {
  name = var.domain_name
}

resource "aws_route53_health_check" "app" {
  fqdn              = aws_lb.nlb.dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 30

  tags = {
    Name = "dob-api-health-check"
  }
}

resource "aws_route53_record_set" "primary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "Primary"
  failover       = "PRIMARY"

  alias {
    name                   = aws_lb.nlb.dns_name
    zone_id                = aws_lb.nlb.zone_id
    evaluate_target_health = true
  }

  health_check_id = aws_route53_health_check.app.id
}

resource "aws_route53_record_set" "secondary" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.${var.domain_name}"
  type    = "A"

  set_identifier = "Secondary"
  failover       = "SECONDARY"

  alias {
    name                   = var.secondary_nlb_dns_name
    zone_id                = var.secondary_nlb_zone_id
    evaluate_target_health = true
  }
}