variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "vpc_name" {
  type        = string
  description = "Name tag for the VPC"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}

variable "public_subnet_azs" {
  type        = list(string)
  description = "AZs for public subnets"
}

variable "private_app_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private app subnets"
}

variable "private_app_subnet_azs" {
  type        = list(string)
  description = "AZs for private app subnets"
}

variable "private_db_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private DB subnets"
}

variable "private_db_subnet_azs" {
  type        = list(string)
  description = "AZs for private DB subnets"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "office_cidr" {
  type        = string
  description = "Your office IP range for SSH access"
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet to use for the Instances"
}

variable "dob_api_alb" {
  type        = string
  description = "ARN of the ALB for the application"
}

variable "dob_api_tg" {
  type        = string
  description = "ARN of the target group for the application"
}