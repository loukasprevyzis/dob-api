

# GitHub Actions CI/CD Overview for dob-api

This repository implements a structured, production-grade GitHub Actions pipeline with clear separation of concerns and triggering conditions. The workflows are split into three files for clarity and control:

## 1. CI Pipeline (`dob-api CI/CD`)
**Trigger:** Automatically on PRs to `main` or pushes to `main`.

**Jobs:**
- ✅ Go Unit Tests — Runs automatically for both PRs and `main`.
- ✅ Docker Build & Push — Runs only for PRs.
- ✅ Terraform Plan (Primary & DR) — Runs only for PRs.
- ✅ Ansible Check Mode — Runs only for PRs.

## 2. Manual Deployments (`dob-api Manual Deploys`)
**Trigger:** Manually via GitHub UI (`workflow_dispatch`) on the `main` branch with `prod-manual` environment configured in the Github Repository settings.

**Jobs:**
- ⏩ Terraform Apply — Primary region.
- ⏩ Terraform Apply — DR region.
- ⏩ Ansible Deploy — Executes playbooks for both primary and DR DBs.

Each job accepts input parameters like:
- `environment` (e.g. `prod-manual`)
- `version` (commit SHA or tag, optional)

## 3. Promote DR (`dob-api - Ansible Promote DR`)
**Trigger:** Manually via GitHub UI (`workflow_dispatch`) on the `main` branch with `prod-manual` environment configured in the Github Repository settings.
.

**Job:**
- ⏩ Promote DR — Runs Ansible playbook to failover the DR region to become primary.

## Why This Setup?
- 🔒 Production deploys and DB promotions are protected by manual triggers.
- ✅ All non-destructive operations are automated at PR level.
- 📄 Input parameters allow flexible, traceable deployment operations.

This setup balances automation and safety, ideal for high-stakes environments like fintech/SRE workflows.