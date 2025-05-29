resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Primary-VPC-eu-west-1"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-eu-west-1a"
  }
}

resource "aws_subnet" "private_app" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-west-1b"
  tags = {
    Name = "Private-App-Subnet-eu-west-1b"
  }
}

resource "aws_subnet" "private_db" {
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-1c"
  tags = {
    Name = "Private-DB-Subnet-eu-west-1c"
  }
}

resource "aws_security_group" "sg_app" {
  name        = "sg_app"
  description = "Allow public HTTP access to App"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow public HTTP access
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG App"
  }
}

resource "aws_security_group" "sg_db" {
  name        = "sg_db"
  description = "Allow App to DB Postgres 5432"
  vpc_id      = aws_vpc.primary.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SG DB"
  }
}

resource "aws_lb" "nlb" {
  name               = "dob-api-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]

  tags = {
    Name = "dob-api-nlb"
  }
}

resource "aws_lb_target_group" "tg_app" {
  name        = "dob-api-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = aws_vpc.primary.id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 10
    interval            = 30
  }

  tags = {
    Name = "dob-api-tg"
  }
}

resource "aws_lb_listener" "listener_http" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_app.arn
  }
}

resource "aws_dynamodb_table" "terraform_lock" {
  name         = "dob-api-terraform-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform Lock Table"
    Environment = "production"
  }
}