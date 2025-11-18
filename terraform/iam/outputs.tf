output "microservice1_task_role_arn" {
  description = "ARN of the IAM role for microservice 1 tasks"
  value       = aws_iam_role.microservice1_task_role.arn
}

output "microservice2_task_role_arn" {
  description = "ARN of the IAM role for microservice 2 tasks"
  value       = aws_iam_role.microservice2_task_role.arn
}

output "ecs_task_execution_role_arn" {
  description = "ARN of the IAM role for ECS task execution"
  value       = aws_iam_role.ecs_task_execution_role.arn
}