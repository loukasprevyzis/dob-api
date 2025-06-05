# PostgreSQL HA Setup with Ansible

This setup provisions a PostgreSQL **primary-replica pair** using Ansible. It includes system preparation, PostgreSQL installation, base backup for replication, WAL streaming configuration.

Additionally, it supports setting up primary and replica pairs in a **Disaster Recovery (DR) region**, enabling cross-region replication for increased resilience.

# Prerequisites for Running Ansible Locally

Before running your Ansible playbooks locally, ensure the following prerequisites are met:

## Install Ansible

- For Ubuntu/Debian:

  `sudo apt update`
  `sudo apt install ansible -y`


- For macOS (using Homebrew):
`brew install ansible`


- Install Required Ansible Collections
`ansible-galaxy collection install amazon.aws`


- Export or setup AWS Credentials:

```
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="your-region"
```
or in `~/.aws/credentials` add:

```
[default]
aws_access_key_id = your-access-key-id
aws_secret_access_key = your-secret-access-key
region = your-region
```
- Ensure Python 3 is installed on your controller machine and managed hosts.

```
pip3 install boto3 botocore
```
---
## 🔧 PostgreSQL Setup (Primary DBs - Both Regions)

## ⚙️ Using `postgresql@12-main` Service

The setup now uses the native Debian/Ubuntu PostgreSQL cluster service `postgresql@12-main` for:

- Standardized PostgreSQL management via systemd
- Configurations in `/etc/postgresql/12/main`
- Seamless service start/stop/restart
- Integration with OS tools and monitoring

### Features


- Installs PostgreSQL 12
- Formats and mounts a dedicated volume
- Initializes a new PostgreSQL cluster
- Configures `pg_hba.conf` for:
  - Local `postgres` user access
  - `replica` user for streaming replication
  - `dob_api_user` for application access
- Creates:
  - A `replica` user with `REPLICATION` privileges
  - An application user and database


---
## 🔧 PostgreSQL Setup (Replica DBs - Both Regions)
### Features

- Installs PostgreSQL 12
- Mounts a dedicated volume
- Performs `pg_basebackup` from the primary to initialize the data directory
- Sets up:
  - `postgresql.auto.conf` with `primary_conninfo` connection string
  - `standby.signal` file to enable streaming replication
- Manages PostgreSQL service via native systemd `postgresql@12-main` unit

---

## ⚙️ Variables

| Variable Name                   | Description                                                | Example / Notes                                                                                   |
|--------------------------------|------------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| `pg_version`                   | PostgreSQL version to install                              | `12`                                                                                               |
| `data_dir`                     | Base directory for PostgreSQL data                         | `/var/lib/postgresql/data`                                                                         |
| `pgdata_dir`                   | PostgreSQL data directory path                             | `{{ data_dir }}/pgdata`                                                                            |
| `postgres_password`            | Password for the `postgres` user                           | **Set securely, do not commit to repo**                                                            |
| `replication_user`             | Replication role username                                  | `replica`                                                                                          |
| `replication_password`         | Password for replication user                              | **Set securely, do not commit to repo**                                                            |
| `app_user`                     | Application database user                                  | `dob_api_user`                                                                                     |
| `app_password`                 | Password for application database user                     | **Set securely, do not commit to repo**                                                            |
| `app_db`                       | Application database name                                  | `dob_api_db`                                                                                       |
| `block_device`                 | Device to use for PostgreSQL data storage                  | `/dev/nvme1n1`                                                                                     |
| `primary_private_ip`           | Primary DB private IP in main region                       | `10.0.1.233`                                                                                       |
| `replica_private_ip`           | Replica DB private IP in main region                       | `10.0.1.213`                                                                                       |
| `primary_dr_private_ip`        | Primary DB private IP in DR region                         | `10.1.1.23`                                                                                        |
| `replica_dr_private_ip`        | Replica DB private IP in DR region                         | `10.1.1.253`                                                                                       |
| `primary_dr_public_ip`         | Public IP of DR primary DB                                 | `52.59.233.245`                                                                                    |
| `prometheus_user`              | System user running Prometheus                             | `prometheus`                                                                                       |
| `alertmanager_user`            | System user running Alertmanager                           | `alertmanager`                                                                                     |
| `postgres_exporter_version`    | Version of postgres_exporter to install                    | `"0.11.0"`                                                                                         |
| `prometheus_version`           | Version of Prometheus to install                           | `"2.50.0"`                                                                                         |
| `alertmanager_version`         | Version of Alertmanager to install                         | `"0.25.0"`                                                                                         |
| `alert_email_recipient`        | Email address to receive alerts                            | `loukas.prevyzis@outlook.com`                                                                      |
| `alert_email_sender`           | Email address used as sender in alert emails               | `loukas.prevyzis@outlook.com`                                                                      |
| `smtp_server`                  | SMTP server hostname                                       | `smtp.office365.com`                                                                              |
| `smtp_port`                    | SMTP server port                                           | `587`                                                                                              |
| `smtp_user`                    | SMTP authentication username                               | `loukas.prevyzis@outlook.com`                                                                      |
| `smtp_password`                | SMTP authentication password                               | **Set securely, do not commit to repo**                                                            |
| `prometheus_scrape_targets`   | List of Postgres exporter targets for Prometheus scraping  | `["{{ primary_private_ip }}:9187", "{{ replica_private_ip }}:9187", "{{ primary_dr_private_ip }}:9187", "{{ replica_dr_private_ip }}:9187"]` |
| `postgres_backup_bucket_primary` | S3 bucket name for primary region backups              | `dob-api-postgres-backups`                                                                         |
| `postgres_backup_bucket_dr`    | S3 bucket name for DR region backups                       | `dob-api-postgres-backups`                                                                         |
| `s3_bucket_map`                | Mapping of inventory groups to S3 buckets                  | ```yaml<br>s3_bucket_map:<br>  postgres_primary: "{{ postgres_backup_bucket_primary }}"<br>  postgres_primary_dr: "{{ postgres_backup_bucket_dr }}"<br>  postgres_replicas: "{{ postgres_backup_bucket_primary }}"<br>  postgres_replicas_dr: "{{ postgres_backup_bucket_dr }}"<br>``` |
| `ecs_cluster_name`             | ECS cluster name to update on failover                     | `dob-api-cluster`                                                                                  |
| `ecs_service_name`             | ECS service name to update on failover                     | `dob-api-service`                                                                                  |
| `task_definition_family`       | ECS task definition family name                            | `dob-api-task`                                                                                     |
| `ecs_execution_role_arn`       | IAM role for ECS task execution                            | `arn:aws:iam::123204938983:role/ecsTaskExecutionRole`                                              |
| `container_name`               | Container name inside ECS task                             | `dob-api`                                                                                          |


---

## ✅ Validation Checklist
## Database and User Permissions Verification

To verify that the application database and users are correctly configured with appropriate permissions, we ran the following query on the application database (`dob_api_db`):

```sql
SELECT
  grantee AS role_name,
  table_schema,
  table_name,
  string_agg(privilege_type, ', ') AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
GROUP BY grantee, table_schema, table_name
ORDER BY grantee, table_name;
```

Result:

![alt text](</screenshots/Screenshot 2025-06-02 at 21.53.27.png>)


### Replication Confimation

#### On the Primary

**Check active replication connections:**
`SELECT pid, client_addr, state, sync_state FROM pg_stat_replication;`

![alt text](</screenshots/Screenshot 2025-06-02 at 21.32.10.png>)

### On the Replica

**Check WAL receiver status:**
`SELECT * FROM pg_stat_wal_receiver;`

![alt text](</screenshots/Screenshot 2025-06-02 at 21.29.36.png>)

**Check replication delay (lag):**
`SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;`

![alt text](</screenshots/Screenshot 2025-06-02 at 21.33.14.png>)


**Confirm this is a standby server:**
`SELECT pg_is_in_recovery();`

![alt text](</screenshots/Screenshot 2025-06-02 at 21.34.17.png>)

**Test data sync by querying an application table:**

`SELECT * FROM users;`

![alt text](</screenshots/Screenshot 2025-06-02 at 21.44.28.png>)



## NOTE: Replication Slots

Replication slots are a PostgreSQL feature that ensures WAL files are retained on the primary until all connected replicas have received them, thereby preventing WAL loss during replication lag or network interruptions..

In this setup, replication slots have not been configured to avoid the potential disk space issues caused by slots that remain active when replicas disconnect or fall behind. The management of replication slots requires careful monitoring and cleanup to prevent excessive WAL accumulation..

Instead, reliance has been placed on configuring `wal_keep_segments` to retain a sufficient number of WAL files for replicas. This approach is considered sufficient for the current use case.

For production environments with higher reliability requirements, the implementation of replication slots alongside appropriate monitoring and alerting is recommended.

## 🗄️ Backup and WAL Archiving Setup (For Both Primary And DR Region DBs) (`db-backup.yml`)

To ensure data durability and enable point-in-time recovery (PITR), this setup automates PostgreSQL base backups and write-ahead log (WAL) archiving on the primary server with cloud storage integration.

### 📦 WAL Archiving to S3
WAL files containing all database changes are continuously archived directly to an AWS S3 bucket. This provides durable offsite storage and allows recovery to any point in time by replaying WALs from S3.

### 🗃️ Automated Base Backups with S3 Sync
A script runs daily to create a full base backup of the database using `pg_basebackup`.
The backup is stored locally temporarily, then synced to the designated S3 buckets
Old backups are cleaned up automatically based on a retention policy (default: 7 days).

### ⏰ Cron Job Automation
The base backup script is deployed to the server and scheduled via a daily cron job running as the `postgres` user.
This cron job executes the backup script automatically every night at 2 AM, ensuring regular backups without manual intervention.

### ⚙️ Configuration
PostgreSQL is configured with:
- `archive_mode = on`
- A customized `archive_command` that uploads WAL files to S3 using the AWS CLI

The backup and archiving mechanisms are fully automated, requiring minimal operational overhead.

### 🌍 Multi-Region Support
Backups and WAL archives are uploaded to **region-specific S3 buckets**, depending on whether the primary or DR region server is targeted — enabling disaster recovery across regions.


### 🛠️ Restore Script Deployment

An additional task deploys a helper script to DR and replica nodes for restoring the latest base backup from S3:

- The script:
  - Retrieves the **latest base backup** from the appropriate S3 bucket using `aws s3 ls`
  - Syncs the backup to a local directory (`/var/lib/postgresql/restore_data`)
  - Creates a `standby.signal` file to enable standby mode on PostgreSQL startup
  - Applies proper ownership and permissions

- The S3 bucket used is dynamically selected from a `s3_bucket_map` based on the host.

> 📝 This script is deployed but not executed by Ansible — it's intended to be manually or automatically run **before PostgreSQL startup** on a standby node to prepare it for replication.

This cloud-backed WAL archiving and backup solution enhances high availability, disaster recovery readiness, and minimizes potential data loss in production environments.

Script runs every night at 2 am and pushes backups to the respective S3 buckets that was deployed in the terraform module of this project with the appropriate permissions:


![alt text](</screenshots/Screenshot 2025-06-02 at 23.09.58.png>)

![alt text](</screenshots/Screenshot 2025-06-02 at 23.10.20.png>)

![alt text](</screenshots/Screenshot 2025-06-02 at 23.10.38.png>)

![alt text](</screenshots/Screenshot 2025-06-02 at 23.11.24.png>)

![alt text](</screenshots/Screenshot 2025-06-02 at 23.11.54.png>)

**Similarly in the DR region for the its primary DB:**

**Note: Ignore the timestamps as this script was automatically run at 2 am (EEST)**

![alt text](</screenshots/Screenshot 2025-06-03 at 00.16.57.png>)

![alt text](</screenshots/Screenshot 2025-06-03 at 00.17.16.png>)

![alt text](</screenshots/Screenshot 2025-06-03 at 00.18.28.png>)

### 🛠️ Restore Script Deployment

An additional task deploys a helper script to DR and replica nodes for restoring the latest base backup from S3:

- The script:
  - Retrieves the **latest base backup** from the appropriate S3 bucket using `aws s3 ls`
  - Syncs the backup to a local directory (`/var/lib/postgresql/restore_data`)
  - Creates a `standby.signal` file to enable standby mode on PostgreSQL startup
  - Applies proper ownership and permissions

- The S3 bucket used is dynamically selected from a `s3_bucket_map` based on the host.

> 📝 This script is deployed but not executed by Ansible — it's intended to be manually or automatically run if restore from back up is needed.
---

# Monitoring & Alerting Setup

The setup in `tasks/monitoring.yml` installs and configures:

- **Postgres Exporter:** Runs on all PostgreSQL hosts (primaries and replicas, in both regions) to expose metrics.
- **Prometheus:** Scrapes metrics from Postgres exporters and evaluates alert rules.
- **Alertmanager:** Sends alert notifications via SMTP email.

```
FOR COST SAVING, PROMETHEUS AND ALERTMANAGER WERE SET UP & CONFIGURED IN THE DR REPLICA DB EC2 INSTANCE
IN A REAL WORLD PRODUCTION ENVIRONMENT MONITORING AND ALERTING WOULD BE SET UP & CONFIGURED AS A STANDALONE CENTRALISED COMPONENTS FOR RESILIENCY
```

## Components

- **Postgres Exporter**
  Installed as a systemd service under user `{{ prometheus_user }}`.
  Metrics exposed on port `9187`.

- **Prometheus**
  Runs as a systemd service scraping metrics every 15 seconds.
  Configuration file location: `/etc/prometheus/prometheus.yml`.
  Alert rules stored in `/etc/prometheus/alerts.yml`.

- **Alertmanager**
  Runs as a systemd service and sends alert emails using SMTP credentials configured.
  Config located at `/etc/alertmanager/alertmanager.yml`.

## Prometheus Scrape Targets

Configured in `templates/prometheus.yml.j2`:

- Primary region primary DB: `{{ primary_private_ip }}:9187`
- Primary region replica DB: `{{ replica_private_ip }}:9187`
- DR region primary DB: `{{ primary_dr_private_ip }}:9187`
- DR region replica DB: `{{ replica_dr_private_ip }}:9187`

## Alerts Defined

Configured in `templates/alerts.yml.j2`:

| Alert Name                  | Expression                                         | Severity  | Description                                                        |
|-----------------------------|--------------------------------------------------|-----------|--------------------------------------------------------------------|
| `PostgresPrimaryDown`       | `up{job="postgresql", instance="{{ primary_private_ip }}:9187"} == 0` | `critical`  | Primary PostgreSQL server unreachable.                             |
| `PostgresReplicaDown`       | `up{job="postgresql", instance=~"{{ replica_private_ip }}:9187`|`{{ replica_dr_private_ip }}:9187"} == 0` | `warning`   | One or more replica servers unreachable.                         |
| `PostgresPrimaryAndReplicaDown` | `up{job="postgresql", instance=~"{{ primary_private_ip }}:9187`|`{{ replica_private_ip }}:9187"} == 0` | critical  | Both primary and main replica down, DR promotion may be needed.   |
| `PostgresReplicationLagHigh`| `pg_stat_replication_lag_seconds > 10`           | `warning`  | Replication lag exceeds 10 seconds.                                |


**Verify services are up and running:**

   ```
   sudo systemctl status postgres_exporter (For all instances)
   sudo systemctl status prometheus
   sudo systemctl status alertmanager
   ```
---



## Disaster Recovery Replica Streaming Replication

- The DR primary is set up to receive asynchronous streaming replication from the main region primary.
	- This reduces replication lag impact on the main region performance while maintaining data durability.
	- The DR replica is configured similarly to other replicas but points to the DR primary IP


### Disaster Recovery Region Failover

#### 🔄 Promote DR Standby Primary

This Ansible task sequence promotes the **standby primary in the DR region** during a disaster recovery (DR) failover event.

#### Intended Use:
- Main Region in (eu-west-1):
  - Primary and replica nodes are **down or unreachable**.
- DR Region (eu-central-1):
  - Standby "primary" node (ready to be promoted).
  - Standby "replica" node (follows the above after promotion).

#### What This Does:
1. **Promotes the standby** by removing `standby.signal` and running `pg_ctl promote`.
2. **Waits** for PostgreSQL to be ready on port 5432.
3. **Verifies** that the instance is no longer in recovery mode.
4. **Fails** clearly if promotion does not succeed.

#### Next Steps :
- Reconfigure the DR replica to follow the new primary:
  ```bash
  # On the DR replica:
  pg_basebackup ... # Or manually reconfigure recovery.conf

The task ansible file is in `promote-dr.yml` and it's triggered by a standalone playbook called `promote-dr-playbook.yml` with `ansible-playbook -i inventory.ini promote-dr-playbook.yml`.

**If monitoring alerts that primary region is unavailable then proceed with the above automation for DR Region Failover - For example:**

![alt text](</screenshots/Screenshot 2025-06-03 at 18.25.33.png>)


⚠️This task is part of the failover automation playbook and should be run only when the primary database is confirmed unavailable.⚠️

**IT IS MANUALLY TRIGGERED IN STANDALONE PIPELINE WORKFLOW, IF REQUIRED**

---

## Failover for ECS

To simulate a failover scenario where ECS starts pointing to the DR region's database without modifying DNS or VPC peering (for this project's personal cost saving):

1. **Assign a Public IP** to the DR region primary DB instance.
2. **Open Ingress Access** in the DR region DB's security group:

   ```hcl
   resource "aws_vpc_security_group_ingress_rule" "allow_temp_cross_region_db_access" {
     security_group_id = aws_security_group.sg_db.id
     from_port         = 5432
     to_port           = 5432
     ip_protocol       = "tcp"
     cidr_ipv4         = "0.0.0.0/0"
     description       = "TEMP: Open DB access for ECS failover test"
   }
   ```

3. **Update ECS to point to the DR DB IP:**

   Use the Ansible task file `update-ecs.yml` to register a new ECS task definition with the updated `DB_HOST` pointing to the DR DB’s public IP:

 `ansible-playbook -i inventory.ini promote-dr-playbook.yml`

4. **Force ECS Deployment:**
   ECS will redeploy your service using the new task definition pointing to the DR region DB.

> ⚠️ **Important:** This is only for short-term testing. Revert the security group changes after verification and restore `DB_HOST` to the primary region DB.

##### Tests to Confirm functionality:

- ECS New Task Defition should be running and pointing to DR Region DB Primary IP (DB_HOST):
![alt text](</screenshots/Screenshot 2025-06-04 at 21.00.50.png>)
![alt text](</screenshots/Screenshot 2025-06-04 at 20.59.34.png>)

- App responds and is available:
![alt text](</screenshots/Screenshot 2025-06-04 at 21.02.22.png>)
---

## 🔐 Deployment with SSH Private Keys and Pipeline Secrets

Ansible connects to target hosts over SSH using private keys for authentication. To enable automated deployments from a CI/CD pipeline:

- **SSH Private Key Usage:**
  The pipeline runner needs access to the SSH private key corresponding to the public key authorized on the target hosts. This key allows Ansible to authenticate without manual password entry.

- **Storing Keys Securely:**
  The private key should be stored as a **secret or environment variable** in pipeline settings (e.g., Bitbucket Pipelines, GitHub Actions Secrets). Never commit private keys directly into source control.

- **Injecting Keys During Pipeline Runs:**
  During the pipeline execution, the private key is written to a secure file (e.g., `~/.ssh/id_rsa`) with strict permissions, enabling Ansible to use it for SSH connections.

- **Example Workflow:**
  1. Add the SSH private key content as a pipeline secret variable.
  2. In the pipeline script, create the key file and set correct permissions.
  3. Run Ansible specifying the private key or relying on default SSH configuration.
  4. Remove the key file after deployment to avoid leaking credentials.

- **Encrypt vars/main.yml files with Ansible Vault:**
  - `ansible-vault encrypt ansible/roles/postgres/vars/main.yml`
  - ansible-vault encrypt ansible/roles/dr-failover/vars/main.yml
  - Add Vault password to pipeline secrets.

- **Best Practices:**
  - Use dedicated deployment SSH keys with limited access.
  - Restrict SSH access and use host key verification.
  - Combine with Ansible Vault or external secrets management for added security.

This approach ensures secure, seamless, and automated deployment using Ansible within the CI/CD pipeline Github Actions Workflow.

---

## 🔐 Further Security Notes

- **Passwords and sensitive credentials** such as `postgres_password`, `replication_password`, and `app_password` should **never be hardcoded** in your playbooks or repository.
- Use **Ansible Vault**, environment variables, or an external **secrets manager** (e.g., HashiCorp Vault, AWS Secrets Manager) to securely store and inject these secrets during playbook runs.
- Ensure **network access controls** and firewall rules restrict PostgreSQL ports (usually 5432) only to trusted hosts (e.g., replicas, application servers).
- Use **SSL/TLS encryption** for PostgreSQL connections in production to protect data in transit.
- Regularly rotate credentials and audit PostgreSQL logs for unusual access patterns to maintain security compliance.

---