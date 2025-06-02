terraform {
  backend "s3" {
    bucket         = "dob-api-terraform-state-s3"
    key            = "dob-api/failover/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "dob-api-terraform-lock"
    encrypt        = true
  }
}