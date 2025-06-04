cluster_name         = "dob-api"
ec2_ssh_key_name     = "dob-api-ec2-key"
primary_ip           = "10.0.1.126"
replica_ip           = "10.0.1.157"
aws_region           = "eu-central-1"
environment          = "dr"
ec2_backup_role_name = "dob-api-ec2-backup-role"
account_id           = "123204938983"
app_db_user          = "dob_api_user"
app_db_password      = ""
app_db_name          = "dob_api_db_dr"

domain_name = "dob-api.click" #if domain name was used to replace nlb dns name