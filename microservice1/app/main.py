"""
Microservice 1 - REST API
Receives requests from ELB, validates token and payload, publishes to SQS
"""

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel, Field, field_validator
import os
import logging
import boto3
import json
from typing import Optional
from botocore.exceptions import ClientError

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(title="Microservice 1 - REST API", version="1.0.0")

# AWS clients
ssm_client = None
sqs_client = None

# Environment variables
AWS_REGION = os.getenv("AWS_REGION", "eu-west-1")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")
SSM_TOKEN_PARAMETER = os.getenv("SSM_TOKEN_PARAMETER")


def get_ssm_client():
    """Get or create SSM client"""
    global ssm_client
    if ssm_client is None:
        ssm_client = boto3.client("ssm", region_name=AWS_REGION)
    return ssm_client


def get_sqs_client():
    """Get or create SQS client"""
    global sqs_client
    if sqs_client is None:
        sqs_client = boto3.client("sqs", region_name=AWS_REGION)
    return sqs_client


def get_token_from_ssm() -> str:
    """
    Retrieve the API token from SSM Parameter Store
    """
    if not SSM_TOKEN_PARAMETER:
        raise ValueError("SSM_TOKEN_PARAMETER environment variable is not set")
    
    try:
        ssm = get_ssm_client()
        response = ssm.get_parameter(
            Name=SSM_TOKEN_PARAMETER,
            WithDecryption=True
        )
        return response["Parameter"]["Value"]
    except ClientError as e:
        logger.error(f"Error retrieving token from SSM: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to retrieve authentication token"
        )


def validate_token(token: str) -> bool:
    """
    Validate the provided token against SSM Parameter Store
    """
    try:
        expected_token = get_token_from_ssm()
        # Strip whitespace from both tokens for comparison
        token_clean = token.strip()
        expected_clean = expected_token.strip()
        is_valid = token_clean == expected_clean
        
        if not is_valid:
            logger.warning(f"Token mismatch. Expected: '{expected_clean}' (len={len(expected_clean)}), Got: '{token_clean}' (len={len(token_clean)})")
            # Debug: show first and last characters
            if expected_clean and token_clean:
                logger.debug(f"Expected first char: '{expected_clean[0]}', last char: '{expected_clean[-1]}'")
                logger.debug(f"Got first char: '{token_clean[0]}', last char: '{token_clean[-1]}'")
        else:
            logger.info("Token validation successful")
        
        return is_valid
    except Exception as e:
        logger.error(f"Token validation error: {e}")
        return False


class EmailData(BaseModel):
    """Email data model with validation"""
    email_subject: str = Field(..., min_length=1, description="Email subject")
    email_sender: str = Field(..., min_length=1, description="Email sender")
    email_timestream: str = Field(..., min_length=1, description="Email timestamp")
    email_content: str = Field(..., min_length=1, description="Email content")

    @field_validator('email_subject', 'email_sender', 'email_timestream', 'email_content')
    @classmethod
    def validate_not_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Field cannot be empty")
        return v.strip()


class RequestPayload(BaseModel):
    """Request payload model"""
    data: EmailData
    token: str = Field(..., min_length=1, description="Authentication token")


def publish_to_sqs(message_body: dict) -> bool:
    """
    Publish message to SQS queue
    """
    if not SQS_QUEUE_URL:
        logger.error("SQS_QUEUE_URL environment variable is not set")
        raise HTTPException(
            status_code=500,
            detail="SQS queue configuration is missing"
        )
    
    try:
        sqs = get_sqs_client()
        response = sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=json.dumps(message_body)
        )
        logger.info(f"Message sent to SQS. MessageId: {response['MessageId']}")
        return True
    except ClientError as e:
        logger.error(f"Error publishing to SQS: {e}")
        raise HTTPException(
            status_code=500,
            detail="Failed to publish message to queue"
        )


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "microservice1",
        "version": "1.0.0"
    }


@app.get("/debug/token")
async def debug_token():
    """Debug endpoint to check token configuration (remove in production)"""
    try:
        if not SSM_TOKEN_PARAMETER:
            return {
                "error": "SSM_TOKEN_PARAMETER not set",
                "ssm_token_parameter": None
            }
        
        expected_token = get_token_from_ssm()
        return {
            "ssm_token_parameter": SSM_TOKEN_PARAMETER,
            "token_length": len(expected_token),
            "token_stripped_length": len(expected_token.strip()),
            "token_preview": f"{expected_token.strip()[:10]}..." if len(expected_token.strip()) > 10 else expected_token.strip(),
            "has_newline": "\n" in expected_token
        }
    except Exception as e:
        return {
            "error": str(e),
            "ssm_token_parameter": SSM_TOKEN_PARAMETER
        }


@app.post("/api/email")
async def process_email(request: RequestPayload):
    """
    Process email request:
    1. Validate token
    2. Validate payload structure (4 required fields)
    3. Publish to SQS
    """
    try:
        # Step 1: Validate token
        if not validate_token(request.token):
            logger.warning("Invalid token provided")
            raise HTTPException(
                status_code=401,
                detail="Invalid authentication token"
            )
        
        # Step 2: Payload validation is handled by Pydantic
        # The 4 required fields are: email_subject, email_sender, email_timestream, email_content
        # These are already validated by the EmailData model
        
        logger.info(f"Processing email request: {request.data.email_subject}")
        
        # Step 3: Prepare message for SQS
        message_body = {
            "email_subject": request.data.email_subject,
            "email_sender": request.data.email_sender,
            "email_timestream": request.data.email_timestream,
            "email_content": request.data.email_content
        }
        
        # Step 4: Publish to SQS
        publish_to_sqs(message_body)
        
        return {
            "status": "success",
            "message": "Email request processed and published to queue",
            "email_subject": request.data.email_subject
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Unexpected error processing email: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )


@app.on_event("startup")
async def startup_event():
    """Initialize on startup"""
    logger.info("Microservice 1 starting up...")
    logger.info(f"AWS Region: {AWS_REGION}")
    logger.info(f"SQS Queue URL: {SQS_QUEUE_URL}")
    logger.info(f"SSM Token Parameter: {SSM_TOKEN_PARAMETER}")


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)