locals {
  workspace_config = {
    "prod-primary" = {
      aws_region = "eu-west-1"
    },
    "prod-dr" = {
      aws_region = "eu-central-1"
    }
  }

  selected_config = lookup(local.workspace_config, terraform.workspace, {
    aws_region = "eu-west-1"
  })
}