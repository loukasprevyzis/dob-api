variable "alb_dns_name" {
  type = string
}

variable "alb_zone_id" {
  type = string
}

variable "domain_name" {
  description = "The domain name for the Route 53 zone"
  type        = string
}
variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_app_subnet_id" {
  type = string
}

variable "security_group_app_id" {
  type = string
}

variable "security_group_db_id" {
  type = string
}

variable "route53_health_check_id" {
  type = string
}
