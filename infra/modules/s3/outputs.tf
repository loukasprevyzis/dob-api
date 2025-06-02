output "postgres_backups_arn" {
  value = aws_s3_bucket.postgres_backups.arn
}