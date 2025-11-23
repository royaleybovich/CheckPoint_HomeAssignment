resource "aws_ecr_repository" "microservice1" {
  name                 = lower("${var.project_name}-microservice1")
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-microservice1-ecr"
    Description = "ECR repository for microservice 1 Docker images"
  }
}

resource "aws_ecr_repository" "microservice2" {
  name                 = lower("${var.project_name}-microservice2")
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-microservice2-ecr"
    Description = "ECR repository for microservice 2 Docker images"
  }
}