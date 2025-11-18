resource "aws_ecs_task_definition" "microservice1" {
  family                   = "${var.project_name}-ms1-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.microservice1_cpu
  memory                   = var.microservice1_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.microservice1_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "microservice1"
      image = "${aws_ecr_repository.microservice1.repository_url}:latest"

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = var.sqs_queue_url
        },
        {
          name  = "SSM_TOKEN_PARAMETER"
          value = var.ssm_token_parameter_name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-ms1-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-ms1-task"
    Description = "Task definition for microservice 1"
  }
}

resource "aws_ecs_task_definition" "microservice2" {
  family                   = "${var.project_name}-ms2-${var.environment}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.microservice2_cpu
  memory                   = var.microservice2_memory
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = var.microservice2_task_role_arn

  container_definitions = jsonencode([
    {
      name  = "microservice2"
      image = "${aws_ecr_repository.microservice2.repository_url}:latest"

      environment = [
        {
          name  = "SQS_QUEUE_URL"
          value = var.sqs_queue_url
        },
        {
          name  = "S3_BUCKET_NAME"
          value = var.s3_bucket_name
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.project_name}-ms2-${var.environment}"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project_name}-ms2-task"
    Description = "Task definition for microservice 2"
  }
}