module "s3" {
  source = "../modules/s3"

  cluster_name                    = "dob-api"
  ec2_backup_role_name            = var.ec2_backup_role_name
  postgres_backups_bucket_name    = "dob-api-postgres-backups"
  terraform_state_bucket_name     = "dob-api-terraform-state-s3"
  terraform_lock_table_name       = "dob-api-terraform-lock"
}

module "networking" {
  source = "../modules/networking"

  aws_region  = var.aws_region
  office_cidr = "81.102.101.206/32" #personal VPN public IP

  vpc_cidr_block = "10.0.0.0/16"
  vpc_name       = "Primary-VPC-eu-west-1"

  public_subnet_cidrs = ["10.0.1.0/24", "10.0.4.0/24", "10.0.5.0/24"]
  public_subnet_azs   = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
  public_subnet_id    = "10.0.1.0/24"

  private_app_subnet_cidrs = ["10.0.2.0/24"]
  private_app_subnet_azs   = ["eu-west-1b"]

  private_db_subnet_cidrs = ["10.0.3.0/24"]
  private_db_subnet_azs   = ["eu-west-1c"]
  dob_api_alb             = "dob-api-alb"
  dob_api_tg              = "dob-api-tg"
}

module "r53" {
  source = "../modules/r53"

  domain_name = var.domain_name
  alb_zone_id = module.networking.alb_zone_id

  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  private_app_subnet_id   = module.networking.private_app_subnet_ids[0]
  security_group_app_id   = module.networking.security_group_app_id
  security_group_db_id    = module.networking.security_group_db_id
  route53_health_check_id = var.route53_health_check_id
  alb_dns_name            = module.networking.alb_dns_name
}

module "db" {
  source = "../modules/db"

  cluster_name         = "dob-api"
  db_name_primary      = "dob-api-db-primary"
  db_name_replica      = "dob-api-db-replica"
  ec2_ssh_key_name     = var.ec2_ssh_key_name
  ec2_private_key_pem  = var.ec2_private_key_pem
  db_data_volume_size  = var.db_data_volume_size
  app_db_name          = var.app_db_name
  app_db_user          = var.app_db_user
  app_db_password      = var.app_db_password
  ec2_backup_role_name = var.ec2_backup_role_name
  aws_region           = var.aws_region
  account_id           = var.account_id

  vpc_id                        = module.networking.vpc_id
  private_subnet_ids            = module.networking.private_db_subnet_ids
  public_subnet_id              = module.networking.public_subnet_ids[0]
  sg_app_id                     = module.networking.security_group_app_id
  sg_db_id                      = module.networking.security_group_db_id
  postgres_backup_bucket_arn    = module.s3.postgres_backups_arn
  backup_automation_policy      = "dob-api-backup-automation-policy"
  backup_automation_role        = "dob-api-backup-automation-role"
  ec2_postgres_backup_policy    = "dob-api-ec2-postgres-backup-policy"
}

module "ecr" {
  source = "../modules/ecr"
}

module "ecs" {
  source = "../modules/ecs"

  docker_image_url = var.docker_image_url
  ecs_cluster_name = "dob-api-cluster"
  docker_image_tag = var.docker_image_tag

  primary_ip           = module.db.primary_private_ip
  replica_ip           = module.db.replica_private_ip
  ec2_backup_role_name = var.ec2_backup_role_name

  aws_region = var.aws_region
  account_id = var.account_id

  app_db_user     = var.app_db_user
  app_db_password = var.app_db_password
  app_db_name     = var.app_db_name

  private_subnet_ids   = module.networking.private_app_subnet_ids
  sg_app_id            = module.networking.security_group_app_id
  alb_target_group_arn = module.networking.alb_target_group_arn
  alb_listener_arn     = module.networking.alb_listener_arn
}