data "aws_caller_identity" "current" {}

data "aws_ssm_parameter" "ubuntu_ami" {
  name = "/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id"
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = var.ec2_ssh_key_name
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_instance" "db_primary" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.small"
  associate_public_ip_address = true
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.sg_db_id]
  key_name                    = var.ec2_ssh_key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_postgres_instance_profile.name

  root_block_device {
    volume_size = var.db_data_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "dob-api-db-primary"
  }
}

resource "aws_ebs_volume" "db_data_primary" {
  availability_zone = aws_instance.db_primary.availability_zone
  size              = var.db_data_volume_size
  type              = "gp3"

  tags = {
    Name = "dob-api-db-primary-data"
  }
}

resource "aws_volume_attachment" "db_data_attach_primary" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.db_data_primary.id
  instance_id = aws_instance.db_primary.id
}

resource "aws_instance" "db_replica" {
  ami                         = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type               = "t3.small"
  associate_public_ip_address = true
  subnet_id                     = var.public_subnet_id
  vpc_security_group_ids        = [var.sg_db_id]
  key_name                      = var.ec2_ssh_key_name
  iam_instance_profile          = aws_iam_instance_profile.ec2_postgres_instance_profile.name

  root_block_device {
    volume_size = var.db_data_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "dob-api-db-replica"
  }
}

resource "aws_ebs_volume" "db_data_replica" {
  availability_zone = aws_instance.db_replica.availability_zone
  size              = var.db_data_volume_size
  type              = "gp3"

  tags = {
    Name = "dob-api-db-replica-data"
  }
}

resource "aws_volume_attachment" "db_data_attach_replica" {
  device_name = "/dev/xvdb"
  volume_id   = aws_ebs_volume.db_data_replica.id
  instance_id = aws_instance.db_replica.id
}

# -------- EC2 Role for PostgreSQL Backups --------
resource "aws_iam_role" "ec2_postgres_role" {
  name = "${var.cluster_name}-ec2-postgres-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "ec2_postgres_backup_policy" {
  name        = "${var.cluster_name}-ec2-postgres-backup-policy"
  description = "Policy for EC2 instances to write backups to S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          var.postgres_backup_bucket_arn,
          "${var.postgres_backup_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_postgres_backup_attach" {
  role       = aws_iam_role.ec2_postgres_role.name
  policy_arn = aws_iam_policy.ec2_postgres_backup_policy.arn
}

# Attach this role to your EC2 instances in postgres.tf (add instance_profile)

resource "aws_iam_instance_profile" "ec2_postgres_instance_profile" {
  name = "${var.cluster_name}-ec2-postgres-instance-profile"
  role = aws_iam_role.ec2_postgres_role.name
}

# -------- EKS Cluster Role (if not already fully defined) --------
# (You already defined these in eks.tf, just check and update if needed)

# -------- Backup Automation Role (e.g., for GitHub Actions or Lambda) --------
resource "aws_iam_role" "backup_automation_role" {
  name = "${var.cluster_name}-backup-automation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # or your GitHub OIDC provider or Lambda ARN
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "backup_automation_policy" {
  name        = "${var.cluster_name}-backup-automation-policy"
  description = "Policy for backup automation to manage S3 backups"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ],
        Resource = [
          var.postgres_backup_bucket_arn,
          "${var.postgres_backup_bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_automation_attach" {
  role       = aws_iam_role.backup_automation_role.name
  policy_arn = aws_iam_policy.backup_automation_policy.arn
}