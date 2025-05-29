variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dob-api-eks-cluster"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "vpc_id" {
  description = "VPC ID where EKS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of private subnet IDs for EKS nodes"
  type        = list(string)
}

variable "ec2_ssh_key_name" {
  description = "EC2 SSH key pair name"
  type        = string
}

variable "office_cidr" {
  type    = string
  default = "YOUR_OFFICE_IP/32" # Change this to your real IP CIDR for SSH access
}

variable "cluster_public_access_cidrs" {
  description = "List of CIDR blocks allowed to access the EKS cluster API server"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your office IP or restrict as needed
}

variable "private_subnet_id_primary" {
  description = "Private subnet ID for primary DB instance"
  type        = string
}

variable "private_subnet_id_replica" {
  description = "Private subnet ID for replica DB instance"
  type        = string
}

variable "db_data_volume_size" {
  description = "Size of EBS volume for PostgreSQL data (GB)"
  type        = number
  default     = 100
}

variable "replication_password" {
  description = "Password for the replication user"
  type        = string
  sensitive   = true
}

variable "db_security_group_id" {
  description = "Security group ID for DB instances allowing port 5432"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {}
variable "domain_name" {} # e.g., "yourdomain.com"
variable "secondary_nlb_dns_name" {}
variable "secondary_nlb_zone_id" {}