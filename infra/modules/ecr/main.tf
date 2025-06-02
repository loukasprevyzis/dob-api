resource "aws_ecr_repository" "dob_api" {
  name                 = "dob-api"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "dob-api"
    Environment = "production"
  }
}

