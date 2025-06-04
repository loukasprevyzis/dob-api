##########################################################
#FOR REFERENCE ONLY AS IT WAS NOT DEPLOYED FOR COST SAVING
##########################################################
# resource "aws_route53_zone" "primary" {
#   name = var.domain_name
#   tags = {
#     Name = "dob-api-primary-zone"
#   }
# }




# resource "aws_route53_health_check" "primary" {
#   fqdn              = var.alb_dns_name
#   port              = 80
#   type              = "HTTP"
#   resource_path     = "/health"
#   failure_threshold = 3
#   request_interval  = 30

#   tags = {
#     Name = "dob-api-primary-health-check"
#   }
# }
# resource "aws_route53_record" "primary" {
#   zone_id = aws_route53_zone.primary.zone_id
#   name    = "project.${var.domain_name}"
#   type    = "A"

#   failover_routing_policy {
#     type = "PRIMARY"
#   }

#   set_identifier = "primary"

#   alias {
#     name                   = var.alb_dns_name
#     zone_id                = var.alb_zone_id
#     evaluate_target_health = true
#   }

#   health_check_id = var.route53_health_check_id
# }

# # resource "aws_route53_record" "secondary" {
# #   zone_id = data.aws_route53_zone.main.zone_id
# #   name    = "api.${var.domain_name}"
# #   type    = "A"

# #   failover_routing_policy {
# #     type = "SECONDARY"
# #   }

# #   set_identifier  = "secondary"

# #   alias {
# #     name                   = "dummy-secondary-nlb.dns.name" # Replace with actual secondary NLB DNS name
# #     zone_id                = "dummy-secondary-nlb.zone.id" # Replace with actual secondary NLB zone ID
# #     evaluate_target_health = true
# #   }

# #   health_check_id = aws_route53_health_check.secondary.id
# # }