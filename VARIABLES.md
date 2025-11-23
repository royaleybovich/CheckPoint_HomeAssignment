# Configuration Variables Reference

## Terraform Variables

### Root Level Variables (`terraform/variables.tf`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `project_name` | string | `"RoyalHA"` | Project name used for resource naming |
| `environment` | string | `"dev"` | Environment name (dev, staging, prod) |
| `aws_region` | string | `"eu-west-1"` | AWS region for all resources |
| `api_token_default` | string | `"default-token-change-me"` | Default API token (should be overridden) |

### ECS Module Variables (`terraform/ecs/variables.tf`)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `microservice1_cpu` | number | `256` | CPU units for Microservice 1 (1024 = 1 vCPU) |
| `microservice1_memory` | number | `512` | Memory for Microservice 1 in MB |
| `microservice2_cpu` | number | `256` | CPU units for Microservice 2 (1024 = 1 vCPU) |
| `microservice2_memory` | number | `512` | Memory for Microservice 2 in MB |
| `microservice1_desired_count` | number | `1` | Desired number of Microservice 1 tasks |
| `microservice2_desired_count` | number | `1` | Desired number of Microservice 2 tasks |

## Environment Variables

### Microservice 1

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SQS_QUEUE_URL` | Yes | SQS queue URL for publishing messages | `https://sqs.eu-west-1.amazonaws.com/123456789/RoyalHA-email-queue-dev` |
| `SSM_TOKEN_PARAMETER` | Yes | SSM parameter name for API token | `/RoyalHA/dev/api-token` |
| `AWS_REGION` | No | AWS region (default: `eu-west-1`) | `eu-west-1` |
| `PORT` | No | Application port (default: `8000`) | `8000` |

### Microservice 2

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `SQS_QUEUE_URL` | Yes | SQS queue URL for consuming messages | `https://sqs.eu-west-1.amazonaws.com/123456789/RoyalHA-email-queue-dev` |
| `S3_BUCKET_NAME` | Yes | S3 bucket name for storing emails | `royalha-ms2-uploads-dev` |
| `AWS_REGION` | No | AWS region (default: `eu-west-1`) | `eu-west-1` |
| `SQS_POLL_INTERVAL` | No | Poll interval in seconds (default: `10`) | `10` |
| `SQS_WAIT_TIME` | No | Long polling wait time in seconds (default: `20`) | `20` |
| `MAX_RETRIES` | No | Max retries for S3 upload (default: `3`) | `3` |

## Setting Variables

### Terraform Variables

**Method 1: terraform.tfvars file (Recommended)**
```hcl
# terraform/terraform.tfvars
project_name = "RoyalHA"
environment  = "dev"
aws_region   = "eu-west-1"
api_token_default = "your-secure-token-here"
```

**Method 2: Command line**
```bash
terraform apply -var="project_name=MyProject" -var="environment=prod"
```

**Method 3: Environment variables**
```bash
export TF_VAR_project_name="MyProject"
export TF_VAR_environment="prod"
terraform apply
```

### Environment Variables for Services

Environment variables are set in the ECS task definitions (`terraform/ecs/task_definitions.tf`).

To modify:
1. Edit `terraform/ecs/task_definitions.tf`
2. Update the `environment` block in the container definition
3. Run `terraform apply`

## Resource Naming Convention

Resources follow this naming pattern:
- `{project_name}-{resource-type}-{environment}`
- Example: `RoyalHA-ms1-dev`, `RoyalHA-cluster-dev`

## Default Values

### CPU and Memory

- **Microservice 1**: 256 CPU units (0.25 vCPU), 512 MB memory
- **Microservice 2**: 256 CPU units (0.25 vCPU), 512 MB memory

These are suitable for development. For production, consider:
- **Microservice 1**: 512 CPU units (0.5 vCPU), 1024 MB memory
- **Microservice 2**: 512 CPU units (0.5 vCPU), 1024 MB memory

### Scaling

- **Desired Count**: 1 task per service (default)
- For high availability, set to 2+ tasks per service

### Log Retention

- **CloudWatch Logs**: 7 days (configurable in `terraform/ecs/services.tf`)

## Overriding Defaults

### Example: Production Configuration

Create `terraform/production.tfvars`:
```hcl
project_name = "RoyalHA"
environment  = "prod"
aws_region   = "eu-west-1"
api_token_default = "production-secure-token"

# Override ECS module defaults
microservice1_cpu = 512
microservice1_memory = 1024
microservice1_desired_count = 2

microservice2_cpu = 512
microservice2_memory = 1024
microservice2_desired_count = 2
```

Apply with:
```bash
terraform apply -var-file=production.tfvars
```

## Sensitive Variables

The following variables are marked as sensitive:
- `api_token_default` - API token stored in SSM Parameter Store

Sensitive variables are not displayed in Terraform output.

## Validation

Terraform validates:
- Resource names follow AWS naming conventions
- Required variables are provided
- Variable types match expected types

Run validation:
```bash
terraform validate
```

