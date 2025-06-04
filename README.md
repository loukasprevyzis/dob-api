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
  - Infrastructure provisioning using Terraform (Primary and Failover Disaster Recovery Region)
  - Ansible - To configure PostgreSQL, PostgreSQL replication & automated backups pushed to S3 (Both Prmary and Disaster Recovery regions)
  - No-downtime production deployment strategy.

- A clear **system architecture diagram** illustrating deployment in AWS/GCP.

---

## 🧱 Components & Architecture

For this assignment, I kept the Terraform flat without modules to focus on correctness, repeatability, and clarity. If this were a production system or part of a larger team project, I would refactor into reusable modules to improve scalability and maintainability.

### API Service

- Developed in Go.
- Validates inputs and interacts with PostgreSQL.
- Deployed in ECS (Elastic Container Service)
- Exposed via Application Load Balancer (ALB).

### PostgreSQL Cluster

- Primary in one AZ/region with dedicated EBS volume.
- Replica in different AZ or region using async streaming replication.
- Self-managed via EC2 instances.
- Security groups restrict access to app and replication traffic.
- Data durability ensured via nightly encrypted backups to S3.

## Network Setup Rationale

For this project, EC2 instances are deployed in **public subnets with public IPs** to enable direct SSH and application access from my local machine. This decision was made to:

- **Simplify testing and debugging** during development and demo.
- Speed up iteration and validation of infrastructure and application deployments.



### Production Considerations

In a real world production environment the following would be implemented:

- Deployment into **private subnets** without public IPs.
- Access via **bastion hosts** , **AWS Systems Manager Session Manager**  or **VPN (e.g AWS VPN Client)* for secure connectivity.
- Proper **security group and network ACL configurations** to restrict access.

**“Route 53 failover is not deployed to avoid cost, but is part of the high availability design. In production, a domain (e.g., api.example.com) would point to a Route 53 hosted zone with a failover routing policy between primary and DR ALBs.”**

**This approach balances practical testing needs with a clear understanding of enterprise-grade network security best practices.**

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


## 🗂️ System Diagram

![alt text](revolut.drawio.png)

This diagram represents the ideal production setup for this project, which for cost saving and local testing purposes it was deployed less restrictive (e.g. networking setup that can be seen in the main.tf of the networking terraform module) and without certain components.
To clarify:
- In the code's setup there is no R53 DNS and no failover routing policy for it. However in the diagram, it is suggested that this would be deployed in a production environment.
- The EC2 instances for the Databases should be deployed in a private subnet, however in code, they were deployed in public subnets so they can be accessed for local testing and DB Failover between regions. In a real world production environment, bastion hosts or VPN (e.g. AWS VPN Client would be configured and deployed)
- In addition, the diagram shows VPC Peering similarly, this was not deployed for cost saving and local testing simplicity - In a real world production environment either VPC Peering or Transit Gateway would be configured and deployed - **More information around that can be found in the `ansible` directory `README.md`

## 🚀 How to Run Locally

- For Ansible: see `README.md` in `ansible` directory - **ALSO EXTENSIVE EXPLANATIONS OF REGION FAILOVER AND DECISIONS AROUND PROCESS FOR THE PURPOSE OF THIS PROJECT**
- For Terraform: see `README.md` in `infra` directory
- For Golang Application: see README..md in `dob-api` directory


## 📦 Deployment

1. Use Terraform to provision infrastructure.
2. Use GitHub Actions to build, test, and deploy.
3. Monitor logs and metrics for DBs with Prometheus & Alert Manager.

---

## 🔐 Security for Ideal Production Environment

- Any secrets exposed are for testing purposes only - in a real production scenario, Secrets Management would be enforced (e.g. Secrets Manager, Hashicorp Vault)
- Secure SSH access limited to specific IPs.
- Some security group rules are non-restrictive for testing purposes only from my local machine.

---

## 📚 Notes
- Designed for self-hosted PostgreSQL, avoiding managed services.
- Suitable for real-world SRE/DataOps challenges involving HA, DR, and automation.
- Code quality and testing prioritized.
- Use of common sense for validations, retries, and error handling.
- Application startup handles app user/table creation, removing the need for fragile logic in cloud-init scripts.