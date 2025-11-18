"""
Microservice 1 - REST API
Receives requests from ELB, validates token and payload, publishes to SQS
"""

from fastapi import FastAPI, HTTPException, Request
from pydantic import BaseModel
import os
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Microservice 1 - REST API", version="0.1.0")


class EmailData(BaseModel):
    """Email data model"""
    email_subject: str
    email_sender: str
    email_timestream: str
    email_content: str


class RequestPayload(BaseModel):
    """Request payload model"""
    data: EmailData
    token: str

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "microservice1"}


@app.post("/api/email")
async def process_email(request: RequestPayload):
    """
    Process email request:
    1. Validate token
    2. Validate payload structure
    3. Publish to SQS
    """
    # TODO: Implement token validation (SSM Parameter Store), payload validation and SQS publishing

    logger.info(f"Received request: {request.data.email_subject}")
    
    return {
        "status": "success",
        "message": "Request received (implementation pending)"
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)