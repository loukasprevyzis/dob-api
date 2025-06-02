cluster_name         = "dob-api"
ec2_ssh_key_name     = "dob-api-ec2-key"
primary_ip           = "10.0.1.126"
replica_ip           = "10.0.1.157"
aws_region           = "eu-west-1"
ec2_backup_role_name = "dob-api-ec2-backup-role"
account_id           = "123204938983"
app_db_user          = "dob_api_user"
app_db_password      = "TkmP8qLox6sCy3o"
app_db_name          = "dob_api_db"

domain_name        = "dob-api.click"
private_subnet_ids = ["subnet-0852d1ee226dc1ee1", "subnet-0d5fb085c85319579"]

public_subnet_id = "subnet-0bde1dc9088d99b94"
vpc_id           = "vpc-0d874d9245f2e757e"

nlb_dns_name = "dob-api-nlb-e404278fe6321d62.elb.eu-west-1.amazonaws.com"
nlb_zone_id  = "Z2IFOLAFXWLO4F"
