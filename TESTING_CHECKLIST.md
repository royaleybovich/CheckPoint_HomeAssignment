# Final Testing Checklist

Use this checklist to verify the entire system is working correctly.

## Pre-Deployment Checks

### Infrastructure
- [ ] Terraform validates successfully (`terraform validate`)
- [ ] Terraform plan shows expected changes
- [ ] All required variables are set
- [ ] AWS credentials are configured
- [ ] Target AWS region is correct

### Code Quality
- [ ] Unit tests pass for Microservice 1 (`pytest microservice1/tests/`)
- [ ] Unit tests pass for Microservice 2 (`pytest microservice2/tests/`)
- [ ] No linting errors
- [ ] Docker images build successfully locally

## Infrastructure Deployment

- [ ] `terraform init` completes successfully
- [ ] `terraform plan` shows expected resources
- [ ] `terraform apply` completes without errors
- [ ] All resources created successfully:
  - [ ] VPC and networking
  - [ ] S3 bucket
  - [ ] SQS queue and DLQ
  - [ ] SSM parameter
  - [ ] IAM roles
  - [ ] ECS cluster
  - [ ] ECR repositories
  - [ ] ALB and target groups
  - [ ] CloudWatch log groups
  - [ ] CloudWatch dashboard
  - [ ] CloudWatch alarms

## Verify Infrastructure Outputs

- [ ] ALB DNS name is available
- [ ] ECR repository URLs are correct
- [ ] CloudWatch dashboard URL is accessible
- [ ] S3 bucket name is correct
- [ ] SQS queue URL is correct
- [ ] SSM parameter exists and has value

## CI/CD Pipeline

### Jenkins Setup
- [ ] Jenkins is running and accessible
- [ ] AWS credentials configured in Jenkins
- [ ] Jenkins jobs created for both microservices
- [ ] Git repository is accessible from Jenkins

### Pipeline Execution
- [ ] Checkout stage succeeds
- [ ] Test stage runs and passes
- [ ] Build stage creates Docker image
- [ ] Push stage uploads to ECR
- [ ] Deploy stage updates ECS service
- [ ] Pipeline completes successfully

## Service Deployment

### Microservice 1
- [ ] Task definition registered successfully
- [ ] ECS service is running
- [ ] At least 1 task is running
- [ ] Task is healthy (passes health check)
- [ ] Service is registered with ALB target group
- [ ] Target shows as healthy in ALB

### Microservice 2
- [ ] Task definition registered successfully
- [ ] ECS service is running
- [ ] At least 1 task is running
- [ ] Task is healthy

## Functional Testing

### Microservice 1 - Health Check
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
curl http://${ALB_DNS}/health
```
- [ ] Returns 200 OK
- [ ] Response contains `"status": "healthy"`

### Microservice 1 - Token Validation
```bash
TOKEN=$(aws ssm get-parameter --name "/RoyalHA/dev/api-token" --with-decryption --query "Parameter.Value" --output text | tr -d '\n')
curl -X POST "http://${ALB_DNS}/api/email" \
  -H "Content-Type: application/json" \
  -d '{"token": "wrong-token", "data": {...}}'
```
- [ ] Returns 401 with invalid token
- [ ] Returns 200 with valid token

### Microservice 1 - Payload Validation
```bash
curl -X POST "http://${ALB_DNS}/api/email" \
  -H "Content-Type: application/json" \
  -d '{"token": "'${TOKEN}'", "data": {"email_subject": ""}}'
```
- [ ] Returns 422 with missing/empty fields
- [ ] Returns 200 with valid payload

### End-to-End Flow
```bash
# Send valid request
curl -X POST "http://${ALB_DNS}/api/email" \
  -H "Content-Type: application/json" \
  -d "{
    \"token\": \"${TOKEN}\",
    \"data\": {
      \"email_subject\": \"Test Email\",
      \"email_sender\": \"test@example.com\",
      \"email_timestream\": \"$(date +%s)\",
      \"email_content\": \"Test content\"
    }
  }"
```
- [ ] Returns 200 with success message
- [ ] Message appears in SQS queue
- [ ] Message is processed by Microservice 2
- [ ] File appears in S3 bucket

### Verify S3 Upload
```bash
BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 ls s3://${BUCKET}/emails/ --recursive
```
- [ ] File exists in S3
- [ ] File path follows pattern: `emails/YYYY/MM/DD/timestamp-uuid.json`
- [ ] File content is valid JSON
- [ ] File contains all email fields

## Monitoring Verification

### CloudWatch Logs
- [ ] Microservice 1 logs are appearing
- [ ] Microservice 2 logs are appearing
- [ ] Logs contain expected information
- [ ] No excessive error messages

### CloudWatch Dashboard
- [ ] Dashboard is accessible
- [ ] Metrics are showing data:
  - [ ] ECS CPU/Memory metrics
  - [ ] ALB request metrics
  - [ ] SQS queue metrics
  - [ ] Running task counts

### CloudWatch Alarms
- [ ] All alarms are created
- [ ] Alarms are in OK state (when services healthy)
- [ ] Alarm thresholds are appropriate

## Performance Testing

### Load Test (Optional)
```bash
# Send multiple requests
for i in {1..10}; do
  curl -X POST "http://${ALB_DNS}/api/email" \
    -H "Content-Type: application/json" \
    -d "{...}" &
done
wait
```
- [ ] All requests succeed
- [ ] Response times are acceptable
- [ ] No errors in logs
- [ ] All messages processed and stored in S3

## Security Verification

- [ ] API token is stored in SSM (encrypted)
- [ ] Services run in private subnets
- [ ] ALB handles public traffic
- [ ] S3 bucket is private
- [ ] IAM roles follow least privilege
- [ ] Security groups restrict traffic appropriately

## Cleanup Verification (Optional)

After testing, verify cleanup works:
```bash
terraform destroy
```
- [ ] All resources are destroyed
- [ ] No orphaned resources remain
- [ ] Costs are stopped

## Success Criteria

✅ **All checks pass** = System is fully functional and ready for production

### Critical Path
1. Infrastructure deploys successfully
2. Services start and are healthy
3. End-to-end flow works (API → SQS → S3)
4. Monitoring is functional
5. CI/CD pipeline works

### Nice to Have
- Performance is acceptable
- Alarms trigger appropriately
- Logs are clear and useful
- Documentation is complete

## Next Steps After Testing

1. Review any failed checks
2. Fix issues found during testing
3. Re-run failed tests
4. Document any deviations or workarounds
5. Prepare for production deployment (if applicable)

