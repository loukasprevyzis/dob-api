variable "docker_image_url" {
  type = string
}

variable "docker_image_tag" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "app_db_user" {
  type = string
}

variable "primary_ip" {
  type = string
}

variable "replica_ip" {
  type = string
}

variable "ec2_backup_role_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "app_db_password" {
  type = string
}

variable "app_db_name" {
  type = string
}

variable "sg_app_id" {
  description = "App security group ID"
  type        = string
}

variable "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "alb_listener_arn" {
  type        = string
  description = "ARN of the ALB listener to attach ECS service"
}