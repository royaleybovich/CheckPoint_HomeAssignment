#!/bin/bash
# Script to deploy Microservice 2 to ECS

set -e

# Configuration
PROJECT_NAME="${PROJECT_NAME:-RoyalHA}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
AWS_REGION="${AWS_REGION:-eu-west-1}"
CLUSTER_NAME="${CLUSTER_NAME:-${PROJECT_NAME}-cluster-${ENVIRONMENT}}"
SERVICE_NAME="${SERVICE_NAME:-${PROJECT_NAME}-ms2-${ENVIRONMENT}}"
TASK_DEFINITION_FAMILY="${TASK_DEFINITION_FAMILY:-${PROJECT_NAME}-ms2-${ENVIRONMENT}}"
ECR_REPOSITORY="${ECR_REPOSITORY:-${PROJECT_NAME}-microservice2}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Get AWS Account ID
ACCOUNT_ID="${AWS_ACCOUNT_ID:-371670420772}"
IMAGE_URI="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPOSITORY}:${IMAGE_TAG}"

echo "=========================================="
echo "Deploying Microservice 2 to ECS"
echo "=========================================="
echo "Cluster: ${CLUSTER_NAME}"
echo "Service: ${SERVICE_NAME}"
echo "Image: ${IMAGE_URI}"
echo ""

# Get current task definition
echo "Getting current task definition..."
TASK_DEF=$(aws ecs describe-task-definition \
    --task-definition "${TASK_DEFINITION_FAMILY}" \
    --region "${AWS_REGION}" \
    --query 'taskDefinition' \
    --output json)

if [ -z "$TASK_DEF" ] || [ "$TASK_DEF" == "null" ]; then
    echo "Error: Task definition not found: ${TASK_DEFINITION_FAMILY}"
    exit 1
fi

# Update container image in task definition
echo "Updating task definition with new image..."
NEW_TASK_DEF=$(echo "$TASK_DEF" | jq --arg IMAGE "$IMAGE_URI" '.containerDefinitions[0].image = $IMAGE')

# Remove fields that can't be in register-task-definition
NEW_TASK_DEF=$(echo "$NEW_TASK_DEF" | jq 'del(.taskDefinitionArn, .revision, .status, .requiresAttributes, .compatibilities, .registeredAt, .registeredBy)')

# Register new task definition
echo "Registering new task definition..."
NEW_TASK_DEF_ARN=$(echo "$NEW_TASK_DEF" | aws ecs register-task-definition \
    --cli-input-json file:///dev/stdin \
    --region "${AWS_REGION}" \
    --query 'taskDefinition.taskDefinitionArn' \
    --output text)

echo "New task definition: ${NEW_TASK_DEF_ARN}"

# Update service with new task definition
echo "Updating ECS service..."
aws ecs update-service \
    --cluster "${CLUSTER_NAME}" \
    --service "${SERVICE_NAME}" \
    --task-definition "${NEW_TASK_DEF_ARN}" \
    --region "${AWS_REGION}" \
    --output json > /dev/null

echo ""
echo "✅ Deployment initiated successfully!"
echo ""
echo "Waiting for service to stabilize..."
aws ecs wait services-stable \
    --cluster "${CLUSTER_NAME}" \
    --services "${SERVICE_NAME}" \
    --region "${AWS_REGION}"

echo ""
echo "✅ Deployment completed successfully!"
echo "Service is now running with image: ${IMAGE_URI}"

