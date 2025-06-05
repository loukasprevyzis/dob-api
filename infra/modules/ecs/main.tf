resource "aws_ecs_cluster" "dob_api" {
  name = var.ecs_cluster_name
}

resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "dob_api" {
  name              = "/ecs/dob-api"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "dob_api" {
  family                   = "dob-api-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "dob-api"
      image     = "${var.docker_image_url}:${var.docker_image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          hostPort      = 8080
        }
      ],
      environment = [
        { name = "DB_HOST", value = var.primary_ip },
        { name = "DB_PORT", value = "5432" },
        { name = "DB_USER", value = var.app_db_user },
        { name = "DB_REPLICA_HOST", value = var.replica_ip },
        { name = "DB_REPLICA_PORT", value = "5432" },
        { name = "DB_PRIMARY_HOST", value = var.primary_ip },
        { name = "DB_PRIMARY_PORT", value = "5432" },
        { name = "DB_BACKUP_ROLE_NAME", value = var.ec2_backup_role_name },
        { name = "AWS_REGION", value = var.aws_region },
        { name = "AWS_ACCOUNT_ID", value = var.account_id },
        { name = "DB_PASSWORD", value = var.app_db_password },
        { name = "DB_NAME", value = var.app_db_name }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/dob-api"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "dob-api"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "dob_api" {
  name            = "dob-api-service"
  cluster         = aws_ecs_cluster.dob_api.id
  task_definition = aws_ecs_task_definition.dob_api.arn
  launch_type     = "FARGATE"
  desired_count   = 2

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.sg_app_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.alb_target_group_arn
    container_name   = "dob-api"
    container_port   = 8080
  }

  depends_on = [var.alb_listener_arn]
}