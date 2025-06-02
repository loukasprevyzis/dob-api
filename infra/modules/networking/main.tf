resource "aws_vpc" "primary" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

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

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-eu-west-1b"
  }
}

resource "aws_subnet" "public_az3" {
  vpc_id                  = aws_vpc.primary.id
  cidr_block              = "10.0.5.0/24"
  availability_zone       = "eu-west-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "Public-Subnet-eu-west-1c"
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

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.primary.id
  tags = {
    Name = "Primary-IGW"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route_table_association" "public_subnet_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_subnet_assoc_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_subnet_assoc_az3" {
  subnet_id      = aws_subnet.public_az3.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_app_rt" {
  vpc_id = aws_vpc.primary.id
  tags = {
    Name = "Private-App-Route-Table"
  }
}

resource "aws_route_table_association" "private_app_subnet_assoc" {
  subnet_id      = aws_subnet.private_app.id
  route_table_id = aws_route_table.private_app_rt.id
}

resource "aws_route_table" "private_db_rt" {
  vpc_id = aws_vpc.primary.id
  tags = {
    Name = "Private-DB-Route-Table"
  }
}

resource "aws_route_table_association" "private_db_subnet_assoc" {
  subnet_id      = aws_subnet.private_db.id
  route_table_id = aws_route_table.private_db_rt.id
}

# No 0.0.0.0/0 routes in private route tables → no NAT gateway needed

# VPC Endpoint for S3 Gateway (allows S3 access without internet/NAT)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.primary.id
  service_name      = "com.amazonaws.eu-west-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private_app_rt.id,
    aws_route_table.private_db_rt.id,
    aws_route_table.public.id,
  ]

  tags = {
    Name = "S3 Endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = aws_vpc.primary.id
  service_name       = "com.amazonaws.eu-west-1.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_app.id, aws_subnet.private_db.id]
  security_group_ids = [aws_security_group.sg_app.id]

  private_dns_enabled = true
  tags = {
    Name = "ECR API Endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = aws_vpc.primary.id
  service_name       = "com.amazonaws.eu-west-1.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_app.id, aws_subnet.private_db.id]
  security_group_ids = [aws_security_group.sg_app.id]

  private_dns_enabled = true
  tags = {
    Name = "ECR DKR Endpoint"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id             = aws_vpc.primary.id
  service_name       = "com.amazonaws.eu-west-1.sts"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_app.id, aws_subnet.private_db.id]
  security_group_ids = [aws_security_group.sg_app.id]

  private_dns_enabled = true
  tags = {
    Name = "STS Endpoint"
  }
}

resource "aws_security_group" "sg_alb" {
  name        = "sg_alb"
  description = "Allow public HTTP access to ALB"
  vpc_id      = aws_vpc.primary.id
  tags = {
    Name = "SG-ALB"
  }
}

resource "aws_security_group" "sg_app" {
  name        = "sg_app"
  description = "Allow traffic from NLB to App pods"
  vpc_id      = aws_vpc.primary.id
  tags = {
    Name = "SG-APP"
  }
}

resource "aws_security_group" "sg_db" {
  name        = "sg_db"
  description = "Allow App to DB Postgres 5432 and SSH access"
  vpc_id      = aws_vpc.primary.id

  tags = {
    Name = "SG-DB"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.sg_db.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "81.102.101.206/32"
  description       = "Allow SSH from my public IP"
}

resource "aws_vpc_security_group_ingress_rule" "allow_app_to_db" {
  security_group_id            = aws_security_group.sg_db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_app.id
  description                  = "Allow app access to DB"
}

resource "aws_vpc_security_group_ingress_rule" "allow_replication" {
  security_group_id            = aws_security_group.sg_db.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.sg_db.id
  description                  = "Allow replication traffic between DB instances"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_outbound" {
  security_group_id = aws_security_group.sg_db.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}


# Allow all outbound traffic from sg_app
# Allow all outbound traffic from sg_app
resource "aws_vpc_security_group_egress_rule" "app_allow_all_outbound" {
  security_group_id = aws_security_group.sg_app.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic"
}

# Allow response traffic from app to ALB
resource "aws_vpc_security_group_egress_rule" "app_allow_return_to_alb" {
  security_group_id = aws_security_group.sg_app.id
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = aws_vpc.primary.cidr_block
  description       = "Allow response traffic from app to ALB"
}

resource "aws_vpc_security_group_ingress_rule" "allow_http_to_alb" {
  security_group_id = aws_security_group.sg_alb.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow HTTP access to ALB"
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_all_outbound" {
  security_group_id = aws_security_group.sg_alb.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound traffic from ALB"
}

resource "aws_vpc_security_group_ingress_rule" "allow_vpc_to_app" {
  security_group_id = aws_security_group.sg_app.id
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
  cidr_ipv4         = aws_vpc.primary.cidr_block
  description       = "Allow ALB health checks and internal traffic"
}

resource "aws_vpc_security_group_ingress_rule" "allow_alb_to_app" {
  security_group_id            = aws_security_group.sg_app.id
  referenced_security_group_id = aws_security_group.sg_alb.id
  from_port                    = 8080
  to_port                      = 8080
  ip_protocol                  = "tcp"
  description                  = "Allow traffic from ALB"
}
resource "aws_lb" "alb" {
  name               = "dob-api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public.id, aws_subnet.public_az2.id, aws_subnet.public_az3.id]
  tags = {
    Name = "dob-api-alb"
  }
}

resource "aws_lb_target_group" "tg_app" {
  name        = "dob-api-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.primary.id
  target_type = "ip"

  health_check {
    protocol            = "HTTP"
    path                = "/hello/health"
    port                = "traffic-port"
    matcher             = "200"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "dob-api-tg"
  }
}

resource "aws_lb_listener" "listener_http_alb" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_app.arn
  }
}


# Allocate an Elastic IP for the NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "Primary-NAT-EIP"
  }
}

# Create NAT Gateway in the public subnet
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "Primary-NAT-Gateway"
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

# Add default route 0.0.0.0/0 in private app route table to NAT Gateway
resource "aws_route" "private_app_nat_route" {
  route_table_id         = aws_route_table.private_app_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

# Add default route 0.0.0.0/0 in private db route table to NAT Gateway
resource "aws_route" "private_db_nat_route" {
  route_table_id         = aws_route_table.private_db_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.eu-west-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app.id, aws_subnet.private_db.id]
  security_group_ids  = [aws_security_group.sg_app.id]
  private_dns_enabled = true
  tags = {
    Name = "SecretsManager Endpoint"
  }
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id              = aws_vpc.primary.id
  service_name        = "com.amazonaws.eu-west-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_app.id, aws_subnet.private_db.id]
  security_group_ids  = [aws_security_group.sg_app.id]
  private_dns_enabled = true
  tags = {
    Name = "CloudWatch Logs Endpoint"
  }
}

# 3. Fix security group rules for app security group
resource "aws_vpc_security_group_ingress_rule" "app_allow_https" {
  security_group_id = aws_security_group.sg_app.id
  description       = "Allow HTTPS for endpoint communication"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = aws_vpc.primary.cidr_block
}