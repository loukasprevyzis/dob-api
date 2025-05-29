resource "aws_s3_bucket" "postgres_backups" {
  bucket        = "${var.cluster_name}-postgres-backups"
  force_destroy = true

  tags = {
    Name        = "Postgres Backups"
    Environment = "production"
  }
}

resource "aws_kms_key" "postgres_backup" {
  description             = "KMS key for encrypting PostgreSQL backups in S3"
  enable_key_rotation     = true
  deletion_window_in_days = 10

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-postgres-backup"
    Statement = [
      {
        Sid    = "AllowEC2BackupInstance"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::<ACCOUNT_ID>:role/<EC2_Backup_Role>"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "postgres-backup-kms"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.postgres_backups.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  bucket = aws_s3_bucket.postgres_backups.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.postgres_backup.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.postgres_backups.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.postgres_backups.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = 14
    }
  }
}


##### Terraform State S3 Bucket #####
resource "aws_s3_bucket" "tf_state" {
  bucket = "dob-api-terraform-state-s3"
}

resource "aws_s3_bucket_versioning" "tf_state_versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state_sse" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}