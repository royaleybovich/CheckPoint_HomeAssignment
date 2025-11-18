# Jenkins CI/CD Configuration

This directory contains Jenkins pipeline configurations for building and pushing Docker images to ECR.

## Files

- `Jenkinsfile.microservice1` - Pipeline for Microservice 1 (REST API)
- `Jenkinsfile.microservice2` - Pipeline for Microservice 2 (SQS Consumer)

## Prerequisites

1. **Jenkins Server** with the following plugins:
   - Docker Pipeline plugin
   - AWS CLI installed on Jenkins agents
   - Docker installed on Jenkins agents

2. **AWS Credentials** configured in Jenkins:
   - AWS Access Key ID and Secret Access Key
   - Credentials ID: `aws-account-id` (should contain AWS Account ID as a string credential)
   - Or use IAM role if Jenkins is running on EC2

3. **ECR Repositories** created (via Terraform):
   - `royalha-microservice1`
   - `royalha-microservice2`

## Jenkins Setup

### Step 1: Configure AWS Credentials

1. Go to Jenkins → Manage Jenkins → Credentials
2. Add AWS credentials:
   - **Kind**: Secret text
   - **ID**: `aws-account-id`
   - **Secret**: Your AWS Account ID (e.g., `371670420772`)

3. Add AWS Access Keys (if not using IAM role):
   - **Kind**: AWS Credentials
   - **ID**: `aws-credentials`
   - **Access Key ID**: Your AWS Access Key
   - **Secret Access Key**: Your AWS Secret Key

### Step 2: Create Jenkins Jobs

#### For Microservice 1:

1. Create a new Pipeline job
2. Name: `microservice1-build-push`
3. Pipeline definition:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your Git repository URL
   - **Script Path**: `jenkins/Jenkinsfile.microservice1`
   - **Branch**: `*/main` (or your main branch)

#### For Microservice 2:

1. Create a new Pipeline job
2. Name: `microservice2-build-push`
3. Pipeline definition:
   - **Definition**: Pipeline script from SCM
   - **SCM**: Git
   - **Repository URL**: Your Git repository URL
   - **Script Path**: `jenkins/Jenkinsfile.microservice2`
   - **Branch**: `*/main` (or your main branch)

### Step 3: Configure Build Triggers (Optional)

You can configure:
- **Poll SCM**: Check for changes periodically (e.g., `H/5 * * * *` - every 5 minutes)
- **GitHub webhook**: Trigger on push events
- **Manual**: Build on demand

## Pipeline Stages

Each pipeline includes:

1. **Checkout** - Get source code from repository
2. **Build Docker Image** - Build Docker image with build number tag
3. **Login to ECR** - Authenticate with AWS ECR
4. **Push to ECR** - Push image to ECR repository (both build number and latest tags)

## Environment Variables

The pipelines use these environment variables:
- `AWS_REGION`: `eu-west-1`
- `AWS_ACCOUNT_ID`: From Jenkins credentials
- `ECR_REPOSITORY`: Repository name
- `IMAGE_TAG`: Jenkins build number
- `DOCKER_IMAGE`: Full ECR image URL

## Manual Build Scripts

For local testing, see:
- `../scripts/build_and_push_ms1.sh`
- `../scripts/build_and_push_ms2.sh`

## Troubleshooting

### Error: "aws-account-id credentials not found"
- Make sure you've created the credentials in Jenkins with ID `aws-account-id`
- The value should be your AWS Account ID (12-digit number)

### Error: "Cannot connect to Docker daemon"
- Ensure Docker is installed and running on Jenkins agent
- Jenkins user needs permission to use Docker

### Error: "ECR login failed"
- Verify AWS credentials are correct
- Check AWS region matches (`eu-west-1`)
- Ensure ECR repositories exist (created via Terraform)

### Error: "Repository does not exist"
- Run Terraform to create ECR repositories:
  ```bash
  cd terraform
  terraform apply
  ```

## Next Steps

After images are pushed to ECR:
1. Update ECS task definitions with new image tags
2. Deploy to ECS (Phase 7)