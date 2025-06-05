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

 **Highly Available PostgreSQL Cluster**:
  - Multi-AZ primary + replica async streaming replication.
  - Cross-region failover capability to ensure recovery from zone or region outages.
  - Automated backups with restore and recovery process in the failover region.

**Automated CI/CD pipelines for:**

  - Build, test, and deployment of Go service.
  - Infrastructure provisioning using Terraform (Primary and Failover Disaster Recovery Region)
  - Ansible - To configure PostgreSQL, PostgreSQL replication & automated backups pushed to S3 (Both Prmary and Disaster Recovery regions)
  - Ansible for Failover (Promoting to Disaster Recovery Envionment)
  - No-downtime production deployment strategy.

- A clear **system architecture diagram** illustrating deployment in AWS.

---

# API Service Application Functionality Confirmation

![alt text](<screenshots/Screenshot 2025-06-04 at 19.45.10.png>)

![alt text](</screenshots/Screenshot 2025-06-04 at 19.45.16.png>)

![alt text](</screenshots/Screenshot 2025-06-04 at 19.45.41.png>)

---

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

>**“Route 53 failover is not deployed to avoid cost, but is part of the high availability design. In production, a domain (e.g., api.example.com) would point to a Route 53 hosted zone with a failover routing policy between primary and DR ALBs.”**



### Infrastructure & Deployment
- Deploys a primary region in eu-west-1.
- Terraform code provisions VPC, subnets, EC2, networking, and ECS cluster.
- Provisions R53 configuration for presentation only and commented out sections only for reference for failover routing policy.
- Deploys a secondary region in eu-central-1 for DB disaster recovery failover.
- Ansible configuration scripts for PostgreSQL Setup, DB Automated Backups & DR Region Failover
- Ansible for logs and metrics for DBs with Prometheus & Alert Manager.
- GitHub Actions for CI/CD pipeline

## 🗂️ System Diagram

![alt text](architecture-diagram.png)


This diagram represents the ideal production setup for this project, which for cost saving and local testing purposes it was deployed less restrictive (e.g. networking setup that can be seen in the main.tf of the networking terraform module) and without certain components.
To clarify:
- In the code's setup there is no R53 DNS with and no Failover Routing Policy for it. However in the diagram, it is suggested that this would be deployed in a production environment. It has been considered that if this project required a complete regional failover with DNS Failover Routing Policy etc., an additional standby ECS Cluster would be deployed as standby in the Disaster Recovery region as well. For better time management and personal cost saving, this was not included.

- The EC2 instances for the Databases should be deployed in a private subnet, however in code, they were deployed in public subnets so they can be accessed via their Public IPs for local testing and DB Failover between regions. In a real world production environment, bastion hosts or VPN (e.g. AWS VPN Client would be configured and deployed).


- In addition, the diagram shows VPC Peering similarly, this was not deployed for cost saving and local testing simplicity - In a real world production environment either VPC Peering or Transit Gateway would be configured and deployed - **More information around that can be found in the `ansible` directory `README.md`

⚠️PLEASE DO DOWNLOAD FROM GITHUB  UI  AS SHOWN BELOW, FOR BETTER QUALITY VISIBILITY - HAVE ALSO INCLUDED IT AS .drawio file in the root of this project.

![alt text](</screenshots/Screenshot 2025-06-05 at 17.47.26.png>)

---

## 🚀 How to Run Locally & In Depth Documentation Outside Of This README

- For Ansible: see documentation in `ansible/README.md`.
- For Terraform: see documentation  in the region folders in`infra/primary-region/README.md` & `infra/failover-region/README.md`.
- For Golang Application: see documentation in `dob-api/cmd/server/README.md`.
- For Golang API Setup: see documentation in `dob-api/internal/api/README-API.md`.
- For Golang API Unit Testing: see documentation in `dob-api/internal/api/README-TESTS.md`.
- For Docker Setup: see documentation in `dob-api/README-DOCKER.md`.
- For CICD Pipelines Setup: see doucumentation in `.github/workflows/README.md`


---

## 🔐 Security for Ideal Production Environment

- Any secrets exposed are for testing purposes only - in a real production scenario, Secrets Management would be enforced (e.g. Secrets Manager, Hashicorp Vault)
- Some security group rules are non-restrictive for testing purposes only from my local machine.

---

## 📚 Notes
- Designed for self-hosted PostgreSQL, avoiding managed services.
- Code quality and testing prioritized.
- Use of common sense for validations, retries, and error handling for the API app.
- Application startup handles app user/table creation, removing the need for fragile logic in cloud-init scripts.