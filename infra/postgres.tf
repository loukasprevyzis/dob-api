# ========== Primary DB Instance ==========
resource "aws_instance" "db_primary" {
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet_id_primary
  vpc_security_group_ids = [var.db_security_group_id]
  key_name               = var.ec2_ssh_key_name

  root_block_device {
    volume_size = var.db_data_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "dob-api-db-primary"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Update and install PostgreSQL
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib

    # Initialize database and ensure service is enabled
    systemctl enable postgresql
    systemctl start postgresql

    # Create replication user with provided password
    sudo -u postgres psql -c "CREATE ROLE replica WITH REPLICATION LOGIN ENCRYPTED PASSWORD '${var.replication_password}';"

    # Configure postgresql.conf for replication
    echo "wal_level = replica" >> /etc/postgresql/14/main/postgresql.conf
    echo "max_wal_senders = 10" >> /etc/postgresql/14/main/postgresql.conf
    echo "wal_keep_size = 64" >> /etc/postgresql/14/main/postgresql.conf

    # Allow replication connections in pg_hba.conf (open to all for demo; restrict in prod)
    echo "host replication replica 0.0.0.0/0 md5" >> /etc/postgresql/14/main/pg_hba.conf

    # Restart PostgreSQL to apply config
    systemctl restart postgresql
  EOF
}

# ========== EBS volume for Primary DB data ==========
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

# ========== Replica DB Instance ==========
resource "aws_instance" "db_replica" {
  ami                    = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnet_id_replica
  vpc_security_group_ids = [var.db_security_group_id]
  key_name               = var.ec2_ssh_key_name

  root_block_device {
    volume_size = var.db_data_volume_size
    volume_type = "gp3"
  }

  tags = {
    Name = "dob-api-db-replica"
  }

  user_data = <<-EOF
    #!/bin/bash
    set -ex

    # Update and install PostgreSQL
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-contrib

    # Format and mount attached volume (assumed /dev/xvdb)
    mkfs.ext4 /dev/xvdb || true  # skip if already formatted
    mkdir -p /var/lib/postgresql/data
    mount /dev/xvdb /var/lib/postgresql/data
    echo "/dev/xvdb /var/lib/postgresql/data ext4 defaults,nofail 0 2" >> /etc/fstab

    # Stop PostgreSQL before base backup
    systemctl stop postgresql || true

    # Clean existing data directory
    rm -rf /var/lib/postgresql/data/*

    # Perform base backup from primary
    sudo -u postgres pg_basebackup -h ${aws_instance.db_primary.private_ip} -D /var/lib/postgresql/data -U replica -v -P --wal-method=stream

    # Set permissions
    chown -R postgres:postgres /var/lib/postgresql/data

    # Configure replication connection info
    echo "primary_conninfo = 'host=${aws_instance.db_primary.private_ip} port=5432 user=replica password=${var.replication_password}'" >> /var/lib/postgresql/data/postgresql.conf

    # For PostgreSQL 12+, create standby.signal to enable recovery mode
    touch /var/lib/postgresql/data/standby.signal

    # Start PostgreSQL service
    systemctl start postgresql
    EOF
}

# ========== EBS volume for Replica DB data ==========
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
          aws_s3_bucket.postgres_backups.arn,
          "${aws_s3_bucket.postgres_backups.arn}/*"
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
        AWS = "arn:aws:iam::YOUR_ACCOUNT_ID:root" # or your GitHub OIDC provider or Lambda ARN
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
          aws_s3_bucket.postgres_backups.arn,
          "${aws_s3_bucket.postgres_backups.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_automation_attach" {
  role       = aws_iam_role.backup_automation_role.name
  policy_arn = aws_iam_policy.backup_automation_policy.arn
}