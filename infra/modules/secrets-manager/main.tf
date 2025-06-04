
data "aws_secretsmanager_secret" "app_db_password" {
  name = "dob-api-db-pwd"
}

# Fetch the latest version of that secret
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = data.aws_secretsmanager_secret.app_db_password.id
}