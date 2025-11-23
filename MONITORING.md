# Monitoring Guide

## CloudWatch Dashboard

A comprehensive CloudWatch dashboard has been set up to monitor all services and infrastructure.

### Access the Dashboard

After running `terraform apply`, get the dashboard URL:
```bash
terraform output cloudwatch_dashboard_url
```

Or access it directly in the AWS Console:
- Navigate to CloudWatch → Dashboards
- Look for: `{project_name}-{environment}-dashboard`

### Dashboard Metrics

The dashboard includes the following widgets:

1. **Microservice 1 - CPU and Memory**
   - CPU Utilization
   - Memory Utilization

2. **Microservice 2 - CPU and Memory**
   - CPU Utilization
   - Memory Utilization

3. **ALB - Request Metrics**
   - Request Count
   - Target Response Time
   - HTTP 2xx Count
   - HTTP 4xx Count
   - HTTP 5xx Count

4. **SQS Queue Metrics**
   - Number of Messages Sent
   - Number of Messages Received
   - Approximate Number of Messages Visible
   - Approximate Number of Messages Not Visible

5. **ECS Running Tasks**
   - Running task count for both services

## CloudWatch Alarms

The following alarms are configured:

### Service Health Alarms

- **Microservice 1 High CPU**: Triggers when CPU > 80% for 2 periods (10 minutes)
- **Microservice 1 High Memory**: Triggers when Memory > 80% for 2 periods (10 minutes)
- **Microservice 2 High CPU**: Triggers when CPU > 80% for 2 periods (10 minutes)
- **Microservice 2 High Memory**: Triggers when Memory > 80% for 2 periods (10 minutes)

### Service Availability Alarms

- **Microservice 1 No Tasks**: Triggers when running task count < 1
- **Microservice 2 No Tasks**: Triggers when running task count < 1

### Application Health Alarms

- **ALB 5xx Errors**: Triggers when 5xx error count > 10 in 5 minutes
- **SQS Queue Depth**: Triggers when visible messages > 100 for 2 periods (10 minutes)

### Configuring Alarm Actions

To receive notifications when alarms trigger, add SNS topics to the `alarm_actions` in `terraform/ecs/cloudwatch.tf`:

```terraform
alarm_actions = [aws_sns_topic.alerts.arn]
```

## CloudWatch Logs

Log groups are automatically configured for both services:

- `/ecs/{project_name}-ms1-{environment}` - Microservice 1 logs
- `/ecs/{project_name}-ms2-{environment}` - Microservice 2 logs

Log retention: 7 days (configurable in `terraform/ecs/services.tf`)

### Viewing Logs

```bash
# View Microservice 1 logs
aws logs tail /ecs/RoyalHA-ms1-dev --follow

# View Microservice 2 logs
aws logs tail /ecs/RoyalHA-ms2-dev --follow
```

Or in AWS Console:
- Navigate to CloudWatch → Log groups
- Select the log group for your service

## Custom Metrics

To add custom application metrics, use the AWS SDK in your Python code:

```python
import boto3

cloudwatch = boto3.client('cloudwatch')

cloudwatch.put_metric_data(
    Namespace='Microservice1/Custom',
    MetricData=[
        {
            'MetricName': 'EmailsProcessed',
            'Value': 1,
            'Unit': 'Count'
        }
    ]
)
```

## Troubleshooting

### Alarms not triggering
- Check that services are running: `aws ecs describe-services --cluster <cluster> --services <service>`
- Verify alarm configuration: `aws cloudwatch describe-alarms --alarm-names <alarm-name>`

### Dashboard not showing data
- Ensure services have been running for at least 5 minutes (metrics are published every 5 minutes)
- Check that services are in the correct region

### Logs not appearing
- Verify ECS task execution role has CloudWatch Logs permissions
- Check task definition log configuration
- Ensure tasks are running: `aws ecs list-tasks --cluster <cluster> --service-name <service>`