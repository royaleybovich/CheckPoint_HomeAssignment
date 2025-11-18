"""
Microservice 2 - SQS Consumer
Polls SQS messages and uploads them to S3
"""

import os
import time
import logging
import json
from datetime import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    """
    Main function that polls SQS and uploads messages to S3
    Polls every X seconds (configurable - environment variable)
    """
    # TODO: Implement SQS polling, S3 upload logic and error handling and retry logic
    
    poll_interval = int(os.getenv("SQS_POLL_INTERVAL", "10"))  # Default 10 seconds
    
    logger.info(f"Starting SQS consumer. Poll interval: {poll_interval} seconds")
    
    while True:
        try:
            # TODO: Poll SQS queue,  Process messages and upload to S3
            
            logger.info("Polling SQS (implementation pending)...")
            time.sleep(poll_interval)
            
        except KeyboardInterrupt:
            logger.info("Shutting down...")
            break
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(poll_interval)


if __name__ == "__main__":
    main()

