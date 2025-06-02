variable "ec2_backup_role_name" {
  description = "IAM role name used by EC2 for PostgreSQL backup encryption"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "dob-api-eks-cluster"
}