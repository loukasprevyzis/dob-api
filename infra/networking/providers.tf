provider "aws" {
  alias  = "primary"
  region = "eu-west-1"
}

provider "aws" {
  alias  = "secondary"
  region = "eu-central-1"
}

data "aws_vpc" "primary" {
  provider = aws.primary
  id       = var.primary_vpc_id
}

data "aws_vpc" "secondary" {
  provider = aws.secondary
  id       = var.secondary_vpc_id
}