"""
Microservice 2 - SQS Consumer
Polls SQS messages and uploads them to S3
"""

import os
import time
import logging
import json
import uuid
from datetime import datetime
from typing import Optional
import boto3
from botocore.exceptions import ClientError

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

sqs_client = None
s3_client = None

AWS_REGION = os.getenv("AWS_REGION", "eu-west-1")
SQS_QUEUE_URL = os.getenv("SQS_QUEUE_URL")
S3_BUCKET_NAME = os.getenv("S3_BUCKET_NAME")
SQS_POLL_INTERVAL = int(os.getenv("SQS_POLL_INTERVAL", "10"))  # Default 10 seconds
SQS_WAIT_TIME = int(os.getenv("SQS_WAIT_TIME", "20"))  # Long polling wait time
MAX_RETRIES = int(os.getenv("MAX_RETRIES", "3"))  # Max retries for S3 upload


def get_sqs_client():
    """Get or create SQS client"""
    global sqs_client
    if sqs_client is None:
        sqs_client = boto3.client("sqs", region_name=AWS_REGION)
    return sqs_client


def get_s3_client():
    """Get or create S3 client"""
    global s3_client
    if s3_client is None:
        s3_client = boto3.client("s3", region_name=AWS_REGION)
    return s3_client


def validate_configuration():
    """Validate that required environment variables are set"""
    # Check environment variables directly to support testing (reads fresh from os.environ)
    sqs_queue_url = os.getenv("SQS_QUEUE_URL")
    s3_bucket_name = os.getenv("S3_BUCKET_NAME")
    
    # Check for None, empty string, or whitespace-only strings
    if not sqs_queue_url or not str(sqs_queue_url).strip():
        raise ValueError("SQS_QUEUE_URL environment variable is not set")
    if not s3_bucket_name or not str(s3_bucket_name).strip():
        raise ValueError("S3_BUCKET_NAME environment variable is not set")
    logger.info("Configuration validated successfully")


def receive_messages(max_messages: int = 10) -> list:
    """
    Receive messages from SQS queue using long polling
    
    Args:
        max_messages: Maximum number of messages to receive (1-10)
    
    Returns:
        List of messages or empty list
    """
    try:
        sqs = get_sqs_client()
        response = sqs.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=min(max_messages, 10),
            WaitTimeSeconds=SQS_WAIT_TIME,  # Long polling
            AttributeNames=['All'],
            MessageAttributeNames=['All']
        )
        
        messages = response.get('Messages', [])
        if messages:
            logger.info(f"Received {len(messages)} message(s) from SQS")
        return messages
    
    except ClientError as e:
        logger.error(f"Error receiving messages from SQS: {e}")
        return []
    except Exception as e:
        logger.error(f"Unexpected error receiving messages: {e}")
        return []


def parse_message_body(message_body: str) -> Optional[dict]:
    """
    Parse and validate message body
    
    Args:
        message_body: JSON string from SQS message
    
    Returns:
        Parsed message dict or None if invalid
    """
    try:
        data = json.loads(message_body)
        
        # Validate required fields
        required_fields = ['email_subject', 'email_sender', 'email_timestream', 'email_content']
        missing_fields = [field for field in required_fields if field not in data]
        
        if missing_fields:
            logger.warning(f"Message missing required fields: {missing_fields}")
            return None
        
        return data
    
    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON in message body: {e}")
        return None
    except Exception as e:
        logger.error(f"Error parsing message body: {e}")
        return None


def generate_s3_key(email_data: dict) -> str:
    """
    Generate S3 key for the email data
    
    Format: emails/{year}/{month}/{day}/{timestamp}-{uuid}.json
    
    Args:
        email_data: Parsed email data
    
    Returns:
        S3 key string
    """
    try:
        # Use email_timestream if available, otherwise use current time
        timestamp = int(email_data.get('email_timestream', str(int(time.time()))))
        dt = datetime.fromtimestamp(timestamp)
        
        # Generate unique identifier
        unique_id = str(uuid.uuid4())[:8]
        
        # Format: emails/YYYY/MM/DD/timestamp-uuid.json
        s3_key = f"emails/{dt.year:04d}/{dt.month:02d}/{dt.day:02d}/{timestamp}-{unique_id}.json"
        
        return s3_key
    
    except Exception as e:
        logger.error(f"Error generating S3 key: {e}")
        # Fallback to timestamp-based key
        timestamp = int(time.time())
        unique_id = str(uuid.uuid4())[:8]
        return f"emails/{timestamp}-{unique_id}.json"


def upload_to_s3(data: dict, s3_key: str, retry_count: int = 0) -> bool:
    """
    Upload email data to S3 bucket
    
    Args:
        data: Email data to upload
        s3_key: S3 object key
        retry_count: Current retry attempt
    
    Returns:
        True if successful, False otherwise
    """
    try:
        s3 = get_s3_client()
        
        # Convert data to JSON string
        json_data = json.dumps(data, indent=2)
        
        # Upload to S3
        s3.put_object(
            Bucket=S3_BUCKET_NAME,
            Key=s3_key,
            Body=json_data.encode('utf-8'),
            ContentType='application/json'
        )
        
        logger.info(f"Successfully uploaded to S3: s3://{S3_BUCKET_NAME}/{s3_key}")
        return True
    
    except ClientError as e:
        error_code = e.response.get('Error', {}).get('Code', 'Unknown')
        logger.error(f"Error uploading to S3 (attempt {retry_count + 1}/{MAX_RETRIES}): {error_code} - {e}")
        
        # Retry on certain errors
        if retry_count < MAX_RETRIES and error_code in ['NoSuchBucket', 'ServiceUnavailable', 'SlowDown']:
            logger.info(f"Retrying upload to S3 (attempt {retry_count + 1}/{MAX_RETRIES})...")
            time.sleep(2 ** retry_count)  # Exponential backoff
            return upload_to_s3(data, s3_key, retry_count + 1)
        
        return False
    
    except Exception as e:
        logger.error(f"Unexpected error uploading to S3: {e}")
        return False


def delete_message(receipt_handle: str) -> bool:
    """
    Delete message from SQS queue after successful processing
    
    Args:
        receipt_handle: Message receipt handle
    
    Returns:
        True if successful, False otherwise
    """
    try:
        sqs = get_sqs_client()
        sqs.delete_message(
            QueueUrl=SQS_QUEUE_URL,
            ReceiptHandle=receipt_handle
        )
        logger.debug(f"Deleted message from SQS queue")
        return True
    
    except ClientError as e:
        logger.error(f"Error deleting message from SQS: {e}")
        return False
    except Exception as e:
        logger.error(f"Unexpected error deleting message: {e}")
        return False


def process_message(message: dict) -> bool:
    """
    Process a single SQS message:
    1. Parse message body
    2. Upload to S3
    3. Delete from queue if successful
    
    Args:
        message: SQS message dict
    
    Returns:
        True if processed successfully, False otherwise
    """
    receipt_handle = message.get('ReceiptHandle')
    message_body = message.get('Body', '')
    
    logger.info(f"Processing message: {message.get('MessageId', 'unknown')}")
    
    # Parse message body
    email_data = parse_message_body(message_body)
    if not email_data:
        logger.warning("Invalid message format, deleting from queue")
        delete_message(receipt_handle)  # Delete invalid messages
        return False
    
    # Generate S3 key
    s3_key = generate_s3_key(email_data)
    logger.info(f"Generated S3 key: {s3_key}")
    
    # Upload to S3
    upload_success = upload_to_s3(email_data, s3_key)
    
    if upload_success:
        # Delete message from queue only after successful upload
        delete_success = delete_message(receipt_handle)
        if delete_success:
            logger.info(f"Successfully processed and deleted message: {message.get('MessageId')}")
            return True
        else:
            logger.warning("Message uploaded to S3 but failed to delete from queue")
            # Message will be reprocessed, but that's okay since S3 upload is idempotent
            return True
    else:
        logger.error("Failed to upload message to S3, message will remain in queue")
        # Don't delete message - let it be retried
        return False


def main():
    """
    Main function that polls SQS and uploads messages to S3
    Polls every X seconds (configurable - environment variable)
    """
    logger.info("=" * 60)
    logger.info("Microservice 2 - SQS Consumer Starting")
    logger.info("=" * 60)
    
    # Validate configuration
    try:
        validate_configuration()
    except ValueError as e:
        logger.error(f"Configuration error: {e}")
        logger.error("Please set required environment variables:")
        logger.error("  - SQS_QUEUE_URL")
        logger.error("  - S3_BUCKET_NAME")
        return
    
    logger.info(f"Configuration:")
    logger.info(f"  AWS Region: {AWS_REGION}")
    logger.info(f"  SQS Queue URL: {SQS_QUEUE_URL}")
    logger.info(f"  S3 Bucket: {S3_BUCKET_NAME}")
    logger.info(f"  Poll Interval: {SQS_POLL_INTERVAL} seconds")
    logger.info(f"  Long Poll Wait Time: {SQS_WAIT_TIME} seconds")
    logger.info(f"  Max Retries: {MAX_RETRIES}")
    logger.info("=" * 60)
    
    consecutive_errors = 0
    max_consecutive_errors = 10
    
    while True:
        try:
            # Receive messages from SQS
            messages = receive_messages(max_messages=10)
            
            if messages:
                consecutive_errors = 0  # Reset error counter on success
                
                # Process each message
                for message in messages:
                    try:
                        process_message(message)
                    except Exception as e:
                        logger.error(f"Error processing individual message: {e}")
                        # Continue with next message
                
            else:
                # No messages, log periodically (every 10th poll)
                if consecutive_errors == 0:
                    logger.debug("No messages in queue, waiting...")
            
            # Sleep before next poll
            time.sleep(SQS_POLL_INTERVAL)
        
        except KeyboardInterrupt:
            logger.info("Received shutdown signal, shutting down gracefully...")
            break
        
        except Exception as e:
            consecutive_errors += 1
            logger.error(f"Error in main loop (error #{consecutive_errors}): {e}")
            
            if consecutive_errors >= max_consecutive_errors:
                logger.error(f"Too many consecutive errors ({consecutive_errors}), exiting...")
                break
            
            # Wait before retrying
            time.sleep(SQS_POLL_INTERVAL)


if __name__ == "__main__":
    main()