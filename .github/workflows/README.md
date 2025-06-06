# GitHub Actions CI/CD Overview for dob-api

This repository implements a structured, production-grade GitHub Actions pipeline with clear separation of concerns and triggering conditions. The workflows are split into three files for clarity and control:

## Prerequisites

- Terraform S3 State Bucket must be created with `aws-cli` locally before terraform can manage it otherwise the pipeline will fail.
- AWS DynamoDB must be created with `aws-cli` locally before terraform can manage it otherwise the pipeline will fail.
- The AWS ECR repository used in the pipeline must be created beforehand, with terraform locally.
- You can create the ECR repository via Terraform by running the provided infrastructure code before triggering the pipeline.
- Ensure AWS credentials and permissions are correctly configured.


## CICD Pipeline (`dob-api CI/CD`)
**Trigger:** Automatically on PRs to `main` or pushes to `main`.

![alt text](</screenshots/Screenshot 2025-06-04 at 18.59.19.png>)
**Jobs:**
- ✅ Go Unit Tests — Runs automatically for both PRs and `main`.
- ✅ Docker Build & Push — Runs only for PRs.
- ✅ Terraform Plan (Primary & DR) — Runs only for PRs.
- ✅ Ansible Check Mode — Runs only for PRs.


## Manual Trigger Workflows - For Terraform Apply & Ansible Configuration Deployments
**Trigger:** Manually via GitHub UI (`workflow_dispatch`) on the `main` branch with `prod-manual` environment configured in the Github Repository settings.

![alt text](</screenshots/Screenshot 2025-06-04 at 19.13.07.png>)
**Jobs:**
- ⏩ Terraform Apply — Primary region.
- ⏩ Terraform Apply — DR region.
- ⏩ Ansible Deploy — Executes playbooks for both primary and DR DBs.

Each job accepts input parameters like:
- `environment` (e.g. `prod-manual`)
- `version` (commit SHA or tag, optional)

## DR Failover (`dob-api - Ansible Promote DR`)

**Trigger:** Manually via GitHub UI (`workflow_dispatch`) on the `main` branch with `prod-manual` environment configured in the Github Repository settings.

![alt text](</screenshots/Screenshot 2025-06-04 at 19.32.02.png>)

**Job:**
- ⏩ Promote DR — Runs Ansible playbook to failover the DR region to become primary (DBs and ECS Task Definition update).


---

## Variables and Secrets

![alt text](</screenshots/Screenshot 2025-06-05 at 17.39.26.png>)
![alt text](</screenshots/Screenshot 2025-06-05 at 17.39.49.png>)

## Why This Setup?
- 🔒 Production deploys and DB promotions are protected by manual triggers.
- ✅ All non-destructive operations are automated at PR level.
- 📄 Input parameters allow flexible, traceable deployment operations.

This setup balances automation and safety, ideal for high-stakes environments like fintech/SRE workflows.