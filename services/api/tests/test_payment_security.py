import pytest
import asyncio
from unittest.mock import Mock, patch, AsyncMock
from datetime import datetime, timedelta
import hmac
import hashlib

from app.utils.payment_security import PaymentSecurityManager
from app.utils.fraud_detection import PaymentFraudDetector, FraudRiskScore
from app.core.config import settings

class TestPaymentSecurityManager:
    """
    Comprehensive test suite for Payment Security Manager
    
    Tests cover:
    - PCI-DSS compliance requirements
    - Indian regulatory compliance
    - Security vulnerability prevention
    - Fraud detection mechanisms
    """
    
    @pytest.fixture
    def payment_security(self):
        """Create PaymentSecurityManager instance for testing"""
        return PaymentSecurityManager()
    
    @pytest.fixture
    def fraud_detector(self):
        """Create PaymentFraudDetector instance for testing"""
        return PaymentFraudDetector()
    
    def test_razorpay_signature_verification_valid(self, payment_security):
        """Test valid Razorpay signature verification"""
        # Arrange
        order_id = "order_test123"
        payment_id = "pay_test456"
        secret = "test_secret_key"
        
        # Create valid signature
        message = f"{order_id}|{payment_id}"
        expected_signature = hmac.new(
            secret.encode('utf-8'),
            message.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
        
        # Mock settings
        with patch.object(settings, 'RAZORPAY_KEY_SECRET', secret):
            # Act
            result = payment_security.verify_razorpay_signature(
                order_id, payment_id, expected_signature
            )
        
        # Assert
        assert result is True
    
    def test_razorpay_signature_verification_invalid(self, payment_security):
        """Test invalid Razorpay signature verification"""
        # Arrange
        order_id = "order_test123"
        payment_id = "pay_test456"
        invalid_signature = "invalid_signature"
        secret = "test_secret_key"
        
        # Mock settings
        with patch.object(settings, 'RAZORPAY_KEY_SECRET', secret):
            # Act
            result = payment_security.verify_razorpay_signature(
                order_id, payment_id, invalid_signature
            )
        
        # Assert
        assert result is False
    
    def test_razorpay_signature_verification_timing_attack_prevention(self, payment_security):
        """Test timing attack prevention in signature verification"""
        # Arrange
        order_id = "order_test123"
        payment_id = "pay_test456"
        secret = "test_secret_key"
        
        # Create two different invalid signatures
        invalid_signature1 = "a" * 64
        invalid_signature2 = "b" * 64
        
        # Mock settings
        with patch.object(settings, 'RAZORPAY_KEY_SECRET', secret):
            # Act - measure time for both verifications
            import time
            
            start1 = time.time()
            result1 = payment_security.verify_razorpay_signature(
                order_id, payment_id, invalid_signature1
            )
            end1 = time.time()
            
            start2 = time.time()
            result2 = payment_security.verify_razorpay_signature(
                order_id, payment_id, invalid_signature2
            )
            end2 = time.time()
        
        # Assert
        assert result1 is False
        assert result2 is False
        # Time difference should be minimal (constant-time comparison)
        time_diff = abs((end1 - start1) - (end2 - start2))
        assert time_diff < 0.001  # Less than 1ms difference
    
    def test_input_sanitization(self, payment_security):
        """Test input sanitization against injection attacks"""
        # Arrange
        malicious_inputs = [
            "'; DROP TABLE orders; --",
            "<script>alert('xss')</script>",
            "../../etc/passwd",
            "order_123; rm -rf /",
            "order_123\x00\x01\x02"
        ]
        
        # Act & Assert
        for malicious_input in malicious_inputs:
            sanitized = payment_security._sanitize_input(malicious_input)
            # Should only contain alphanumeric characters and allowed symbols
            assert all(c.isalnum() or c in '_-|' for c in sanitized)
    
    @pytest.mark.asyncio
    async def test_cod_validation_amount_limit(self, payment_security):
        """Test COD validation against RBI amount limits"""
        # Arrange
        order_over_limit = {
            "total_amount": 60000.0,  # Over ₹50,000 limit
            "delivery_address": {
                "street": "123 Test Street",
                "city": "Mumbai",
                "state": "Maharashtra",
                "pincode": "400001"
            }
        }
        
        order_within_limit = {
            "total_amount": 30000.0,  # Within ₹50,000 limit
            "delivery_address": {
                "street": "123 Test Street",
                "city": "Mumbai",
                "state": "Maharashtra",
                "pincode": "400001"
            }
        }
        
        # Mock dependencies
        with patch.object(payment_security, '_calculate_user_risk_score', return_value=30), \
             patch.object(payment_security, '_get_recent_orders', return_value=[]), \
             patch.object(payment_security, '_is_serviceable_pincode', return_value=True):
            
            # Act
            result_over = await payment_security.validate_cod_order(
                order_over_limit, "user123", "192.168.1.1"
            )
            result_within = await payment_security.validate_cod_order(
                order_within_limit, "user123", "192.168.1.1"
            )
        
        # Assert
        assert result_over["eligible"] is False
        assert "50,000" in result_over["reason"]
        assert result_within["eligible"] is True
    
    @pytest.mark.asyncio
    async def test_cod_validation_invalid_address(self, payment_security):
        """Test COD validation with invalid Indian address"""
        # Arrange
        order_invalid_pincode = {
            "total_amount": 1000.0,
            "delivery_address": {
                "street": "123 Test Street",
                "city": "Mumbai",
                "state": "Maharashtra",
                "pincode": "12345"  # Invalid - not 6 digits
            }
        }
        
        order_missing_fields = {
            "total_amount": 1000.0,
            "delivery_address": {
                "street": "123 Test Street",
                # Missing city, state, pincode
            }
        }
        
        # Act
        result_invalid = await payment_security.validate_cod_order(
            order_invalid_pincode, "user123", "192.168.1.1"
        )
        result_missing = await payment_security.validate_cod_order(
            order_missing_fields, "user123", "192.168.1.1"
        )
        
        # Assert
        assert result_invalid["eligible"] is False
        assert "address" in result_invalid["reason"].lower()
        assert result_missing["eligible"] is False
        assert "address" in result_missing["reason"].lower()
    
    @pytest.mark.asyncio
    async def test_fraud_detection_velocity_limits(self, fraud_detector):
        """Test fraud detection velocity limits"""
        # Arrange
        user_id = "user123"
        amount = 1000.0
        
        # Mock recent transactions exceeding limits
        recent_transactions = [
            {"amount": 1000.0, "timestamp": datetime.now() - timedelta(minutes=30)},
            {"amount": 1500.0, "timestamp": datetime.now() - timedelta(minutes=20)},
            {"amount": 2000.0, "timestamp": datetime.now() - timedelta(minutes=10)},
            {"amount": 1200.0, "timestamp": datetime.now() - timedelta(minutes=5)},
            {"amount": 800.0, "timestamp": datetime.now() - timedelta(minutes=2)},
        ]
        
        with patch.object(fraud_detector, '_get_recent_transactions', return_value=recent_transactions), \
             patch.object(fraud_detector, '_get_user_average_order_value', return_value=1000.0), \
             patch.object(fraud_detector, '_get_account_age_days', return_value=30), \
             patch.object(fraud_detector, '_get_user_total_orders', return_value=10), \
             patch.object(fraud_detector, '_get_recent_failed_payments', return_value=0), \
             patch.object(fraud_detector, '_get_cod_return_rate', return_value=0.1):
            
            # Act
            risk_score = await fraud_detector.analyze_transaction_risk(
                user_id=user_id,
                amount=amount,
                payment_method="cod",
                ip_address="192.168.1.1",
                user_agent="Mozilla/5.0 (Mobile)",
                delivery_address={
                    "street": "123 Test Street",
                    "city": "Mumbai",
                    "state": "Maharashtra",
                    "pincode": "400001"
                }
            )
        
        # Assert
        assert risk_score.score > fraud_detector.MEDIUM_RISK_THRESHOLD
        assert risk_score.risk_level in ["high", "critical"]
        assert any("transaction" in reason.lower() for reason in risk_score.reasons)
    
    @pytest.mark.asyncio
    async def test_fraud_detection_new_account_risk(self, fraud_detector):
        """Test fraud detection for new accounts"""
        # Arrange
        user_id = "new_user123"
        amount = 5000.0
        
        with patch.object(fraud_detector, '_get_recent_transactions', return_value=[]), \
             patch.object(fraud_detector, '_get_user_average_order_value', return_value=0.0), \
             patch.object(fraud_detector, '_get_account_age_days', return_value=0), \
             patch.object(fraud_detector, '_get_user_total_orders', return_value=0), \
             patch.object(fraud_detector, '_get_recent_failed_payments', return_value=0), \
             patch.object(fraud_detector, '_get_cod_return_rate', return_value=0.0):
            
            # Act
            risk_score = await fraud_detector.analyze_transaction_risk(
                user_id=user_id,
                amount=amount,
                payment_method="cod",
                ip_address="192.168.1.1",
                user_agent="Mozilla/5.0 (Mobile)",
                delivery_address={
                    "street": "123 Test Street",
                    "city": "Mumbai",
                    "state": "Maharashtra",
                    "pincode": "400001"
                }
            )
        
        # Assert
        assert risk_score.score > fraud_detector.LOW_RISK_THRESHOLD
        assert any("new account" in reason.lower() or "first-time" in reason.lower() 
                  for reason in risk_score.reasons)
    
    @pytest.mark.asyncio
    async def test_fraud_detection_suspicious_amounts(self, fraud_detector):
        """Test fraud detection for suspicious amount patterns"""
        # Arrange
        suspicious_amounts = [9999.0, 19999.0, 49999.0, 1111.11, 2222.22]
        user_id = "user123"
        
        for amount in suspicious_amounts:
            with patch.object(fraud_detector, '_get_recent_transactions', return_value=[]), \
                 patch.object(fraud_detector, '_get_user_average_order_value', return_value=1000.0), \
                 patch.object(fraud_detector, '_get_account_age_days', return_value=30), \
                 patch.object(fraud_detector, '_get_user_total_orders', return_value=10), \
                 patch.object(fraud_detector, '_get_recent_failed_payments', return_value=0), \
                 patch.object(fraud_detector, '_get_cod_return_rate', return_value=0.1):
                
                # Act
                risk_score = await fraud_detector.analyze_transaction_risk(
                    user_id=user_id,
                    amount=amount,
                    payment_method="cod",
                    ip_address="192.168.1.1",
                    user_agent="Mozilla/5.0 (Mobile)",
                    delivery_address={
                        "street": "123 Test Street",
                        "city": "Mumbai",
                        "state": "Maharashtra",
                        "pincode": "400001"
                    }
                )
            
            # Assert
            assert any("suspicious amount" in reason.lower() 
                      for reason in risk_score.reasons)
    
    def test_indian_address_validation(self, payment_security):
        """Test Indian address validation"""
        # Arrange
        valid_address = {
            "street": "123 MG Road",
            "city": "Mumbai",
            "state": "Maharashtra",
            "pincode": "400001"
        }
        
        invalid_addresses = [
            {"street": "", "city": "Mumbai", "state": "Maharashtra", "pincode": "400001"},
            {"street": "123 MG Road", "city": "", "state": "Maharashtra", "pincode": "400001"},
            {"street": "123 MG Road", "city": "Mumbai", "state": "", "pincode": "400001"},
            {"street": "123 MG Road", "city": "Mumbai", "state": "Maharashtra", "pincode": ""},
            {"street": "123 MG Road", "city": "Mumbai", "state": "Maharashtra", "pincode": "12345"},
            {"street": "123 MG Road", "city": "Mumbai", "state": "Maharashtra", "pincode": "1234567"},
        ]
        
        # Act & Assert
        assert payment_security._validate_indian_address(valid_address) is True
        
        for invalid_address in invalid_addresses:
            assert payment_security._validate_indian_address(invalid_address) is False
    
    @pytest.mark.asyncio
    async def test_payment_method_availability(self, payment_security):
        """Test payment method availability based on user eligibility"""
        # Arrange
        low_risk_user = "low_risk_user"
        high_risk_user = "high_risk_user"
        
        with patch.object(payment_security, '_calculate_user_risk_score') as mock_risk:
            # Test low risk user
            mock_risk.return_value = 30
            low_risk_methods = await payment_security.get_available_payment_methods(low_risk_user)
            
            # Test high risk user
            mock_risk.return_value = 80
            high_risk_methods = await payment_security.get_available_payment_methods(high_risk_user)
        
        # Assert
        # Low risk user should have COD available
        cod_available_low = any(method["id"] == "cod" and method["enabled"] 
                               for method in low_risk_methods)
        assert cod_available_low is True
        
        # High risk user should not have COD available
        cod_available_high = any(method["id"] == "cod" and method["enabled"] 
                                for method in high_risk_methods)
        assert cod_available_high is False
    
    def test_webhook_signature_verification(self, payment_security):
        """Test webhook signature verification"""
        # Arrange
        payload = b'{"event": "payment.captured", "payload": {"payment": {"id": "pay_test123"}}}'
        secret = "webhook_secret"
        
        # Create valid signature
        expected_signature = hmac.new(
            secret.encode('utf-8'),
            payload,
            hashlib.sha256
        ).hexdigest()
        
        # Mock settings
        with patch.object(settings, 'RAZORPAY_KEY_SECRET', secret):
            # Act
            valid_result = payment_security.verify_webhook_signature(payload, expected_signature)
            invalid_result = payment_security.verify_webhook_signature(payload, "invalid_signature")
        
        # Assert
        assert valid_result is True
        assert invalid_result is False
    
    @pytest.mark.asyncio
    async def test_daily_transaction_limit_enforcement(self, payment_security):
        """Test daily transaction limit enforcement"""
        # Arrange
        user_id = "user123"
        
        # Mock user already at daily limit
        with patch.object(payment_security, '_get_user_daily_transaction_total', 
                         return_value=payment_security.DAILY_TRANSACTION_LIMIT):
            
            # Act & Assert
            with pytest.raises(ValueError, match="Daily transaction limit exceeded"):
                await payment_security.create_razorpay_order(
                    amount=1000.0,
                    currency="INR",
                    user_id=user_id
                )
    
    def test_currency_validation(self, payment_security):
        """Test currency validation for Indian market"""
        # Act & Assert
        with pytest.raises(ValueError, match="Only INR currency is supported"):
            asyncio.run(payment_security.create_razorpay_order(
                amount=1000.0,
                currency="USD",
                user_id="user123"
            ))
    
    def test_minimum_amount_validation(self, payment_security):
        """Test minimum amount validation"""
        # Act & Assert
        with pytest.raises(ValueError, match="Minimum transaction amount is ₹1.00"):
            asyncio.run(payment_security.create_razorpay_order(
                amount=0.50,
                currency="INR",
                user_id="user123"
            ))
    
    def test_maximum_amount_validation(self, payment_security):
        """Test maximum amount validation"""
        # Act & Assert
        with pytest.raises(ValueError, match="Amount exceeds maximum transaction limit"):
            asyncio.run(payment_security.create_razorpay_order(
                amount=250000.0,  # Over ₹2 Lakh limit
                currency="INR",
                user_id="user123"
            ))
