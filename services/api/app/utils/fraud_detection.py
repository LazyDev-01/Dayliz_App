import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
import re
from decimal import Decimal
import hashlib
from dataclasses import dataclass

@dataclass
class FraudRiskScore:
    """Fraud risk score result"""
    score: int  # 0-100, higher is riskier
    risk_level: str  # low, medium, high, critical
    reasons: List[str]
    recommendations: List[str]

class PaymentFraudDetector:
    """
    Advanced Payment Fraud Detection System for Indian Market
    
    Compliance:
    - RBI Guidelines for Digital Payment Security
    - Indian Cybersecurity Framework
    - PCI-DSS Fraud Prevention Requirements
    - NPCI Fraud Prevention Guidelines
    """
    
    def __init__(self):
        self.logger = logging.getLogger("fraud_detection")
        self.logger.setLevel(logging.INFO)
        
        # Risk thresholds
        self.LOW_RISK_THRESHOLD = 30
        self.MEDIUM_RISK_THRESHOLD = 60
        self.HIGH_RISK_THRESHOLD = 80
        
        # Velocity limits (Indian market specific)
        self.MAX_TRANSACTIONS_PER_HOUR = 5
        self.MAX_TRANSACTIONS_PER_DAY = 20
        self.MAX_AMOUNT_PER_HOUR = 50000.0  # ₹50,000
        self.MAX_AMOUNT_PER_DAY = 200000.0  # ₹2 Lakh
        
        # Suspicious patterns
        self.SUSPICIOUS_AMOUNT_PATTERNS = [
            9999.0, 19999.0, 49999.0,  # Just below common limits
            1111.11, 2222.22, 3333.33,  # Repeated digits
        ]
        
        # High-risk IP ranges (to be configured)
        self.HIGH_RISK_IP_RANGES = []
        
        # Blocked countries (if international payments enabled)
        self.BLOCKED_COUNTRIES = ["CN", "PK", "BD"]  # Example
    
    async def analyze_transaction_risk(
        self,
        user_id: str,
        amount: float,
        payment_method: str,
        ip_address: str,
        user_agent: str,
        delivery_address: Dict[str, Any],
        order_items: List[Dict[str, Any]] = None
    ) -> FraudRiskScore:
        """
        Comprehensive fraud risk analysis for transactions
        """
        try:
            risk_score = 0
            risk_reasons = []
            recommendations = []
            
            # 1. Amount-based risk analysis
            amount_risk = await self._analyze_amount_risk(amount, user_id)
            risk_score += amount_risk["score"]
            risk_reasons.extend(amount_risk["reasons"])
            
            # 2. Velocity analysis
            velocity_risk = await self._analyze_velocity_risk(user_id, amount)
            risk_score += velocity_risk["score"]
            risk_reasons.extend(velocity_risk["reasons"])
            
            # 3. Geographic risk analysis
            geo_risk = await self._analyze_geographic_risk(ip_address, delivery_address)
            risk_score += geo_risk["score"]
            risk_reasons.extend(geo_risk["reasons"])
            
            # 4. User behavior analysis
            behavior_risk = await self._analyze_user_behavior(user_id, payment_method)
            risk_score += behavior_risk["score"]
            risk_reasons.extend(behavior_risk["reasons"])
            
            # 5. Device and session analysis
            device_risk = await self._analyze_device_risk(user_agent, ip_address)
            risk_score += device_risk["score"]
            risk_reasons.extend(device_risk["reasons"])
            
            # 6. Order pattern analysis
            if order_items:
                order_risk = await self._analyze_order_patterns(order_items, user_id)
                risk_score += order_risk["score"]
                risk_reasons.extend(order_risk["reasons"])
            
            # 7. Time-based analysis
            time_risk = await self._analyze_time_patterns(user_id)
            risk_score += time_risk["score"]
            risk_reasons.extend(time_risk["reasons"])
            
            # Cap the risk score at 100
            risk_score = min(risk_score, 100)
            
            # Determine risk level
            if risk_score < self.LOW_RISK_THRESHOLD:
                risk_level = "low"
                recommendations.append("Transaction approved - low risk")
            elif risk_score < self.MEDIUM_RISK_THRESHOLD:
                risk_level = "medium"
                recommendations.extend([
                    "Additional verification recommended",
                    "Monitor transaction closely"
                ])
            elif risk_score < self.HIGH_RISK_THRESHOLD:
                risk_level = "high"
                recommendations.extend([
                    "Manual review required",
                    "Consider additional authentication",
                    "Limit transaction amount"
                ])
            else:
                risk_level = "critical"
                recommendations.extend([
                    "Block transaction",
                    "Require manual approval",
                    "Investigate user account"
                ])
            
            self.logger.info(
                f"Fraud analysis completed - User: {user_id}, "
                f"Amount: ₹{amount}, Risk Score: {risk_score}, Level: {risk_level}"
            )
            
            return FraudRiskScore(
                score=risk_score,
                risk_level=risk_level,
                reasons=risk_reasons,
                recommendations=recommendations
            )
            
        except Exception as e:
            self.logger.error(f"Fraud analysis failed: {str(e)}")
            # Return high risk on analysis failure
            return FraudRiskScore(
                score=90,
                risk_level="critical",
                reasons=["Fraud analysis system error"],
                recommendations=["Manual review required"]
            )
    
    async def _analyze_amount_risk(self, amount: float, user_id: str) -> Dict[str, Any]:
        """Analyze risk based on transaction amount"""
        risk_score = 0
        reasons = []
        
        # Check for suspicious amount patterns
        if amount in self.SUSPICIOUS_AMOUNT_PATTERNS:
            risk_score += 25
            reasons.append(f"Suspicious amount pattern: ₹{amount}")
        
        # Check for round numbers (potential testing)
        if amount % 1000 == 0 and amount >= 10000:
            risk_score += 10
            reasons.append("Large round number amount")
        
        # Check against user's historical spending
        avg_order_value = await self._get_user_average_order_value(user_id)
        if avg_order_value > 0:
            if amount > avg_order_value * 5:  # 5x higher than average
                risk_score += 20
                reasons.append("Amount significantly higher than user average")
            elif amount > avg_order_value * 3:  # 3x higher than average
                risk_score += 10
                reasons.append("Amount moderately higher than user average")
        
        # Very high amounts
        if amount > 100000:  # ₹1 Lakh
            risk_score += 15
            reasons.append("Very high transaction amount")
        elif amount > 50000:  # ₹50,000
            risk_score += 8
            reasons.append("High transaction amount")
        
        return {"score": risk_score, "reasons": reasons}
    
    async def _analyze_velocity_risk(self, user_id: str, amount: float) -> Dict[str, Any]:
        """Analyze transaction velocity risk"""
        risk_score = 0
        reasons = []
        
        # Get recent transactions
        hourly_transactions = await self._get_recent_transactions(user_id, hours=1)
        daily_transactions = await self._get_recent_transactions(user_id, hours=24)
        
        # Check transaction count velocity
        if len(hourly_transactions) >= self.MAX_TRANSACTIONS_PER_HOUR:
            risk_score += 30
            reasons.append(f"Too many transactions in last hour: {len(hourly_transactions)}")
        elif len(hourly_transactions) >= self.MAX_TRANSACTIONS_PER_HOUR - 1:
            risk_score += 15
            reasons.append("High transaction frequency in last hour")
        
        if len(daily_transactions) >= self.MAX_TRANSACTIONS_PER_DAY:
            risk_score += 25
            reasons.append(f"Too many transactions today: {len(daily_transactions)}")
        
        # Check amount velocity
        hourly_amount = sum(t.get("amount", 0) for t in hourly_transactions) + amount
        daily_amount = sum(t.get("amount", 0) for t in daily_transactions) + amount
        
        if hourly_amount > self.MAX_AMOUNT_PER_HOUR:
            risk_score += 25
            reasons.append(f"Hourly amount limit exceeded: ₹{hourly_amount:,.0f}")
        
        if daily_amount > self.MAX_AMOUNT_PER_DAY:
            risk_score += 20
            reasons.append(f"Daily amount limit exceeded: ₹{daily_amount:,.0f}")
        
        return {"score": risk_score, "reasons": reasons}
    
    async def _analyze_geographic_risk(self, ip_address: str, delivery_address: Dict[str, Any]) -> Dict[str, Any]:
        """Analyze geographic and location-based risk"""
        risk_score = 0
        reasons = []
        
        # Check IP reputation
        if await self._is_high_risk_ip(ip_address):
            risk_score += 30
            reasons.append("High-risk IP address detected")
        
        # Check for VPN/Proxy usage
        if await self._is_vpn_or_proxy(ip_address):
            risk_score += 20
            reasons.append("VPN or proxy usage detected")
        
        # Validate Indian address
        pincode = delivery_address.get("pincode", "")
        if not re.match(r'^\d{6}$', pincode):
            risk_score += 15
            reasons.append("Invalid Indian pincode format")
        
        # Check for high-risk pincodes (if configured)
        if await self._is_high_risk_pincode(pincode):
            risk_score += 10
            reasons.append("Delivery to high-risk area")
        
        # Geographic distance analysis
        ip_location = await self._get_ip_location(ip_address)
        if ip_location and delivery_address:
            distance = await self._calculate_distance(ip_location, delivery_address)
            if distance > 500:  # More than 500 km
                risk_score += 15
                reasons.append("Large distance between IP location and delivery address")
        
        return {"score": risk_score, "reasons": reasons}
    
    async def _analyze_user_behavior(self, user_id: str, payment_method: str) -> Dict[str, Any]:
        """Analyze user behavior patterns"""
        risk_score = 0
        reasons = []
        
        # Check account age
        account_age = await self._get_account_age_days(user_id)
        if account_age < 1:  # Less than 1 day old
            risk_score += 25
            reasons.append("Very new account (less than 1 day)")
        elif account_age < 7:  # Less than 1 week old
            risk_score += 15
            reasons.append("New account (less than 1 week)")
        elif account_age < 30:  # Less than 1 month old
            risk_score += 5
            reasons.append("Relatively new account")
        
        # Check order history
        total_orders = await self._get_user_total_orders(user_id)
        if total_orders == 0:
            risk_score += 20
            reasons.append("First-time customer")
        elif total_orders < 3:
            risk_score += 10
            reasons.append("Limited order history")
        
        # Check failed payment attempts
        failed_payments = await self._get_recent_failed_payments(user_id, days=7)
        if failed_payments > 3:
            risk_score += 20
            reasons.append(f"Multiple recent failed payments: {failed_payments}")
        elif failed_payments > 1:
            risk_score += 10
            reasons.append("Recent failed payment attempts")
        
        # Check for COD abuse
        if payment_method == "cod":
            cod_return_rate = await self._get_cod_return_rate(user_id)
            if cod_return_rate > 0.5:  # More than 50% return rate
                risk_score += 25
                reasons.append("High COD return rate")
            elif cod_return_rate > 0.3:  # More than 30% return rate
                risk_score += 15
                reasons.append("Elevated COD return rate")
        
        return {"score": risk_score, "reasons": reasons}
    
    async def _analyze_device_risk(self, user_agent: str, ip_address: str) -> Dict[str, Any]:
        """Analyze device and session risk"""
        risk_score = 0
        reasons = []
        
        # Check for suspicious user agents
        if not user_agent or len(user_agent) < 10:
            risk_score += 15
            reasons.append("Missing or suspicious user agent")
        
        # Check for automated tools
        suspicious_agents = ["bot", "crawler", "spider", "scraper", "automated"]
        if any(agent in user_agent.lower() for agent in suspicious_agents):
            risk_score += 25
            reasons.append("Automated tool detected")
        
        # Check for mobile vs desktop patterns
        is_mobile = any(mobile in user_agent.lower() for mobile in ["mobile", "android", "iphone"])
        if not is_mobile:
            risk_score += 5
            reasons.append("Desktop browser usage (mobile app expected)")
        
        return {"score": risk_score, "reasons": reasons}
    
    async def _analyze_order_patterns(self, order_items: List[Dict[str, Any]], user_id: str) -> Dict[str, Any]:
        """Analyze order pattern risks"""
        risk_score = 0
        reasons = []
        
        # Check for unusual quantities
        total_quantity = sum(item.get("quantity", 0) for item in order_items)
        if total_quantity > 50:  # Very large quantity
            risk_score += 15
            reasons.append(f"Unusually large total quantity: {total_quantity}")
        
        # Check for high-value items
        high_value_items = [item for item in order_items if item.get("price", 0) > 5000]
        if len(high_value_items) > 3:
            risk_score += 10
            reasons.append("Multiple high-value items")
        
        # Check for duplicate items in large quantities
        for item in order_items:
            if item.get("quantity", 0) > 10:
                risk_score += 8
                reasons.append(f"Large quantity of single item: {item.get('name', 'Unknown')}")
        
        return {"score": risk_score, "reasons": reasons}
    
    async def _analyze_time_patterns(self, user_id: str) -> Dict[str, Any]:
        """Analyze time-based risk patterns"""
        risk_score = 0
        reasons = []
        
        current_hour = datetime.now().hour
        
        # Check for unusual hours (late night transactions)
        if current_hour < 6 or current_hour > 23:
            risk_score += 10
            reasons.append("Transaction during unusual hours")
        
        # Check for rapid successive transactions
        last_transaction_time = await self._get_last_transaction_time(user_id)
        if last_transaction_time:
            time_diff = datetime.now() - last_transaction_time
            if time_diff.total_seconds() < 60:  # Less than 1 minute
                risk_score += 20
                reasons.append("Very rapid successive transaction")
            elif time_diff.total_seconds() < 300:  # Less than 5 minutes
                risk_score += 10
                reasons.append("Rapid successive transaction")
        
        return {"score": risk_score, "reasons": reasons}
    
    # Helper methods (placeholder implementations)
    
    async def _get_user_average_order_value(self, user_id: str) -> float:
        """Get user's average order value"""
        # TODO: Implement actual database query
        return 0.0
    
    async def _get_recent_transactions(self, user_id: str, hours: int) -> List[Dict]:
        """Get recent transactions for user"""
        # TODO: Implement actual database query
        return []
    
    async def _is_high_risk_ip(self, ip_address: str) -> bool:
        """Check if IP is in high-risk database"""
        # TODO: Implement IP reputation check
        return False
    
    async def _is_vpn_or_proxy(self, ip_address: str) -> bool:
        """Check if IP is VPN or proxy"""
        # TODO: Implement VPN/proxy detection
        return False
    
    async def _is_high_risk_pincode(self, pincode: str) -> bool:
        """Check if pincode is high-risk"""
        # TODO: Implement pincode risk database
        return False
    
    async def _get_ip_location(self, ip_address: str) -> Optional[Dict]:
        """Get geographic location of IP"""
        # TODO: Implement IP geolocation
        return None
    
    async def _calculate_distance(self, location1: Dict, location2: Dict) -> float:
        """Calculate distance between two locations"""
        # TODO: Implement distance calculation
        return 0.0
    
    async def _get_account_age_days(self, user_id: str) -> int:
        """Get account age in days"""
        # TODO: Implement actual database query
        return 30
    
    async def _get_user_total_orders(self, user_id: str) -> int:
        """Get total number of orders for user"""
        # TODO: Implement actual database query
        return 0
    
    async def _get_recent_failed_payments(self, user_id: str, days: int) -> int:
        """Get count of recent failed payments"""
        # TODO: Implement actual database query
        return 0
    
    async def _get_cod_return_rate(self, user_id: str) -> float:
        """Get COD return rate for user"""
        # TODO: Implement actual database query
        return 0.0
    
    async def _get_last_transaction_time(self, user_id: str) -> Optional[datetime]:
        """Get timestamp of last transaction"""
        # TODO: Implement actual database query
        return None
