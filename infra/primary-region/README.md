## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

```

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

```

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_db"></a> [db](#module\_db) | ../modules/db | n/a |
| <a name="module_ecr"></a> [ecr](#module\_ecr) | ../modules/ecr | n/a |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | ../modules/ecs | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ../modules/networking | n/a |
| <a name="module_r53"></a> [r53](#module\_r53) | ../modules/r53 | n/a |
| <a name="module_s3"></a> [s3](#module\_s3) | ../modules/s3 | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | AWS account ID | `string` | n/a | yes |
| <a name="input_app_db_name"></a> [app\_db\_name](#input\_app\_db\_name) | Database name for the application | `string` | n/a | yes |
| <a name="input_app_db_password"></a> [app\_db\_password](#input\_app\_db\_password) | Database password for the application | `string` | n/a | yes |
| <a name="input_app_db_user"></a> [app\_db\_user](#input\_app\_db\_user) | Database user for the application | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS Region | `string` | `"eu-west-1"` | no |
| <a name="input_cluster_public_access_cidrs"></a> [cluster\_public\_access\_cidrs](#input\_cluster\_public\_access\_cidrs) | List of CIDR blocks allowed to access the ECS cluster API server | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_db_data_volume_size"></a> [db\_data\_volume\_size](#input\_db\_data\_volume\_size) | Size of EBS volume for PostgreSQL data (GB) | `number` | `100` | no |
| <a name="input_docker_image_tag"></a> [docker\_image\_tag](#input\_docker\_image\_tag) | Docker image tag to deploy | `string` | `"latest"` | no |
| <a name="input_docker_image_url"></a> [docker\_image\_url](#input\_docker\_image\_url) | n/a | `string` | `"123204938983.dkr.ecr.eu-west-1.amazonaws.com/dob-api"` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | The Route53 hosted zone domain name, e.g., example.com | `string` | n/a | yes |
| <a name="input_ec2_backup_role_name"></a> [ec2\_backup\_role\_name](#input\_ec2\_backup\_role\_name) | IAM role name used by EC2 for PostgreSQL backup encryption | `string` | n/a | yes |
| <a name="input_ec2_private_key_pem"></a> [ec2\_private\_key\_pem](#input\_ec2\_private\_key\_pem) | EC2 key pair PEM file content | `string` | `""` | no |
| <a name="input_ec2_ssh_key_name"></a> [ec2\_ssh\_key\_name](#input\_ec2\_ssh\_key\_name) | EC2 SSH key pair name | `string` | n/a | yes |
| <a name="input_office_cidr"></a> [office\_cidr](#input\_office\_cidr) | n/a | `string` | `"81.102.101.206/32"` | no |
| <a name="input_primary_ip"></a> [primary\_ip](#input\_primary\_ip) | Private IP of primary DB instance | `string` | `""` | no |
| <a name="input_private_subnet_ids"></a> [private\_subnet\_ids](#input\_private\_subnet\_ids) | n/a | `list(string)` | n/a | yes |
| <a name="input_public_subnet_id"></a> [public\_subnet\_id](#input\_public\_subnet\_id) | ID of the public subnet to use for the Instances | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"eu-west-1"` | no |
| <a name="input_replica_ip"></a> [replica\_ip](#input\_replica\_ip) | IP address of the replica DB instance | `string` | `""` | no |
| <a name="input_route53_health_check_id"></a> [route53\_health\_check\_id](#input\_route53\_health\_check\_id) | n/a | `string` | `""` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID where ECS and related resources will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ec2_private_key_pem"></a> [ec2\_private\_key\_pem](#output\_ec2\_private\_key\_pem) | n/a |
