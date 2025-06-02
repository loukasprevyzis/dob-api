# 🛠 dob-api — SRE/DataOps Engineer Assignment

## 🎯 Goal

Implement a highly available, disaster-resilient "Hello World" API service with:

- A **Go-based HTTP API** with two endpoints:
  - `PUT /hello/<username>`: Save/update user’s date of birth (DOB).
    - Validations:
      - `<username>` must be alphabetic only.
      - DOB must be a date before today.
    - Returns `204 No Content` on success.
  - `GET /hello/<username>`: Returns a birthday message:
    - If birthday is **today**:  
      `{ "message": "Hello, <username>! Happy birthday!" }`
    - If birthday is **in N days**:  
      `{ "message": "Hello, <username>! Your birthday is in N day(s)" }`

- Backend storage using **self-hosted PostgreSQL** (no managed DB services allowed).

- **Highly Available PostgreSQL Cluster**:
  - Multi-AZ primary + replica async streaming replication.
  - Cross-region failover capability to ensure recovery from zone or region outages.
  - Automated backups with restore and recovery process in the failover region.

- Automated CI/CD pipelines for:
  - Build, test, and deployment of Go service.
  - Infrastructure provisioning using Terraform.
  - No-downtime production deployment strategy.

- A clear **system architecture diagram** illustrating deployment in AWS/GCP.

---

## 🧱 Components & Architecture

For this assignment, I kept the Terraform flat without modules to focus on correctness, repeatability, and clarity. If this were a production system or part of a larger team project, I would refactor into reusable modules to improve scalability and maintainability.

### API Service

- Developed in Go.
- Validates inputs and interacts with PostgreSQL.
- Stateless, deployed in Kubernetes cluster (EKS or GKE).
- Exposed via Network Load Balancer (NLB).

### PostgreSQL Cluster



- Primary in one AZ/region with dedicated EBS volume.
- Replica in different AZ or region using async streaming replication.
- Self-managed via EC2 instances.
- Security groups restrict access to app and replication traffic.
- Data durability ensured via nightly encrypted backups to S3.

## Network Setup Rationale

For this project, EC2 instances are deployed in **public subnets with public IPs** to enable direct SSH and application access from my local machine. This decision was made to:

- **Simplify testing and debugging** during development and demo phases.
- Avoid additional complexity from VPNs, bastion hosts, or private networking during the initial setup.
- Speed up iteration and validation of infrastructure and application deployments.

---

### Production Considerations

In a production environment, I would implement:

- Deployment into **private subnets** without public IPs.
- Access via **bastion hosts** or **AWS Systems Manager Session Manager** for secure connectivity.
- Proper **security group and network ACL configurations** to restrict access.
- Use of **VPNs or Direct Connect** for secure corporate connectivity.

This approach balances practical testing needs with a clear understanding of enterprise-grade network security best practices.

### Infrastructure & Deployment

- Terraform scripts provision VPC, subnets, EC2, security groups, and EKS cluster.
- Provisions R53 configuration with a new hosted zone using a purchased pre-existing domain name.
- User data scripts configure PostgreSQL on EC2, set up replication with two multi AZ ec2 psql clusters.
- Deploys a secondary region in eu-central-1 for DB disaster recovery failover.
- GitHub Actions for CI/CD pipeline:  
  - Runs unit tests locally.  
  - Builds and publishes Docker images.  
  - Deploys to Kubernetes with rolling update strategy.
- Backup and restore jobs triggered via GitHub Actions.

---

## ✅ Validation & Testing for Postgresql D. 

After infrastructure deployment, confirm system functionality with for the primary/replica multi AZ DBs:
- PostgreSQL user/database/table creation is handled dynamically by the Go application on startup via environment-based connection config and schema init logic.
- Database Tests:
  - On primary, check replication slots and active replicas.
    ```bash
    sudo -u postgres psql -c "SELECT slot_name, active FROM pg_replication_slots;"
    sudo -u postgres psql -c "SELECT * FROM pg_stat_replication;"
    ```
  - On replica, verify WAL streaming is active.  
    ```bash
    sudo -u postgres psql -c "SELECT * FROM pg_stat_wal_receiver;"
    ```
  - Confirm `pg_is_in_recovery()` is `false` on primary, `true` on replica.
- Connectivity:
  - From replica, test connection to primary with replication user.
- Failover:
  - Test manual failover by stopping primary and verifying replica promotion.
- Backup:
  - Validate automated backup files in S3.
  - Run restore job to test recovery in failover region.

- API Tests:
  - Validate PUT `/hello/<username>` stores DOB.
  - Validate GET `/hello/<username>` returns correct birthday message.


---

## 🗂️ System Diagram

*See `diagram.drawio` and exported `.jpeg` in this repo illustrating the multi-region, multi-AZ architecture with replication, backups, and API flow.*

---

## 🚀 How to Run Locally

1. Start local PostgreSQL instance.
2. Run unit tests:
   ```bash
   go test ./...
   ```
3. Use provided Dockerfile to build image.
4. Run API container locally and test API endpoints.

---

## 📦 Deployment

1. Use Terraform to provision infrastructure.
2. Use GitHub Actions to build, test, and deploy.
3. Monitor logs and metrics for replication health and API uptime.

---

## 🔐 Security

- No secrets or credentials stored in the repo; managed via Terraform variables and CI secrets.
- Secure SSH access limited to specific IP.
- Internal security groups allow necessary communication only.

---

## 📚 Notes
- Designed for self-hosted PostgreSQL, avoiding managed services.
- Suitable for real-world SRE/DataOps challenges involving HA, DR, and automation.
- Code quality and testing prioritized.
- Use of common sense for validations, retries, and error handling.
- Application startup handles app user/table creation, removing the need for fragile logic in cloud-init scripts.