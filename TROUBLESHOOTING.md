# Troubleshooting Guide

## Common Issues and Solutions

### Infrastructure Issues

#### ECS Service Not Starting

**Symptoms**: Service shows "PENDING" or tasks keep stopping

**Checklist**:
1. Verify task definition exists:
```bash
aws ecs describe-task-definition --task-definition RoyalHA-ms1-dev
```

2. Check task logs for errors:
```bash
aws logs tail /ecs/RoyalHA-ms1-dev --follow
```

3. Verify IAM roles have correct permissions:
```bash
aws iam get-role --role-name RoyalHA-ecs-task-execution-role-dev
```

4. Check if ECR image exists:
```bash
aws ecr describe-images --repository-name royalha-microservice1
```

5. Verify security groups allow traffic:
```bash
aws ec2 describe-security-groups --group-ids <sg-id>
```

**Common Causes**:
- Missing environment variables
- Incorrect IAM permissions
- Image pull errors (ECR authentication)
- Health check failures

### Application Issues

#### Microservice 1 - Invalid Token Error

**Symptoms**: `401 Invalid authentication token`

**Solutions**:
1. Verify token in SSM:
```bash
aws ssm get-parameter --name "/RoyalHA/dev/api-token" --with-decryption --query "Parameter.Value" --output text | tr -d '\n'
```

2. Check token has no trailing newline (use `tr -d '\n'`)

3. Verify `SSM_TOKEN_PARAMETER` environment variable is set correctly

4. Check service logs:
```bash
aws logs tail /ecs/RoyalHA-ms1-dev --follow | grep -i token
```

#### Microservice 1 - SQS Publish Fails

**Symptoms**: `500 Failed to publish message to queue`

**Solutions**:
1. Verify `SQS_QUEUE_URL` environment variable is set
2. Check IAM role has `sqs:SendMessage` permission
3. Verify queue exists:
```bash
aws sqs get-queue-url --queue-name RoyalHA-email-queue-dev
```

#### Microservice 2 - Messages Not Processing

**Symptoms**: Messages stay in SQS queue

**Solutions**:
1. Check if service is running:
```bash
aws ecs describe-services --cluster RoyalHA-cluster-dev --services RoyalHA-ms2-dev
```

2. Check service logs:
```bash
aws logs tail /ecs/RoyalHA-ms2-dev --follow
```

3. Verify `SQS_QUEUE_URL` and `S3_BUCKET_NAME` are set correctly

4. Check IAM permissions for SQS and S3

5. Verify S3 bucket exists:
```bash
aws s3 ls s3://$(terraform output -raw s3_bucket_name)
```

#### Microservice 2 - S3 Upload Fails

**Symptoms**: Messages processed but not in S3

**Solutions**:
1. Check IAM role has `s3:PutObject` permission
2. Verify bucket name is correct
3. Check service logs for S3 errors
4. Verify bucket exists and is accessible

### ALB Issues

#### Health Check Failing

**Symptoms**: Targets show as "unhealthy"

**Solutions**:
1. Check target group health:
```bash
aws elbv2 describe-target-health --target-group-arn <arn>
```

2. Verify security group allows traffic from ALB on port 8000
3. Check service is running and responding:
```bash
curl http://<alb-dns>/health
```

4. Verify health check path and port in target group configuration

#### 502 Bad Gateway

**Symptoms**: ALB returns 502 errors

**Solutions**:
1. Check if any tasks are running:
```bash
aws ecs list-tasks --cluster RoyalHA-cluster-dev --service-name RoyalHA-ms1-dev
```

2. Check service logs for application errors
3. Verify target group has healthy targets
4. Check security groups allow traffic

### CI/CD Issues

#### Jenkins Pipeline - Build Fails

**Error: "Unable to find Jenkinsfile"**
- **Solution**: Verify Script Path in Jenkins job configuration
- **Correct path**: `jenkins/Jenkinsfile.microservice1` (relative to repo root)

**Error: "docker build" requires exactly 1 argument**
- **Solution**: Use `DOCKER_BUILDKIT=0 docker build -t ... .` with explicit build context

**Error: "Unable to locate credentials"**
- **Solution**: Configure AWS credentials in Jenkins container:
```bash
docker exec checkpoint-jenkins aws configure
```

**Error: "python3-venv not available"**
- **Solution**: Pipeline now installs `python3-venv` automatically
- **Check**: Ensure Jenkins container has apt-get access

**Error: "pydantic-core build fails"**
- **Solution**: Upgraded pydantic to >=2.6.0 for Python 3.13 compatibility
- **Check**: Ensure `build-essential` and `python3-dev` are installed

#### Jenkins Pipeline - Deployment Fails

**Error: "Task definition not found"**
- **Solution**: Ensure infrastructure is deployed first (`terraform apply`)
- **Check**: Verify task definition exists:
```bash
aws ecs describe-task-definition --task-definition RoyalHA-ms1-dev
```

**Error: "Invalid JSON" when registering task definition**
- **Solution**: Use temporary file instead of stdin for JSON input
- **Check**: Verify `jq` is installed in Jenkins container

### Monitoring Issues

#### CloudWatch Dashboard Not Showing Data

**Solutions**:
1. Ensure services have been running for at least 5 minutes
2. Verify services are in the correct AWS region
3. Check that CloudWatch metrics are enabled (default for ECS/ALB)

#### CloudWatch Alarms Not Triggering

**Solutions**:
1. Verify alarm configuration:
```bash
aws cloudwatch describe-alarms --alarm-names RoyalHA-ms1-dev-high-cpu
```

2. Check alarm state:
```bash
aws cloudwatch describe-alarm-history --alarm-name RoyalHA-ms1-dev-high-cpu
```

3. Verify metric data exists:
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=RoyalHA-ms1-dev \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Network Issues

#### Cannot Access ALB

**Solutions**:
1. Verify ALB is in public subnets
2. Check security group allows inbound traffic on port 80/443
3. Verify internet gateway is attached to VPC
4. Check route tables for public subnets

#### Services Cannot Access SQS/S3

**Solutions**:
1. Verify services are in private subnets with NAT gateway
2. Check NAT gateway is in public subnet
3. Verify route tables route 0.0.0.0/0 to NAT gateway
4. Check security groups allow outbound traffic
5. Verify IAM roles have correct permissions

## Debugging Commands

### Check Service Status
```bash
# ECS Service
aws ecs describe-services --cluster RoyalHA-cluster-dev --services RoyalHA-ms1-dev

# Running Tasks
aws ecs list-tasks --cluster RoyalHA-cluster-dev --service-name RoyalHA-ms1-dev

# Task Details
aws ecs describe-tasks --cluster RoyalHA-cluster-dev --tasks <task-id>
```

### Check Logs
```bash
# Recent logs
aws logs tail /ecs/RoyalHA-ms1-dev --since 1h

# Follow logs
aws logs tail /ecs/RoyalHA-ms1-dev --follow

# Search logs
aws logs filter-log-events \
  --log-group-name /ecs/RoyalHA-ms1-dev \
  --filter-pattern "ERROR"
```

### Check Infrastructure
```bash
# VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=RoyalHA-vpc-dev"

# Subnets
aws ec2 describe-subnets --filters "Name=tag:Name,Values=RoyalHA-*"

# Security Groups
aws ec2 describe-security-groups --filters "Name=tag:Name,Values=RoyalHA-*"
```

### Test End-to-End
```bash
# Get ALB DNS
ALB_DNS=$(terraform output -raw alb_dns_name)

# Get Token
TOKEN=$(aws ssm get-parameter --name "/RoyalHA/dev/api-token" --with-decryption --query "Parameter.Value" --output text | tr -d '\n')

# Send Request
curl -X POST "http://${ALB_DNS}/api/email" \
  -H "Content-Type: application/json" \
  -d "{
    \"token\": \"${TOKEN}\",
    \"data\": {
      \"email_subject\": \"Test\",
      \"email_sender\": \"test@example.com\",
      \"email_timestream\": \"$(date +%s)\",
      \"email_content\": \"Test content\"
    }
  }"

# Check S3
BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 ls s3://${BUCKET}/emails/ --recursive | tail -5
```

## Getting Help

1. Check service logs first
2. Verify infrastructure is correctly deployed
3. Check IAM permissions
4. Review CloudWatch metrics and alarms
5. Test components individually

## Useful Resources

- [AWS ECS Troubleshooting](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/troubleshooting.html)
- [AWS ALB Troubleshooting](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-troubleshooting.html)
- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

