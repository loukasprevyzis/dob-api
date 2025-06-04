variable "ec2_backup_role_name" {
  description = "IAM role name used by EC2 for PostgreSQL backup encryption"
  type        = string
}
variable "cluster_name" {
  description = "Name of the cluster"
  type        = string
}
variable "postgres_backups_bucket_name" {
  description = "Name of the S3 bucket for postgres backups"
  type        = string
}

variable "terraform_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "terraform_lock_table_name" {
  description = "Name of the DynamoDB table for Terraform locking"
  type        = string
}