# CheckPoint DevOps Home Assignment

A complete microservices architecture on AWS with CI/CD pipeline, monitoring, and automated testing.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   Application   │
                    │  Load Balancer  │
                    └────────┬────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │         Public Subnets                 │
        │  ┌──────────────────────────────────┐  │
        │  │     ALB (Application LB)         │  │
        │  └──────────────────────────────────┘  │
        └────────────────────────────────────────┘
                             │
                             ▼
        ┌────────────────────────────────────────┐
        │        Private Subnets                 │
        │  ┌──────────────────────────────────┐  │
        │  │  ECS Cluster (Fargate)            │  │
        │  │  ┌────────────┐  ┌──────────────┐ │  │
        │  │  │ Microservice│  │ Microservice │ │  │
        │  │  │     1       │  │     2        │ │  │
        │  │  │  (REST API) │  │ (SQS Consumer)│ │  │
        │  │  └──────┬─────┘  └──────┬───────┘ │  │
        │  └─────────┼─────────────────┼────────┘  │
        └────────────┼─────────────────┼────────────┘
                     │                 │
        ┌────────────▼─────┐  ┌────────▼──────────┐
        │   SQS Queue      │  │   S3 Bucket       │
        │  (Email Queue)   │  │  (Email Storage)  │
        └──────────────────┘  └───────────────────┘
                     │
        ┌────────────▼─────┐
        │  SSM Parameter   │
        │   (API Token)    │
        └──────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         CI/CD Pipeline                           │
│                                                                   │
│  GitHub → Jenkins → Build → Push to ECR → Deploy to ECS         │
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Checkout │→ │   Test   │→ │   Build  │→ │  Deploy  │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### Microservice 1 - REST API
- **Technology**: Python/FastAPI
- **Function**: Receives HTTP requests, validates token and payload, publishes to SQS
- **Endpoints**:
  - `POST /api/email` - Process email requests
  - `GET /health` - Health check
  - `GET /debug/token` - Debug token configuration

### Microservice 2 - SQS Consumer
- **Technology**: Python
- **Function**: Polls SQS queue, processes messages, uploads to S3
- **Behavior**: Long polling (20s), retry logic, graceful shutdown

### Infrastructure
- **ECS Fargate**: Container orchestration
- **Application Load Balancer**: Routes traffic to Microservice 1
- **SQS**: Message queue with Dead Letter Queue
- **S3**: Storage for processed emails
- **SSM Parameter Store**: Secure token storage
- **CloudWatch**: Logging, metrics, dashboards, alarms

### CI/CD
- **Jenkins**: CI/CD pipeline
- **ECR**: Docker image registry
- **Automated Testing**: Unit tests run before deployment

## Prerequisites

- AWS Account with appropriate permissions
- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- Docker (for local testing)
- Python 3.10+ (for local development)
- Jenkins (for CI/CD, see `jenkins/` directory)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/royaleybovich/CheckPoint_HomeAssignment.git
cd CheckPoint_HomeAssignment
```

### 2. Configure Terraform Variables

Create `terraform/terraform.tfvars`:

```hcl
project_name = "RoyalHA"
environment  = "dev"
aws_region   = "eu-west-1"
api_token_default = "your-secure-token-here"
```

### 3. Deploy Infrastructure

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 4. Get Outputs

```bash
terraform output
```

Key outputs:
- `alb_dns_name` - ALB endpoint for Microservice 1
- `ecr_repository_microservice1_url` - ECR repository URL
- `ecr_repository_microservice2_url` - ECR repository URL
- `cloudwatch_dashboard_url` - Monitoring dashboard URL

### 5. Set Up Jenkins

See `jenkins/README.md` for detailed Jenkins setup instructions.

Quick setup:
```bash
cd jenkins
./setup_jenkins.sh
```

### 6. Build and Push Docker Images

**Option A: Using Jenkins (Recommended)**
1. Create Jenkins jobs pointing to `jenkins/Jenkinsfile.microservice1` and `jenkins/Jenkinsfile.microservice2`
2. Run the pipelines

**Option B: Manual Build**
```bash
# Build and push Microservice 1
cd scripts
./build_and_push_ms1.sh

# Build and push Microservice 2
./build_and_push_ms2.sh
```

### 7. Deploy Services

**Option A: Using Jenkins**
- The pipeline automatically deploys after building

**Option B: Manual Deployment**
```bash
# Deploy Microservice 1
./scripts/deploy_ms1.sh

# Deploy Microservice 2
./scripts/deploy_ms2.sh
```

## Testing

### Unit Tests

```bash
# Microservice 1
cd microservice1
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v

# Microservice 2
cd microservice2
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
pytest tests/ -v
```

### Integration Testing

1. Get the ALB DNS name:
```bash
terraform output alb_dns_name
```

2. Get the API token:
```bash
aws ssm get-parameter --name "/RoyalHA/dev/api-token" --with-decryption --query "Parameter.Value" --output text | tr -d '\n'
```

3. Test Microservice 1:
```bash
ALB_DNS=$(terraform output -raw alb_dns_name)
TOKEN=$(aws ssm get-parameter --name "/RoyalHA/dev/api-token" --with-decryption --query "Parameter.Value" --output text | tr -d '\n')

curl -X POST "http://${ALB_DNS}/api/email" \
  -H "Content-Type: application/json" \
  -d "{
    \"token\": \"${TOKEN}\",
    \"data\": {
      \"email_subject\": \"Test Email\",
      \"email_sender\": \"test@example.com\",
      \"email_timestream\": \"$(date +%s)\",
      \"email_content\": \"This is a test email\"
    }
  }"
```

4. Check S3 for uploaded files:
```bash
BUCKET=$(terraform output -raw s3_bucket_name)
aws s3 ls s3://${BUCKET}/emails/ --recursive
```

## Configuration

### Terraform Variables

See `terraform/variables.tf` for all available variables.

**Required Variables:**
- `project_name` - Project name for resource naming (default: "RoyalHA")
- `environment` - Environment name (default: "dev")
- `aws_region` - AWS region (default: "eu-west-1")
- `api_token_default` - API token (should be overridden via tfvars)

**Optional Variables:**
- `microservice1_cpu` - CPU units for MS1 (default: 256)
- `microservice1_memory` - Memory for MS1 in MB (default: 512)
- `microservice2_cpu` - CPU units for MS2 (default: 256)
- `microservice2_memory` - Memory for MS2 in MB (default: 512)
- `microservice1_desired_count` - Desired task count for MS1 (default: 1)
- `microservice2_desired_count` - Desired task count for MS2 (default: 1)

### Environment Variables

**Microservice 1:**
- `SQS_QUEUE_URL` - SQS queue URL
- `SSM_TOKEN_PARAMETER` - SSM parameter name for API token
- `AWS_REGION` - AWS region

**Microservice 2:**
- `SQS_QUEUE_URL` - SQS queue URL
- `S3_BUCKET_NAME` - S3 bucket name
- `AWS_REGION` - AWS region
- `SQS_POLL_INTERVAL` - Poll interval in seconds (default: 10)
- `SQS_WAIT_TIME` - Long polling wait time (default: 20)
- `MAX_RETRIES` - Max retries for S3 upload (default: 3)

## Monitoring

### CloudWatch Dashboard

Access the dashboard:
```bash
terraform output cloudwatch_dashboard_url
```

Or in AWS Console: CloudWatch → Dashboards → `{project_name}-{environment}-dashboard`

### CloudWatch Logs

View logs:
```bash
# Microservice 1
aws logs tail /ecs/RoyalHA-ms1-dev --follow

# Microservice 2
aws logs tail /ecs/RoyalHA-ms2-dev --follow
```

### CloudWatch Alarms

Configured alarms:
- High CPU/Memory for both services
- Service down detection
- ALB 5xx errors
- SQS queue depth

See `MONITORING.md` for detailed monitoring documentation.

## Project Structure

```
CheckPoint_HomeAssignment/
├── microservice1/          # REST API service
│   ├── app/
│   │   └── main.py
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
├── microservice2/          # SQS Consumer service
│   ├── app/
│   │   └── main.py
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
├── terraform/              # Infrastructure as Code
│   ├── networking/         # VPC, subnets, NAT gateway
│   ├── storage/           # S3, SQS, SSM
│   ├── iam/               # IAM roles and policies
│   ├── ecs/               # ECS cluster, services, ALB
│   └── main.tf
├── jenkins/               # CI/CD pipelines
│   ├── Jenkinsfile.microservice1
│   ├── Jenkinsfile.microservice2
│   └── README.md
├── scripts/               # Deployment scripts
│   ├── deploy_ms1.sh
│   └── deploy_ms2.sh
└── README.md
```

## Troubleshooting

### Services Not Starting

1. Check ECS service status:
```bash
aws ecs describe-services \
  --cluster RoyalHA-cluster-dev \
  --services RoyalHA-ms1-dev
```

2. Check task logs:
```bash
aws logs tail /ecs/RoyalHA-ms1-dev --follow
```

3. Verify task definition:
```bash
aws ecs describe-task-definition \
  --task-definition RoyalHA-ms1-dev
```

### ALB Health Check Failing

1. Check target group health:
```bash
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

2. Verify security groups allow traffic
3. Check service logs for errors

### SQS Messages Not Processing

1. Check queue depth:
```bash
aws sqs get-queue-attributes \
  --queue-url <queue-url> \
  --attribute-names ApproximateNumberOfMessages
```

2. Check Microservice 2 logs:
```bash
aws logs tail /ecs/RoyalHA-ms2-dev --follow
```

3. Verify IAM permissions for SQS and S3

### Jenkins Pipeline Failures

1. Check Jenkins console output
2. Verify AWS credentials in Jenkins
3. Check Docker daemon is running
4. Verify ECR repositories exist

See `TROUBLESHOOTING.md` for more detailed troubleshooting.

## Security Considerations

- API token stored in SSM Parameter Store (encrypted)
- IAM roles follow least privilege principle
- Services run in private subnets
- ALB handles public traffic
- S3 bucket is private by default
- CloudWatch logs retention: 7 days

## Cost Optimization

- Fargate spot instances (if available)
- S3 lifecycle policies for old data
- CloudWatch log retention: 7 days
- ECR image cleanup (manual or automated)
- ALB idle timeout configuration

## Cleanup

To destroy all resources:

```bash
cd terraform
terraform destroy
```

**Warning**: This will delete all resources including S3 bucket data!

## Additional Documentation

- `MONITORING.md` - Monitoring setup and usage
- `PROJECT_PLAN.md` - Project phases and implementation plan
- `jenkins/README.md` - Jenkins setup guide

## License

This is a home assignment project for Check Point DevOps role.
