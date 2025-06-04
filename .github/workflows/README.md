# dob-api CI/CD Pipeline

This repository contains the CI/CD pipeline for the **dob-api** Go application, using GitHub Actions for automation. It covers build, test, Docker image build & push, Terraform infrastructure management, and Ansible deployments.

---

## Workflow Triggers

- **Pull Requests** targeting `main`:
  - Run Go unit tests
  - Terraform plan for primary and failover regions
  - Ansible check (dry run)

- **Pushes** to `main` branch and manual workflow dispatch:
  - Run Go unit tests
  - Build and push Docker image to AWS ECR
  - Terraform apply for primary and failover regions
  - Ansible deployment with vault secrets
  - **Manual promotion for DB region failover and ECS failover using Ansible**

---

## Jobs Overview

### 1. `go-test`

- Runs Go unit tests with coverage.
- Caches Go modules for speed.
- Runs on `ubuntu-latest`.

### 2. `docker-build-push`

- Builds a Docker image for the Go app.
- Tags image with short Git commit SHA.
- Pushes image to AWS ECR.
- Depends on `go-test`.

### 3. Terraform Jobs

- **Plan jobs** run on PRs to check infra changes in:
  - `infra/primary-region` (eu-west-1)
  - `infra/failover-region` (eu-central-1)

- **Apply jobs** run on manual triggers (`workflow_dispatch`) on `main`:
  - Apply changes in primary and failover infra regions.

### 4. Ansible Jobs

- **ansible-plan**: Runs in check mode on PRs to validate playbook.
- **ansible-deploy**: Runs on manual trigger (`workflow_dispatch`) on `main` to deploy playbook using vault and SSH keys.
- **ansible-promote-dr**: Runs only on manual trigger (`workflow_dispatch`) on `main` to perform DB region failover promotion and ECS failover to the new primary DB region.

---

## Secrets and Variables

Below are the required secrets and variables you need to configure in your GitHub repository settings:

- AWS credentials:  
  - `AWS_ACCESS_KEY_ID` (variable)  
  - `AWS_SECRET_ACCESS_KEY` (secret)  
- AWS ECR repository: `ECR_REPOSITORY` (variable)  
- SSH private keys for Ansible:  
  - `SSH_PRIVATE_KEY_PRIMARY` (secret)  
  - `SSH_PRIVATE_KEY_FAILOVER` (secret)  
- Ansible vault password: `ANSIBLE_VAULT_PASSWORD` (secret)  
- Infrastructure hosts for SSH scan (variables):  
  - `PRIMARY_DB_HOST`  
  - `PRIMARY_REPLICA_DB_HOST`  
  - `FAILOVER_DB_HOST`  
  - `FAILOVER_REPLICA_DB_HOST`

### Example: GitHub Secrets Setup

![GitHub Secrets Setup Screenshot](./docs/github-secrets-setup.png)

---

## Workflow Runs

### Pull Request Pipeline (main/develop branches)

This pipeline runs on every PR targeting `main` or `develop` and includes tests, Terraform plans, and Ansible checks.

**Go Unit Testing**

---

### Main Branch Deployment Pipeline

This pipeline runs on pushes to `main` and manual triggers to deploy infrastructure and the application.

![Main Pipeline Run Screenshot](./docs/main-pipeline-run.png)

---

### Manual Promote DR Job

This manual job runs only when triggered from the GitHub Actions UI on the `main` branch. It promotes database failover to the primary region and updates ECS services accordingly, using the Ansible playbook `promote-dr-playbook.yml`.

---

## Usage

- Push or open a PR to `main` or `develop` to run tests and plans.
- Manually trigger the workflow on the `main` branch to deploy infrastructure and application.
- Manually trigger the **Promote DR** job on `main` to execute failover promotion.

---

## Requirements

- AWS ECR repository must exist.
- Terraform and Ansible playbooks are configured in `infra/` and `ansible/` directories.
- Secrets and variables configured in the GitHub repository settings.

---

## Notes

- Docker image is built for `linux/amd64` platform.
- Terraform version used is `1.5.7`.
- Go version used is `1.24`.

---

## License

MIT License