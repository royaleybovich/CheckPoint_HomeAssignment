output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecr_repository_microservice1_url" {
  description = "URL of the ECR repository for microservice 1"
  value       = aws_ecr_repository.microservice1.repository_url
}

output "ecr_repository_microservice2_url" {
  description = "URL of the ECR repository for microservice 2"
  value       = aws_ecr_repository.microservice2.repository_url
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group for microservice 1"
  value       = aws_lb_target_group.microservice1.arn
}

output "microservice1_service_name" {
  description = "Name of the ECS service for microservice 1"
  value       = aws_ecs_service.microservice1.name
}

output "microservice2_service_name" {
  description = "Name of the ECS service for microservice 2"
  value       = aws_ecs_service.microservice2.name
}

output "cloudwatch_dashboard_url" {
  description = "URL to the CloudWatch dashboard"
  value       = "https://${var.aws_region}.console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.main.dashboard_name}"
}