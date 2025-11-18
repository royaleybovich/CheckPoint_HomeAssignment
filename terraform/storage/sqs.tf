resource "aws_sqs_queue" "email_queue" {
  name                      = "${var.project_name}-email-queue-${var.environment}"
  message_retention_seconds = 86400 # 24 hours
  receive_wait_time_seconds = 20    # Long polling

  tags = {
    Name        = "${var.project_name}-email-queue"
    Description = "SQS queue for email messages from microservice 1 to microservice 2"
  }
}

# Dead Letter Queue for failed messages
resource "aws_sqs_queue" "email_queue_dlq" {
  name                      = "${var.project_name}-email-queue-dlq-${var.environment}"
  message_retention_seconds = 1209600 # 14 days

  tags = {
    Name        = "${var.project_name}-email-queue-dlq"
    Description = "Dead letter queue for failed email messages"
  }
}

# Redrive policy to connect main queue to DLQ
resource "aws_sqs_queue_redrive_policy" "email_queue" {
  queue_url = aws_sqs_queue.email_queue.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_queue_dlq.arn
    maxReceiveCount     = 3
  })
}