module "s3" {
  providers = {
    aws = aws.primary
  }
  source                          = "../modules/s3"
  cluster_name                    = "dob-api-${local.name_suffix}"
  postgres_backups_bucket_name    = "dob-api-postgres-backups"
  terraform_state_bucket_name     = "dob-api-terraform-state-s3"
  terraform_lock_table_name       = "dob-api-terraform-lock"
  ec2_backup_role_name            = var.ec2_backup_role_name
}

module "networking" {
  source = "../modules/networking"

  aws_region  = var.aws_region
  office_cidr = "81.102.101.206/32" # for SSH

  vpc_cidr_block = "10.1.0.0/16"
  vpc_name       = "Failover-VPC-${local.name_suffix}"

  public_subnet_cidrs = ["10.1.1.0/24", "10.1.4.0/24", "10.1.5.0/24"]
  public_subnet_azs   = ["${var.aws_region}a", "${var.aws_region}b", "${var.aws_region}c"]
  public_subnet_id    = "10.1.1.0/24"

  private_app_subnet_cidrs = ["10.1.2.0/24"]
  private_app_subnet_azs   = ["${var.aws_region}b"]

  private_db_subnet_cidrs = ["10.1.3.0/24"]
  private_db_subnet_azs   = ["${var.aws_region}c"]
  dob_api_alb             = "dob-api-alb-${local.name_suffix}"
  dob_api_tg              = "dob-api-tg-${local.name_suffix}"
}

module "r53" {
  source = "../modules/r53"

  domain_name = "${var.domain_name}-${local.name_suffix}"
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

  cluster_name         = "dob-api-${local.name_suffix}"
  db_name_primary      = "dob-api-db-primary-${local.name_suffix}"
  db_name_replica      = "dob-api-db-replica-${local.name_suffix}"
  ec2_ssh_key_name     = var.ec2_ssh_key_name
  ec2_private_key_pem  = var.ec2_private_key_pem
  db_data_volume_size  = var.db_data_volume_size
  app_db_name          = var.app_db_name
  app_db_user          = var.app_db_user
  app_db_password      = var.app_db_password
  ec2_backup_role_name = var.ec2_backup_role_name
  aws_region           = var.aws_region
  account_id           = var.account_id

  vpc_id                     = module.networking.vpc_id
  private_subnet_ids         = module.networking.private_db_subnet_ids
  public_subnet_id           = module.networking.public_subnet_ids[0]
  sg_app_id                  = module.networking.security_group_app_id
  sg_db_id                   = module.networking.security_group_db_id
  postgres_backup_bucket_arn = module.s3.postgres_backups_arn

  backup_automation_policy      = "dob-api-${local.name_suffix}-backup-automation-policy"
  backup_automation_role        = "dob-api-${local.name_suffix}-backup-automation-role"
  ec2_postgres_backup_policy    = "dob-api-${local.name_suffix}-ec2-postgres-backup-policy"
}

module "ecr" {
  source = "../modules/ecr"
}

module "ecs" {
  source = "../modules/ecs"

  ecs_cluster_name = "dob-api-cluster-${local.name_suffix}"
  docker_image_url = var.docker_image_url
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