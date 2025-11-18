#!/bin/bash
# Build and push Microservice 1 Docker image to ECR

set -e

# Get values from Terraform
cd "$(dirname "$0")/../terraform"
ECR_REPO=$(terraform output -raw ecr_repository_microservice1_url 2>/dev/null || echo "")
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "eu-west-1")
cd ..

if [ -z "$ECR_REPO" ]; then
    echo "Error: Could not get ECR repository URL from Terraform"
    echo "Make sure Terraform has been applied and ECR repository exists"
    exit 1
fi

# Extract repository name and account ID
REPO_NAME=$(echo "$ECR_REPO" | cut -d'/' -f2)
ACCOUNT_ID=$(echo "$ECR_REPO" | cut -d'.' -f1)

echo "Building and pushing Microservice 1 to ECR"
echo "Repository: $ECR_REPO"
echo "Region: $AWS_REGION"
echo ""

# Generate image tag (timestamp or git commit)
IMAGE_TAG="${1:-$(date +%Y%m%d-%H%M%S)}"
IMAGE_URI="${ECR_REPO}:${IMAGE_TAG}"
IMAGE_LATEST="${ECR_REPO}:latest"

echo "Image tag: $IMAGE_TAG"
echo ""

# Build Docker image
echo "Step 1: Building Docker image..."
cd microservice1
docker build -t "$IMAGE_URI" -t "$IMAGE_LATEST" .
cd ..

# Login to ECR
echo ""
echo "Step 2: Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | \
    docker login --username AWS --password-stdin \
    "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Push to ECR
echo ""
echo "Step 3: Pushing Docker image to ECR..."
docker push "$IMAGE_URI"
docker push "$IMAGE_LATEST"

echo ""
echo "Successfully pushed:"
echo "   $IMAGE_URI"
echo "   $IMAGE_LATEST"