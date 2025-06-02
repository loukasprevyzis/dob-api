# PostgreSQL HA Setup with Ansible

This setup provisions a PostgreSQL **primary-replica pair** using Ansible. It includes system preparation, PostgreSQL installation, base backup for replication, WAL streaming configuration, and optional replication slot support.

Additionally, it supports setting up primary and replica pairs in a **Disaster Recovery (DR) region**, enabling cross-region replication for increased resilience.

---

## 🔧 Primary Node Setup

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
- Creates a physical replication slot (optional but recommended)

### Variables

- `postgres_password`: password for the default `postgres` user
- `replication_password`: password for the `replica` user
- `app_password`: password for the application user
- `replication_slot` (optional): slot name to retain WAL files for replica

---

## 📥 Replica Node Setup

### Features

- Installs PostgreSQL 12
- Mounts a dedicated volume
- Performs `pg_basebackup` from the primary to initialize the data directory
- Sets up:
  - `postgresql.auto.conf` with `primary_conninfo` connection string
  - `standby.signal` file to enable streaming replication
- Manages PostgreSQL service via native systemd `postgresql@12-main` unit

## ⚙️ Variables

| Variable               | Description                                                    |
|------------------------|----------------------------------------------------------------|
| `pg_version`           | PostgreSQL major version to install (e.g., 12)                |
| `data_dir`             | Base directory where PostgreSQL data will be stored           |
| `pgdata_dir`           | Full path to PostgreSQL data directory (`{{ data_dir }}/pgdata`) |
| `postgres_password`    | Password for the default `postgres` superuser                 |
| `replication_user`     | Username for the replication role                              |
| `replication_password` | Password for the replication user                              |
| `app_user`             | Application database user                                      |
| `app_password`         | Password for the application user                              |
| `app_db`               | Name of the application database                               |
| `block_device`         | Block device path to format and mount for PostgreSQL data     |
| `primary_private_ip`   | Private IP address of the primary PostgreSQL server           |
| `replica_private_ip`   | Private IP address of the replica PostgreSQL server           |
| `primary_dr_private_ip`| Private IP of the primary in the Disaster Recovery (DR) region|
| `replica_dr_private_ip`| Private IP of the replica in the Disaster Recovery (DR) region|

---

## 🌍 Disaster Recovery (DR) Region Setup

This playbook supports installing PostgreSQL a **primary-replica pair in a DR region**, ensuring data replication across geographically separated data centers for improved fault tolerance and disaster resilience.

DR setup uses the same mechanisms but points the replica to the DR primary instance IP and credentials.

---

## ⚙️ Using `postgresql@12-main` Service

The setup now uses the native Debian/Ubuntu PostgreSQL cluster service `postgresql@12-main` for:

- Standardized PostgreSQL management via systemd
- Configurations in `/etc/postgresql/12/main`
- Seamless service start/stop/restart
- Integration with OS tools and monitoring

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

![alt text](<Screenshot 2025-06-02 at 21.53.27.png>)


### Replication Confimation

#### On the Primary

**Check active replication connections:**
`SELECT pid, client_addr, state, sync_state FROM pg_stat_replication;`

![alt text](<Screenshot 2025-06-02 at 21.32.10.png>)

### On the Replica

**Check WAL receiver status:**
SELECT * FROM pg_stat_wal_receiver;

![alt text](<Screenshot 2025-06-02 at 21.29.36.png>)

**Check replication delay (lag):**
`SELECT now() - pg_last_xact_replay_timestamp() AS replication_delay;`

![alt text](<Screenshot 2025-06-02 at 21.33.14.png>)


**Confirm this is a standby server:**
`SELECT pg_is_in_recovery();`

![alt text](<Screenshot 2025-06-02 at 21.34.17.png>)

**Test data sync by querying an application table:**

`SELECT * FROM users;`

![alt text](<Screenshot 2025-06-02 at 21.44.28.png>)


## NOTE: Replication Slots

Replication slots are a PostgreSQL feature that ensures WAL files are retained on the primary until all connected replicas have received them, thereby preventing WAL loss during replication lag or network interruptions..

In this setup, replication slots have not been employed to avoid the potential for disk space issues caused by slots that remain active when replicas disconnect or fall behind. The management of replication slots requires careful monitoring and cleanup to prevent excessive WAL accumulation..

Instead, reliance has been placed on configuring `wal_keep_segments` to retain a sufficient number of WAL files for replicas. This approach is considered sufficient for the current use case.

For production environments with higher reliability requirements, the implementation of replication slots alongside appropriate monitoring and alerting is recommended.

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

- **Best Practices:**
  - Use dedicated deployment SSH keys with limited access.
  - Restrict SSH access and use host key verification.
  - Combine with Ansible Vault or external secrets management for added security.

This approach ensures secure, seamless, and automated deployment using Ansible within your CI/CD pipelines.

## 🔐 Security Note

- **Passwords and sensitive credentials** such as `postgres_password`, `replication_password`, and `app_password` should **never be hardcoded** in your playbooks or repository.
- Use **Ansible Vault**, environment variables, or an external **secrets manager** (e.g., HashiCorp Vault, AWS Secrets Manager) to securely store and inject these secrets during playbook runs.
- Ensure **network access controls** and firewall rules restrict PostgreSQL ports (usually 5432) only to trusted hosts (e.g., replicas, application servers).
- Use **SSL/TLS encryption** for PostgreSQL connections in production to protect data in transit.
- Regularly rotate credentials and audit PostgreSQL logs for unusual access patterns to maintain security compliance.

