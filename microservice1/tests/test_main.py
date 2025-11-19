"""
Unit tests for Microservice 1
"""
import pytest
import os
import json
from unittest.mock import Mock, patch, MagicMock
from fastapi.testclient import TestClient
from botocore.exceptions import ClientError

# Set test environment variables before importing the app
os.environ["SSM_TOKEN_PARAMETER"] = "/test/api-token"
os.environ["SQS_QUEUE_URL"] = "https://sqs.eu-west-1.amazonaws.com/123456789/test-queue"
os.environ["AWS_REGION"] = "eu-west-1"

from app.main import app, validate_token, get_token_from_ssm, publish_to_sqs


@pytest.fixture
def client():
    """Create test client"""
    return TestClient(app)


@pytest.fixture
def mock_ssm_token():
    """Mock SSM token value"""
    return "test-token-12345"


class TestTokenValidation:
    """Test token validation functionality"""
    
    @patch('app.main.get_ssm_client')
    def test_validate_token_success(self, mock_ssm_client, mock_ssm_token):
        """Test successful token validation"""
        # Mock SSM response
        mock_ssm = Mock()
        mock_ssm.get_parameter.return_value = {
            "Parameter": {
                "Value": mock_ssm_token
            }
        }
        mock_ssm_client.return_value = mock_ssm
        
        result = validate_token(mock_ssm_token)
        assert result is True
    
    @patch('app.main.get_ssm_client')
    def test_validate_token_failure(self, mock_ssm_client, mock_ssm_token):
        """Test failed token validation"""
        # Mock SSM response
        mock_ssm = Mock()
        mock_ssm.get_parameter.return_value = {
            "Parameter": {
                "Value": mock_ssm_token
            }
        }
        mock_ssm_client.return_value = mock_ssm
        
        result = validate_token("wrong-token")
        assert result is False
    
    @patch('app.main.get_ssm_client')
    def test_validate_token_whitespace_stripping(self, mock_ssm_client):
        """Test token validation with whitespace stripping"""
        # Mock SSM response with newline
        mock_ssm = Mock()
        mock_ssm.get_parameter.return_value = {
            "Parameter": {
                "Value": "test-token\n"
            }
        }
        mock_ssm_client.return_value = mock_ssm
        
        result = validate_token("test-token")
        assert result is True
    
    @patch('app.main.get_ssm_client')
    def test_validate_token_ssm_error(self, mock_ssm_client):
        """Test token validation when SSM returns error"""
        # Mock SSM error
        mock_ssm = Mock()
        mock_ssm.get_parameter.side_effect = ClientError(
            {'Error': {'Code': 'ParameterNotFound'}},
            'GetParameter'
        )
        mock_ssm_client.return_value = mock_ssm
        
        result = validate_token("any-token")
        assert result is False


class TestPayloadValidation:
    """Test payload validation"""
    
    def test_valid_payload(self, client, mock_ssm_token):
        """Test valid payload structure"""
        with patch('app.main.validate_token', return_value=True), \
             patch('app.main.publish_to_sqs', return_value=True):
            
            payload = {
                "token": mock_ssm_token,
                "data": {
                    "email_subject": "Test Subject",
                    "email_sender": "sender@example.com",
                    "email_timestream": "2024-01-01T00:00:00Z",
                    "email_content": "Test content"
                }
            }
            
            response = client.post("/api/email", json=payload)
            assert response.status_code == 200
            assert response.json()["status"] == "success"
    
    def test_missing_required_fields(self, client):
        """Test payload with missing required fields"""
        payload = {
            "token": "test-token",
            "data": {
                "email_subject": "Test Subject",
                "email_sender": "sender@example.com"
                # Missing email_timestream and email_content
            }
        }
        
        response = client.post("/api/email", json=payload)
        assert response.status_code == 422  # Validation error
    
    def test_empty_fields(self, client):
        """Test payload with empty fields"""
        payload = {
            "token": "test-token",
            "data": {
                "email_subject": "",
                "email_sender": "sender@example.com",
                "email_timestream": "2024-01-01T00:00:00Z",
                "email_content": "Test content"
            }
        }
        
        response = client.post("/api/email", json=payload)
        assert response.status_code == 422  # Validation error
    
    def test_whitespace_only_fields(self, client):
        """Test payload with whitespace-only fields"""
        payload = {
            "token": "test-token",
            "data": {
                "email_subject": "   ",
                "email_sender": "sender@example.com",
                "email_timestream": "2024-01-01T00:00:00Z",
                "email_content": "Test content"
            }
        }
        
        response = client.post("/api/email", json=payload)
        assert response.status_code == 422  # Validation error


class TestAPIEndpoints:
    """Test API endpoints"""
    
    def test_health_check(self, client):
        """Test health check endpoint"""
        response = client.get("/health")
        assert response.status_code == 200
        assert response.json()["status"] == "healthy"
        assert response.json()["service"] == "microservice1"
    
    @patch('app.main.get_token_from_ssm')
    def test_debug_token_endpoint(self, mock_get_token, client):
        """Test debug token endpoint"""
        mock_get_token.return_value = "test-token-12345"
        
        response = client.get("/debug/token")
        assert response.status_code == 200
        assert "token_length" in response.json()
        assert response.json()["ssm_token_parameter"] == "/test/api-token"
    
    def test_process_email_invalid_token(self, client):
        """Test email processing with invalid token"""
        with patch('app.main.validate_token', return_value=False):
            payload = {
                "token": "invalid-token",
                "data": {
                    "email_subject": "Test Subject",
                    "email_sender": "sender@example.com",
                    "email_timestream": "2024-01-01T00:00:00Z",
                    "email_content": "Test content"
                }
            }
            
            response = client.post("/api/email", json=payload)
            assert response.status_code == 401
            assert "Invalid authentication token" in response.json()["detail"]
    
    def test_process_email_sqs_error(self, client, mock_ssm_token):
        """Test email processing when SQS fails"""
        with patch('app.main.validate_token', return_value=True), \
             patch('app.main.publish_to_sqs', side_effect=Exception("SQS Error")):
            
            payload = {
                "token": mock_ssm_token,
                "data": {
                    "email_subject": "Test Subject",
                    "email_sender": "sender@example.com",
                    "email_timestream": "2024-01-01T00:00:00Z",
                    "email_content": "Test content"
                }
            }
            
            response = client.post("/api/email", json=payload)
            assert response.status_code == 500


class TestSQSIntegration:
    """Test SQS publishing"""
    
    @patch('app.main.get_sqs_client')
    def test_publish_to_sqs_success(self, mock_sqs_client):
        """Test successful SQS publish"""
        mock_sqs = Mock()
        mock_sqs.send_message.return_value = {
            "MessageId": "test-message-id"
        }
        mock_sqs_client.return_value = mock_sqs
        
        message = {
            "email_subject": "Test",
            "email_sender": "test@example.com",
            "email_timestream": "2024-01-01T00:00:00Z",
            "email_content": "Test content"
        }
        
        result = publish_to_sqs(message)
        assert result is True
        mock_sqs.send_message.assert_called_once()
    
    @patch('app.main.get_sqs_client')
    def test_publish_to_sqs_error(self, mock_sqs_client):
        """Test SQS publish error"""
        mock_sqs = Mock()
        mock_sqs.send_message.side_effect = ClientError(
            {'Error': {'Code': 'AWS.SimpleQueueService.NonExistentQueue'}},
            'SendMessage'
        )
        mock_sqs_client.return_value = mock_sqs
        
        message = {
            "email_subject": "Test",
            "email_sender": "test@example.com",
            "email_timestream": "2024-01-01T00:00:00Z",
            "email_content": "Test content"
        }
        
        with pytest.raises(Exception):  # Should raise HTTPException
            publish_to_sqs(message)