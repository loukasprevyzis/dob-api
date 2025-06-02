

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "ec2_ssh_key_name" {
  description = "EC2 SSH key pair name"
  type        = string
}

variable "office_cidr" {
  type    = string
  default = "81.102.101.206/32"
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the ECS cluster API server"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your office IP or restrict as needed
}

variable "db_data_volume_size" {
  description = "Size of EBS volume for PostgreSQL data (GB)"
  type        = number
  default     = 100
}

variable "app_db_user" {
  description = "Database user for the application"
  type        = string
}
variable "app_db_name" {
  description = "Database name for the application"
  type        = string

}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "ec2_backup_role_name" {
  description = "IAM role name used by EC2 for PostgreSQL backup encryption"
  type        = string
}

variable "domain_name" {
  description = "The Route53 hosted zone domain name, e.g., example.com"
  type        = string
}

variable "private_subnet_ids" {
  type = list(string)
}


variable "replica_ip" {
  description = "IP address of the replica DB instance"
  type        = string
  default     = ""
}

variable "primary_ip" {
  description = "Private IP of primary DB instance"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The VPC ID where EKS and related resources will be deployed"
  type        = string
}

variable "docker_image_tag" {
  description = "Docker image tag to deploy"
  type        = string
  default     = "latest"
}

variable "docker_image_url" {
  default = "123204938983.dkr.ecr.eu-west-1.amazonaws.com/dob-api"
}
variable "app_db_password" {
  type        = string
  description = "Database password for the application"
}

variable "public_subnet_id" {
  type        = string
  description = "ID of the public subnet to use for the Instances"

}
variable "ec2_private_key_pem" {
  type        = string
  description = "EC2 key pair PEM file content"
  default     = ""
}

variable "route53_health_check_id" {
  type    = string
  default = ""
}