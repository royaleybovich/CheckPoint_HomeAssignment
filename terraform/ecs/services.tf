resource "aws_cloudwatch_log_group" "microservice1" {
  name              = "/ecs/${var.project_name}-ms1-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ms1-logs"
  }
}

resource "aws_cloudwatch_log_group" "microservice2" {
  name              = "/ecs/${var.project_name}-ms2-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ms2-logs"
  }
}

resource "aws_ecs_service" "microservice1" {
  name            = "${var.project_name}-ms1-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservice1.arn
  desired_count   = var.microservice1_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.microservice1.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.microservice1.arn
    container_name   = "microservice1"
    container_port   = 8000
  }

  depends_on = [
    aws_lb_listener.main,
    aws_cloudwatch_log_group.microservice1
  ]

  tags = {
    Name        = "${var.project_name}-ms1-service"
    Description = "ECS service for microservice 1"
  }
}

resource "aws_ecs_service" "microservice2" {
  name            = "${var.project_name}-ms2-${var.environment}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservice2.arn
  desired_count   = var.microservice2_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.microservice2.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_cloudwatch_log_group.microservice2
  ]

  tags = {
    Name        = "${var.project_name}-ms2-service"
    Description = "ECS service for microservice 2"
  }
}