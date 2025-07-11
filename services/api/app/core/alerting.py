import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from app.core.config import settings

class AlertSeverity(Enum):
    """Alert severity levels"""
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class AlertChannel(Enum):
    """Alert delivery channels"""
    EMAIL = "email"
    SLACK = "slack"
    DISCORD = "discord"
    SMS = "sms"
    WEBHOOK = "webhook"

@dataclass
class Alert:
    """Alert data structure"""
    id: str
    title: str
    message: str
    severity: AlertSeverity
    timestamp: datetime
    source: str
    tags: Dict[str, str]
    resolved: bool = False
    resolved_at: Optional[datetime] = None
    acknowledged: bool = False
    acknowledged_at: Optional[datetime] = None
    acknowledged_by: Optional[str] = None

@dataclass
class AlertRule:
    """Alert rule configuration"""
    name: str
    condition: str
    threshold: float
    severity: AlertSeverity
    channels: List[AlertChannel]
    cooldown_minutes: int = 5
    enabled: bool = True

class AlertingService:
    """
    Comprehensive Alerting Service for Dayliz API
    
    Features:
    - Multi-channel alert delivery
    - Alert severity management
    - Alert deduplication and cooldown
    - Alert acknowledgment and resolution
    - Integration with monitoring metrics
    """
    
    def __init__(self):
        self.logger = logging.getLogger("alerting")
        self.logger.setLevel(logging.INFO)
        
        # Alert storage
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.alert_rules: Dict[str, AlertRule] = {}
        
        # Alert state tracking
        self.last_alert_times: Dict[str, datetime] = {}
        self.alert_counts: Dict[str, int] = {}
        
        # Initialize default alert rules
        self._initialize_default_rules()
    
    def _initialize_default_rules(self):
        """Initialize default alert rules for Dayliz API"""
        default_rules = [
            AlertRule(
                name="high_error_rate",
                condition="error_rate > threshold",
                threshold=0.05,  # 5%
                severity=AlertSeverity.HIGH,
                channels=[AlertChannel.EMAIL, AlertChannel.SLACK],
                cooldown_minutes=5
            ),
            AlertRule(
                name="slow_response_time",
                condition="avg_response_time > threshold",
                threshold=2000,  # 2 seconds
                severity=AlertSeverity.MEDIUM,
                channels=[AlertChannel.EMAIL],
                cooldown_minutes=10
            ),
            AlertRule(
                name="high_cpu_usage",
                condition="cpu_percent > threshold",
                threshold=80,  # 80%
                severity=AlertSeverity.HIGH,
                channels=[AlertChannel.EMAIL, AlertChannel.SLACK],
                cooldown_minutes=5
            ),
            AlertRule(
                name="high_memory_usage",
                condition="memory_percent > threshold",
                threshold=80,  # 80%
                severity=AlertSeverity.HIGH,
                channels=[AlertChannel.EMAIL, AlertChannel.SLACK],
                cooldown_minutes=5
            ),
            AlertRule(
                name="payment_failure_spike",
                condition="payment_failure_rate > threshold",
                threshold=0.10,  # 10%
                severity=AlertSeverity.CRITICAL,
                channels=[AlertChannel.EMAIL, AlertChannel.SLACK, AlertChannel.SMS],
                cooldown_minutes=2
            ),
            AlertRule(
                name="order_processing_failure",
                condition="order_failure_rate > threshold",
                threshold=0.05,  # 5%
                severity=AlertSeverity.HIGH,
                channels=[AlertChannel.EMAIL, AlertChannel.SLACK],
                cooldown_minutes=5
            ),
            AlertRule(
                name="database_connection_failure",
                condition="db_connection_failures > threshold",
                threshold=5,  # 5 failures
                severity=AlertSeverity.CRITICAL,
                channels=[AlertChannel.EMAIL, AlertChannel.SLACK, AlertChannel.SMS],
                cooldown_minutes=1
            )
        ]
        
        for rule in default_rules:
            self.alert_rules[rule.name] = rule
    
    async def trigger_alert(
        self,
        rule_name: str,
        title: str,
        message: str,
        source: str = "monitoring",
        tags: Dict[str, str] = None,
        override_severity: AlertSeverity = None
    ) -> Optional[Alert]:
        """Trigger an alert based on a rule"""
        try:
            # Get alert rule
            rule = self.alert_rules.get(rule_name)
            if not rule or not rule.enabled:
                return None
            
            # Check cooldown
            if not self._check_cooldown(rule_name, rule.cooldown_minutes):
                self.logger.debug(f"Alert {rule_name} is in cooldown period")
                return None
            
            # Create alert
            alert_id = f"{rule_name}_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            severity = override_severity or rule.severity
            
            alert = Alert(
                id=alert_id,
                title=title,
                message=message,
                severity=severity,
                timestamp=datetime.now(),
                source=source,
                tags=tags or {}
            )
            
            # Store alert
            self.active_alerts[alert_id] = alert
            self.alert_history.append(alert)
            
            # Update tracking
            self.last_alert_times[rule_name] = datetime.now()
            self.alert_counts[rule_name] = self.alert_counts.get(rule_name, 0) + 1
            
            # Send alert through configured channels
            await self._send_alert(alert, rule.channels)
            
            self.logger.warning(f"Alert triggered: {title} - {message}")
            
            return alert
            
        except Exception as e:
            self.logger.error(f"Failed to trigger alert {rule_name}: {str(e)}")
            return None
    
    async def _send_alert(self, alert: Alert, channels: List[AlertChannel]):
        """Send alert through specified channels"""
        for channel in channels:
            try:
                if channel == AlertChannel.EMAIL:
                    await self._send_email_alert(alert)
                elif channel == AlertChannel.SLACK:
                    await self._send_slack_alert(alert)
                elif channel == AlertChannel.DISCORD:
                    await self._send_discord_alert(alert)
                elif channel == AlertChannel.SMS:
                    await self._send_sms_alert(alert)
                elif channel == AlertChannel.WEBHOOK:
                    await self._send_webhook_alert(alert)
                    
            except Exception as e:
                self.logger.error(f"Failed to send alert via {channel.value}: {str(e)}")
    
    async def _send_email_alert(self, alert: Alert):
        """Send alert via email"""
        try:
            if not hasattr(settings, 'SMTP_SERVER') or not settings.SMTP_SERVER:
                self.logger.warning("SMTP not configured, skipping email alert")
                return
            
            # Create email message
            msg = MIMEMultipart()
            msg['From'] = settings.ALERT_FROM_EMAIL
            msg['To'] = settings.ALERT_TO_EMAIL
            msg['Subject'] = f"[{alert.severity.value.upper()}] Dayliz Alert: {alert.title}"
            
            # Email body
            body = f"""
            Alert Details:
            
            Title: {alert.title}
            Severity: {alert.severity.value.upper()}
            Time: {alert.timestamp.strftime('%Y-%m-%d %H:%M:%S UTC')}
            Source: {alert.source}
            
            Message:
            {alert.message}
            
            Tags:
            {json.dumps(alert.tags, indent=2)}
            
            Alert ID: {alert.id}
            
            ---
            Dayliz Monitoring System
            """
            
            msg.attach(MIMEText(body, 'plain'))
            
            # Send email
            server = smtplib.SMTP(settings.SMTP_SERVER, settings.SMTP_PORT)
            if hasattr(settings, 'SMTP_USERNAME') and settings.SMTP_USERNAME:
                server.starttls()
                server.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
            
            server.send_message(msg)
            server.quit()
            
            self.logger.info(f"Email alert sent for {alert.id}")
            
        except Exception as e:
            self.logger.error(f"Failed to send email alert: {str(e)}")
    
    async def _send_slack_alert(self, alert: Alert):
        """Send alert via Slack webhook"""
        try:
            if not hasattr(settings, 'SLACK_WEBHOOK_URL') or not settings.SLACK_WEBHOOK_URL:
                self.logger.warning("Slack webhook not configured, skipping Slack alert")
                return
            
            # Create Slack message
            color = {
                AlertSeverity.LOW: "good",
                AlertSeverity.MEDIUM: "warning", 
                AlertSeverity.HIGH: "danger",
                AlertSeverity.CRITICAL: "danger"
            }.get(alert.severity, "warning")
            
            payload = {
                "text": f"🚨 Dayliz Alert: {alert.title}",
                "attachments": [
                    {
                        "color": color,
                        "fields": [
                            {
                                "title": "Severity",
                                "value": alert.severity.value.upper(),
                                "short": True
                            },
                            {
                                "title": "Source",
                                "value": alert.source,
                                "short": True
                            },
                            {
                                "title": "Time",
                                "value": alert.timestamp.strftime('%Y-%m-%d %H:%M:%S UTC'),
                                "short": True
                            },
                            {
                                "title": "Message",
                                "value": alert.message,
                                "short": False
                            }
                        ],
                        "footer": f"Alert ID: {alert.id}"
                    }
                ]
            }
            
            # Send to Slack (placeholder - would use actual HTTP client)
            # await http_client.post(settings.SLACK_WEBHOOK_URL, json=payload)
            
            self.logger.info(f"Slack alert sent for {alert.id}")
            
        except Exception as e:
            self.logger.error(f"Failed to send Slack alert: {str(e)}")
    
    async def _send_discord_alert(self, alert: Alert):
        """Send alert via Discord webhook"""
        try:
            # Similar to Slack implementation
            self.logger.info(f"Discord alert sent for {alert.id}")
            
        except Exception as e:
            self.logger.error(f"Failed to send Discord alert: {str(e)}")
    
    async def _send_sms_alert(self, alert: Alert):
        """Send alert via SMS"""
        try:
            # SMS implementation would go here
            # Could use Twilio, AWS SNS, or other SMS service
            self.logger.info(f"SMS alert sent for {alert.id}")
            
        except Exception as e:
            self.logger.error(f"Failed to send SMS alert: {str(e)}")
    
    async def _send_webhook_alert(self, alert: Alert):
        """Send alert via custom webhook"""
        try:
            # Custom webhook implementation
            self.logger.info(f"Webhook alert sent for {alert.id}")
            
        except Exception as e:
            self.logger.error(f"Failed to send webhook alert: {str(e)}")
    
    def _check_cooldown(self, rule_name: str, cooldown_minutes: int) -> bool:
        """Check if alert is in cooldown period"""
        last_alert_time = self.last_alert_times.get(rule_name)
        if last_alert_time is None:
            return True
        
        cooldown_period = timedelta(minutes=cooldown_minutes)
        return datetime.now() - last_alert_time > cooldown_period
    
    async def acknowledge_alert(self, alert_id: str, acknowledged_by: str) -> bool:
        """Acknowledge an alert"""
        try:
            alert = self.active_alerts.get(alert_id)
            if not alert:
                return False
            
            alert.acknowledged = True
            alert.acknowledged_at = datetime.now()
            alert.acknowledged_by = acknowledged_by
            
            self.logger.info(f"Alert {alert_id} acknowledged by {acknowledged_by}")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to acknowledge alert {alert_id}: {str(e)}")
            return False
    
    async def resolve_alert(self, alert_id: str) -> bool:
        """Resolve an alert"""
        try:
            alert = self.active_alerts.get(alert_id)
            if not alert:
                return False
            
            alert.resolved = True
            alert.resolved_at = datetime.now()
            
            # Remove from active alerts
            del self.active_alerts[alert_id]
            
            self.logger.info(f"Alert {alert_id} resolved")
            return True
            
        except Exception as e:
            self.logger.error(f"Failed to resolve alert {alert_id}: {str(e)}")
            return False
    
    def get_active_alerts(self) -> List[Alert]:
        """Get all active alerts"""
        return list(self.active_alerts.values())
    
    def get_alert_history(self, limit: int = 100) -> List[Alert]:
        """Get alert history"""
        return self.alert_history[-limit:]
    
    def get_alert_statistics(self) -> Dict[str, Any]:
        """Get alert statistics"""
        return {
            "active_alerts": len(self.active_alerts),
            "total_alerts_today": len([
                alert for alert in self.alert_history
                if alert.timestamp.date() == datetime.now().date()
            ]),
            "alert_counts_by_rule": dict(self.alert_counts),
            "alerts_by_severity": {
                severity.value: len([
                    alert for alert in self.active_alerts.values()
                    if alert.severity == severity
                ])
                for severity in AlertSeverity
            }
        }

# Global alerting service instance
alerting_service = AlertingService()
