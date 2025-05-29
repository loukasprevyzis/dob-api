# 🛠 System Architecture Overview – `dob-api` (Revolut SRE/DataOps Assignment)

## 🎯 Goal

Build and deploy a simple Go-based API (`/hello/<username>`) with PostgreSQL as the backend, ensuring:

- High availability (HA)
- Disaster recovery (DR)
- No managed DB services (self-hosted PostgreSQL)
- Automated CI/CD and backup

---

## 🧱 Components

### 🟩 Primary VPC (eu-west-1)

- **NLB (Network Load Balancer)**: Routes external HTTP/HTTPS traffic to Kubernetes pods.
- **EKS Cluster**: Hosts stateless Go API (`dob-api`).
- **Private Subnet (DB)**:
  - **EC2 Instance (Primary PostgreSQL)**: Self-managed PostgreSQL server.
  - **Security Group**: Allows traffic only from EKS app and replication traffic to the replica.
  - **Automated Backup**: Nightly database dumps to Amazon S3 using cronjob.

---

### 🟪 Failover VPC (eu-central-1)

- **Private Subnet (DB Replica)**:
  - **EC2 Instance (Replica PostgreSQL)**: Async replication from the primary via VPC Peering.
  - **Security Group**: Allows replication traffic and read-only failover access.

---

### 📦 Shared Services

- **Amazon S3 Bucket**: Stores encrypted PostgreSQL backups.
- **GitHub Actions**:
  - Runs build/test
  - Publishes Docker image
  - Deploys to Kubernetes
  - Triggers backup jobs and restore logic

---

### 🌐 Route53

- **DNS Failover Routing**: Directs traffic to the failover region if the primary is unavailable.

---

## ✅ Highlights

- Full Kubernetes-based app deployment (stateless Go app).
- Self-hosted PostgreSQL (no managed services).
- Cross-region async replication for HA & DR.
- CI/CD and backup automation.
- Diagrams available in `draw.io` and `.jpeg` formats.


## 🗄️ Database Setup: PostgreSQL on EC2

This module provisions a highly-available PostgreSQL setup on EC2 using EBS volumes in private subnets.

### 🧱 Components

- **Primary DB Instance**  
  - Hosted in `eu-west-1c` (or similar), using a dedicated EBS volume for data.
  - Custom `user_data` script installs PostgreSQL and mounts the EBS volume to `/var/lib/postgresql/data`.

- **Replica DB Instance**  
  - Hosted in a different AZ (`eu-west-1b`), prepped for future streaming replication setup.
  - Will follow the same pattern for volume management.

### 🔐 Security

- No hardcoded credentials or secrets.
- SSH access controlled via `var.ec2_ssh_key_name`.
- Only internal security groups allow DB port access (5432) from the app tier.

### 📝 Notes

- The user data script installs PostgreSQL, mounts the attached volume, and relocates the PostgreSQL data directory.
- Replication configuration is left as a placeholder for later.
- EBS volume is automatically re-attached on instance reboot via `fstab`.

### 🚫 Disclaimer

This architecture avoids RDS by design (per assignment requirements). In production, use RDS with multi-AZ for simplicity and better failover.