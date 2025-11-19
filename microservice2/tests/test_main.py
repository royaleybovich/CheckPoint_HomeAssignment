"""
Unit tests for Microservice 2
"""
import pytest
import os
import json
import time
from unittest.mock import Mock, patch, MagicMock
from botocore.exceptions import ClientError

# Set test environment variables before importing the app
os.environ["SQS_QUEUE_URL"] = "https://sqs.eu-west-1.amazonaws.com/123456789/test-queue"
os.environ["S3_BUCKET_NAME"] = "test-bucket"
os.environ["AWS_REGION"] = "eu-west-1"
os.environ["SQS_POLL_INTERVAL"] = "1"
os.environ["SQS_WAIT_TIME"] = "1"
os.environ["MAX_RETRIES"] = "3"

from app.main import (
    validate_configuration,
    receive_messages,
    parse_message_body,
    generate_s3_key,
    upload_to_s3,
    delete_message,
    process_message
)


class TestConfiguration:
    """Test configuration validation"""
    
    def test_validate_configuration_success(self):
        """Test successful configuration validation"""
        # Environment variables are set in setup
        try:
            validate_configuration()
            assert True
        except ValueError:
            pytest.fail("validate_configuration raised ValueError unexpectedly")
    
    def test_validate_configuration_missing_sqs(self):
        """Test configuration validation with missing SQS_QUEUE_URL"""
        with patch.dict(os.environ, {"SQS_QUEUE_URL": ""}):
            with pytest.raises(ValueError, match="SQS_QUEUE_URL"):
                validate_configuration()
    
    def test_validate_configuration_missing_s3(self):
        """Test configuration validation with missing S3_BUCKET_NAME"""
        with patch.dict(os.environ, {"S3_BUCKET_NAME": ""}):
            with pytest.raises(ValueError, match="S3_BUCKET_NAME"):
                validate_configuration()


class TestSQSPolling:
    """Test SQS message receiving"""
    
    @patch('app.main.get_sqs_client')
    def test_receive_messages_success(self, mock_sqs_client):
        """Test successful message receiving"""
        mock_sqs = Mock()
        mock_sqs.receive_message.return_value = {
            'Messages': [
                {
                    'MessageId': 'msg-1',
                    'Body': json.dumps({
                        'email_subject': 'Test',
                        'email_sender': 'test@example.com',
                        'email_timestream': '1234567890',
                        'email_content': 'Test content'
                    }),
                    'ReceiptHandle': 'receipt-handle-1'
                }
            ]
        }
        mock_sqs_client.return_value = mock_sqs
        
        messages = receive_messages(max_messages=10)
        assert len(messages) == 1
        assert messages[0]['MessageId'] == 'msg-1'
    
    @patch('app.main.get_sqs_client')
    def test_receive_messages_empty_queue(self, mock_sqs_client):
        """Test receiving messages from empty queue"""
        mock_sqs = Mock()
        mock_sqs.receive_message.return_value = {}
        mock_sqs_client.return_value = mock_sqs
        
        messages = receive_messages()
        assert messages == []
    
    @patch('app.main.get_sqs_client')
    def test_receive_messages_error(self, mock_sqs_client):
        """Test error handling when receiving messages"""
        mock_sqs = Mock()
        mock_sqs.receive_message.side_effect = ClientError(
            {'Error': {'Code': 'AWS.SimpleQueueService.NonExistentQueue'}},
            'ReceiveMessage'
        )
        mock_sqs_client.return_value = mock_sqs
        
        messages = receive_messages()
        assert messages == []


class TestMessageParsing:
    """Test message body parsing"""
    
    def test_parse_message_body_valid(self):
        """Test parsing valid message body"""
        message_body = json.dumps({
            'email_subject': 'Test Subject',
            'email_sender': 'sender@example.com',
            'email_timestream': '1234567890',
            'email_content': 'Test content'
        })
        
        result = parse_message_body(message_body)
        assert result is not None
        assert result['email_subject'] == 'Test Subject'
        assert result['email_sender'] == 'sender@example.com'
    
    def test_parse_message_body_invalid_json(self):
        """Test parsing invalid JSON"""
        message_body = "{ invalid json }"
        
        result = parse_message_body(message_body)
        assert result is None
    
    def test_parse_message_body_missing_fields(self):
        """Test parsing message with missing required fields"""
        message_body = json.dumps({
            'email_subject': 'Test Subject',
            'email_sender': 'sender@example.com'
            # Missing email_timestream and email_content
        })
        
        result = parse_message_body(message_body)
        assert result is None
    
    def test_parse_message_body_empty(self):
        """Test parsing empty message body"""
        result = parse_message_body("")
        assert result is None


class TestS3KeyGeneration:
    """Test S3 key generation"""
    
    def test_generate_s3_key_with_timestream(self):
        """Test generating S3 key with timestream"""
        email_data = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1704067200',  # 2024-01-01 00:00:00 UTC
            'email_content': 'Test content'
        }
        
        s3_key = generate_s3_key(email_data)
        assert s3_key.startswith('emails/2024/01/01/')
        assert s3_key.endswith('.json')
    
    def test_generate_s3_key_without_timestream(self):
        """Test generating S3 key without timestream (uses current time)"""
        email_data = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_content': 'Test content'
        }
        
        s3_key = generate_s3_key(email_data)
        assert s3_key.startswith('emails/')
        assert s3_key.endswith('.json')
    
    def test_generate_s3_key_format(self):
        """Test S3 key format is correct"""
        email_data = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1704067200',
            'email_content': 'Test content'
        }
        
        s3_key = generate_s3_key(email_data)
        parts = s3_key.split('/')
        assert len(parts) == 5  # emails/YYYY/MM/DD/file.json
        assert parts[0] == 'emails'
        assert parts[1] == '2024'
        assert parts[2] == '01'
        assert parts[3] == '01'


class TestS3Upload:
    """Test S3 upload functionality"""
    
    @patch('app.main.get_s3_client')
    def test_upload_to_s3_success(self, mock_s3_client):
        """Test successful S3 upload"""
        mock_s3 = Mock()
        mock_s3.put_object.return_value = {'ETag': 'test-etag'}
        mock_s3_client.return_value = mock_s3
        
        email_data = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1234567890',
            'email_content': 'Test content'
        }
        
        result = upload_to_s3(email_data, 'emails/test-key.json')
        assert result is True
        mock_s3.put_object.assert_called_once()
    
    @patch('app.main.get_s3_client')
    def test_upload_to_s3_retry_on_error(self, mock_s3_client):
        """Test S3 upload retry on retryable error"""
        mock_s3 = Mock()
        # First call fails, second succeeds
        mock_s3.put_object.side_effect = [
            ClientError({'Error': {'Code': 'ServiceUnavailable'}}, 'PutObject'),
            {'ETag': 'test-etag'}
        ]
        mock_s3_client.return_value = mock_s3
        
        email_data = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1234567890',
            'email_content': 'Test content'
        }
        
        with patch('time.sleep'):  # Skip sleep in tests
            result = upload_to_s3(email_data, 'emails/test-key.json', retry_count=0)
            assert result is True
            assert mock_s3.put_object.call_count == 2
    
    @patch('app.main.get_s3_client')
    def test_upload_to_s3_non_retryable_error(self, mock_s3_client):
        """Test S3 upload fails on non-retryable error"""
        mock_s3 = Mock()
        mock_s3.put_object.side_effect = ClientError(
            {'Error': {'Code': 'AccessDenied'}},
            'PutObject'
        )
        mock_s3_client.return_value = mock_s3
        
        email_data = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1234567890',
            'email_content': 'Test content'
        }
        
        result = upload_to_s3(email_data, 'emails/test-key.json')
        assert result is False


class TestMessageDeletion:
    """Test SQS message deletion"""
    
    @patch('app.main.get_sqs_client')
    def test_delete_message_success(self, mock_sqs_client):
        """Test successful message deletion"""
        mock_sqs = Mock()
        mock_sqs.delete_message.return_value = {}
        mock_sqs_client.return_value = mock_sqs
        
        result = delete_message('receipt-handle-123')
        assert result is True
        mock_sqs.delete_message.assert_called_once()
    
    @patch('app.main.get_sqs_client')
    def test_delete_message_error(self, mock_sqs_client):
        """Test message deletion error handling"""
        mock_sqs = Mock()
        mock_sqs.delete_message.side_effect = ClientError(
            {'Error': {'Code': 'InvalidReceiptHandle'}},
            'DeleteMessage'
        )
        mock_sqs_client.return_value = mock_sqs
        
        result = delete_message('invalid-receipt-handle')
        assert result is False


class TestMessageProcessing:
    """Test complete message processing"""
    
    @patch('app.main.parse_message_body')
    @patch('app.main.generate_s3_key')
    @patch('app.main.upload_to_s3')
    @patch('app.main.delete_message')
    def test_process_message_success(self, mock_delete, mock_upload, mock_key, mock_parse):
        """Test successful message processing"""
        mock_parse.return_value = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1234567890',
            'email_content': 'Test content'
        }
        mock_key.return_value = 'emails/test-key.json'
        mock_upload.return_value = True
        mock_delete.return_value = True
        
        message = {
            'MessageId': 'msg-1',
            'Body': json.dumps({'test': 'data'}),
            'ReceiptHandle': 'receipt-handle-1'
        }
        
        result = process_message(message)
        assert result is True
        mock_upload.assert_called_once()
        mock_delete.assert_called_once()
    
    @patch('app.main.parse_message_body')
    @patch('app.main.delete_message')
    def test_process_message_invalid_format(self, mock_delete, mock_parse):
        """Test processing message with invalid format"""
        mock_parse.return_value = None  # Invalid message
        
        message = {
            'MessageId': 'msg-1',
            'Body': 'invalid',
            'ReceiptHandle': 'receipt-handle-1'
        }
        
        result = process_message(message)
        assert result is False
        mock_delete.assert_called_once()  # Invalid messages are deleted
    
    @patch('app.main.parse_message_body')
    @patch('app.main.generate_s3_key')
    @patch('app.main.upload_to_s3')
    def test_process_message_s3_upload_fails(self, mock_upload, mock_key, mock_parse):
        """Test message processing when S3 upload fails"""
        mock_parse.return_value = {
            'email_subject': 'Test',
            'email_sender': 'test@example.com',
            'email_timestream': '1234567890',
            'email_content': 'Test content'
        }
        mock_key.return_value = 'emails/test-key.json'
        mock_upload.return_value = False  # Upload fails
        
        message = {
            'MessageId': 'msg-1',
            'Body': json.dumps({'test': 'data'}),
            'ReceiptHandle': 'receipt-handle-1'
        }
        
        result = process_message(message)
        assert result is False
        # Message should NOT be deleted if upload fails

