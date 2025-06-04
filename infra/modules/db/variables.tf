variable "cluster_name" {
  type        = string
}

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
  description = "List of CIDR blocks allowed to access the EKS cluster API server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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


variable "private_subnet_ids" {
  type        = list(string)
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

variable "app_db_password" {
  type        = string
  description = "Database password for the application"
}


variable "sg_app_id" {
  description = "Security Group ID for app"
  type        = string
}

variable "ec2_private_key_pem" {
  description = "EC2 private key in PEM format"
  type        = string
  
}

variable "public_subnet_id" {
  type        = string
  description = "Public subnet ID to launch the EC2 instances in"
}

variable "sg_db_id" {
  description = "Security group ID for the DB instance"
  type        = string
}

variable "postgres_backup_bucket_arn" {
  description = "ARN of the S3 bucket for Postgres backups"
  type        = string
}

variable "db_name_primary" {
  description = "Primary database name"
  type        = string
  default     = "dob_api_db_primary"
}

variable "db_name_replica" {
  description = "Replica database name"
  type        = string
  default     = "dob_api_db_replica"
}

variable "backup_automation_policy" {
  description = "Name of the backup automation policy"
  type        = string
}

variable "backup_automation_role" {
  description = "IAM role for backup automation"
  type        = string
}

variable "ec2_postgres_backup_policy" {
  description = "IAM policy for EC2 Postgres backup"
  type        = string
}
