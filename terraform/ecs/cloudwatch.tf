resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_name}-${var.environment}-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # ECS Service Metrics
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-ms1-${var.environment}", "ClusterName", "${var.project_name}-cluster-${var.environment}"],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Microservice 1 - CPU and Memory"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", "${var.project_name}-ms2-${var.environment}", "ClusterName", "${var.project_name}-cluster-${var.environment}"],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Microservice 2 - CPU and Memory"
        }
      },
      # ALB Metrics
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", split("/", aws_lb.main.arn)[1]],
            [".", "TargetResponseTime", ".", "."],
            [".", "HTTPCode_Target_2XX_Count", ".", "."],
            [".", "HTTPCode_Target_4XX_Count", ".", "."],
            [".", "HTTPCode_Target_5XX_Count", ".", "."]
          ]
          period = 300
          stat   = "Sum"
          region = var.aws_region
          title  = "ALB - Request Metrics"
        }
      },
      # SQS Metrics
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/SQS", "NumberOfMessagesSent", "QueueName", split("/", var.sqs_queue_url)[4]],
            [".", "NumberOfMessagesReceived", ".", "."],
            [".", "ApproximateNumberOfMessagesVisible", ".", "."],
            [".", "ApproximateNumberOfMessagesNotVisible", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "SQS Queue Metrics"
        }
      },
      # ECS Service Running Tasks
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "RunningTaskCount", "ServiceName", "${var.project_name}-ms1-${var.environment}", "ClusterName", "${var.project_name}-cluster-${var.environment}"],
            [".", ".", ".", "${var.project_name}-ms2-${var.environment}", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "ECS Running Tasks"
        }
      }
    ]
  })
}

# CloudWatch Alarms

# Alarm for Microservice 1 High CPU
resource "aws_cloudwatch_metric_alarm" "microservice1_high_cpu" {
  alarm_name          = "${var.project_name}-ms1-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS CPU utilization for Microservice 1"
  alarm_actions       = []

  dimensions = {
    ServiceName = "${var.project_name}-ms1-${var.environment}"
    ClusterName = "${var.project_name}-cluster-${var.environment}"
  }

  tags = {
    Name = "${var.project_name}-ms1-cpu-alarm"
  }
}

# Alarm for Microservice 1 High Memory
resource "aws_cloudwatch_metric_alarm" "microservice1_high_memory" {
  alarm_name          = "${var.project_name}-ms1-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization for Microservice 1"
  alarm_actions       = []

  dimensions = {
    ServiceName = "${var.project_name}-ms1-${var.environment}"
    ClusterName = "${var.project_name}-cluster-${var.environment}"
  }

  tags = {
    Name = "${var.project_name}-ms1-memory-alarm"
  }
}

# Alarm for Microservice 2 High CPU
resource "aws_cloudwatch_metric_alarm" "microservice2_high_cpu" {
  alarm_name          = "${var.project_name}-ms2-${var.environment}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS CPU utilization for Microservice 2"
  alarm_actions       = []

  dimensions = {
    ServiceName = "${var.project_name}-ms2-${var.environment}"
    ClusterName = "${var.project_name}-cluster-${var.environment}"
  }

  tags = {
    Name = "${var.project_name}-ms2-cpu-alarm"
  }
}

# Alarm for Microservice 2 High Memory
resource "aws_cloudwatch_metric_alarm" "microservice2_high_memory" {
  alarm_name          = "${var.project_name}-ms2-${var.environment}-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This metric monitors ECS memory utilization for Microservice 2"
  alarm_actions       = []

  dimensions = {
    ServiceName = "${var.project_name}-ms2-${var.environment}"
    ClusterName = "${var.project_name}-cluster-${var.environment}"
  }

  tags = {
    Name = "${var.project_name}-ms2-memory-alarm"
  }
}

# Alarm for ALB 5xx Errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-${var.environment}-5xx-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "This metric monitors ALB 5xx errors"
  alarm_actions       = []

  dimensions = {
    LoadBalancer = split("/", aws_lb.main.arn)[1]
  }

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm"
  }
}

# Alarm for SQS Queue Depth (too many messages)
resource "aws_cloudwatch_metric_alarm" "sqs_queue_depth" {
  alarm_name          = "${var.project_name}-sqs-${var.environment}-queue-depth"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 300
  statistic           = "Average"
  threshold           = 100
  alarm_description   = "This metric monitors SQS queue depth"
  alarm_actions       = []

  dimensions = {
    QueueName = split("/", var.sqs_queue_url)[4]
  }

  tags = {
    Name = "${var.project_name}-sqs-depth-alarm"
  }
}

# Alarm for ECS Service Running Task Count (service down)
resource "aws_cloudwatch_metric_alarm" "microservice1_no_tasks" {
  alarm_name          = "${var.project_name}-ms1-${var.environment}-no-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors if Microservice 1 has no running tasks"
  alarm_actions       = []

  dimensions = {
    ServiceName = "${var.project_name}-ms1-${var.environment}"
    ClusterName = "${var.project_name}-cluster-${var.environment}"
  }

  tags = {
    Name = "${var.project_name}-ms1-tasks-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "microservice2_no_tasks" {
  alarm_name          = "${var.project_name}-ms2-${var.environment}-no-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "This metric monitors if Microservice 2 has no running tasks"
  alarm_actions       = []

  dimensions = {
    ServiceName = "${var.project_name}-ms2-${var.environment}"
    ClusterName = "${var.project_name}-cluster-${var.environment}"
  }

  tags = {
    Name = "${var.project_name}-ms2-tasks-alarm"
  }
}