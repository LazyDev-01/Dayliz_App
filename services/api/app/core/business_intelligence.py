import asyncio
import logging
from typing import Dict, Any, List, Optional
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import json

from app.core.monitoring import monitoring_service
from app.core.alerting import alerting_service, AlertSeverity

class MetricType(Enum):
    """Business metric types"""
    REVENUE = "revenue"
    ORDERS = "orders"
    USERS = "users"
    PERFORMANCE = "performance"
    ENGAGEMENT = "engagement"

@dataclass
class BusinessKPI:
    """Business KPI data structure"""
    name: str
    value: float
    target: float
    unit: str
    trend: str  # "up", "down", "stable"
    change_percent: float
    timestamp: datetime

class BusinessIntelligenceService:
    """
    Business Intelligence Service for Dayliz App
    
    Features:
    - Real-time business metrics calculation
    - KPI tracking and alerting
    - Performance analytics
    - Revenue and order analytics
    - User engagement metrics
    - Automated business insights
    """
    
    def __init__(self):
        self.logger = logging.getLogger("business_intelligence")
        self.logger.setLevel(logging.INFO)
        
        # KPI targets (configurable)
        self.kpi_targets = {
            "daily_orders": 100,
            "daily_revenue": 50000.0,  # ₹50,000
            "order_success_rate": 0.95,  # 95%
            "payment_success_rate": 0.98,  # 98%
            "average_order_value": 500.0,  # ₹500
            "user_retention_rate": 0.80,  # 80%
            "delivery_success_rate": 0.95,  # 95%
            "customer_satisfaction": 4.5,  # 4.5/5.0
            "app_crash_rate": 0.01,  # 1%
            "api_response_time": 500.0,  # 500ms
        }
        
        # Metric cache
        self.metric_cache: Dict[str, Any] = {}
        self.last_calculation_time: Dict[str, datetime] = {}
    
    async def calculate_daily_kpis(self, date: datetime = None) -> Dict[str, BusinessKPI]:
        """Calculate daily business KPIs"""
        try:
            target_date = date or datetime.now()
            cache_key = f"daily_kpis_{target_date.strftime('%Y-%m-%d')}"
            
            # Check cache
            if self._is_cache_valid(cache_key, minutes=5):
                return self.metric_cache[cache_key]
            
            kpis = {}
            
            # Order metrics
            order_metrics = await self._calculate_order_metrics(target_date)
            kpis.update(order_metrics)
            
            # Revenue metrics
            revenue_metrics = await self._calculate_revenue_metrics(target_date)
            kpis.update(revenue_metrics)
            
            # User metrics
            user_metrics = await self._calculate_user_metrics(target_date)
            kpis.update(user_metrics)
            
            # Performance metrics
            performance_metrics = await self._calculate_performance_metrics(target_date)
            kpis.update(performance_metrics)
            
            # Engagement metrics
            engagement_metrics = await self._calculate_engagement_metrics(target_date)
            kpis.update(engagement_metrics)
            
            # Cache results
            self.metric_cache[cache_key] = kpis
            self.last_calculation_time[cache_key] = datetime.now()
            
            # Check for KPI alerts
            await self._check_kpi_alerts(kpis)
            
            self.logger.info(f"Daily KPIs calculated for {target_date.strftime('%Y-%m-%d')}")
            
            return kpis
            
        except Exception as e:
            self.logger.error(f"Failed to calculate daily KPIs: {str(e)}")
            return {}
    
    async def _calculate_order_metrics(self, date: datetime) -> Dict[str, BusinessKPI]:
        """Calculate order-related metrics"""
        try:
            # TODO: Implement actual database queries
            # For now, using mock data
            
            # Mock order data
            total_orders = 85  # Mock value
            successful_orders = 82  # Mock value
            cancelled_orders = 3  # Mock value
            
            order_success_rate = successful_orders / total_orders if total_orders > 0 else 0
            
            # Calculate trends (mock data)
            yesterday_orders = 78  # Mock value
            order_trend = "up" if total_orders > yesterday_orders else "down"
            order_change = ((total_orders - yesterday_orders) / yesterday_orders * 100) if yesterday_orders > 0 else 0
            
            return {
                "daily_orders": BusinessKPI(
                    name="Daily Orders",
                    value=total_orders,
                    target=self.kpi_targets["daily_orders"],
                    unit="orders",
                    trend=order_trend,
                    change_percent=order_change,
                    timestamp=datetime.now()
                ),
                "order_success_rate": BusinessKPI(
                    name="Order Success Rate",
                    value=order_success_rate,
                    target=self.kpi_targets["order_success_rate"],
                    unit="percentage",
                    trend="stable",
                    change_percent=0.5,
                    timestamp=datetime.now()
                )
            }
            
        except Exception as e:
            self.logger.error(f"Failed to calculate order metrics: {str(e)}")
            return {}
    
    async def _calculate_revenue_metrics(self, date: datetime) -> Dict[str, BusinessKPI]:
        """Calculate revenue-related metrics"""
        try:
            # TODO: Implement actual database queries
            # Mock revenue data
            daily_revenue = 42500.0  # ₹42,500
            total_orders = 85
            average_order_value = daily_revenue / total_orders if total_orders > 0 else 0
            
            # Calculate trends
            yesterday_revenue = 38000.0  # Mock value
            revenue_trend = "up" if daily_revenue > yesterday_revenue else "down"
            revenue_change = ((daily_revenue - yesterday_revenue) / yesterday_revenue * 100) if yesterday_revenue > 0 else 0
            
            return {
                "daily_revenue": BusinessKPI(
                    name="Daily Revenue",
                    value=daily_revenue,
                    target=self.kpi_targets["daily_revenue"],
                    unit="INR",
                    trend=revenue_trend,
                    change_percent=revenue_change,
                    timestamp=datetime.now()
                ),
                "average_order_value": BusinessKPI(
                    name="Average Order Value",
                    value=average_order_value,
                    target=self.kpi_targets["average_order_value"],
                    unit="INR",
                    trend="up",
                    change_percent=2.3,
                    timestamp=datetime.now()
                )
            }
            
        except Exception as e:
            self.logger.error(f"Failed to calculate revenue metrics: {str(e)}")
            return {}
    
    async def _calculate_user_metrics(self, date: datetime) -> Dict[str, BusinessKPI]:
        """Calculate user-related metrics"""
        try:
            # TODO: Implement actual database queries
            # Mock user data
            daily_active_users = 245  # Mock value
            new_users = 12  # Mock value
            returning_users = 233  # Mock value
            
            user_retention_rate = returning_users / daily_active_users if daily_active_users > 0 else 0
            
            return {
                "daily_active_users": BusinessKPI(
                    name="Daily Active Users",
                    value=daily_active_users,
                    target=200,  # Target DAU
                    unit="users",
                    trend="up",
                    change_percent=8.2,
                    timestamp=datetime.now()
                ),
                "user_retention_rate": BusinessKPI(
                    name="User Retention Rate",
                    value=user_retention_rate,
                    target=self.kpi_targets["user_retention_rate"],
                    unit="percentage",
                    trend="stable",
                    change_percent=1.1,
                    timestamp=datetime.now()
                )
            }
            
        except Exception as e:
            self.logger.error(f"Failed to calculate user metrics: {str(e)}")
            return {}
    
    async def _calculate_performance_metrics(self, date: datetime) -> Dict[str, BusinessKPI]:
        """Calculate performance-related metrics"""
        try:
            # Get actual performance data from monitoring service
            api_metrics = monitoring_service.get_api_metrics()
            system_metrics = monitoring_service.get_system_metrics()
            
            avg_response_time = api_metrics.get("avg_response_time", 0)
            error_rate = api_metrics.get("error_rate", 0)
            
            # Calculate trends
            response_time_trend = "down" if avg_response_time < 600 else "up"
            error_rate_trend = "down" if error_rate < 0.02 else "up"
            
            return {
                "api_response_time": BusinessKPI(
                    name="API Response Time",
                    value=avg_response_time,
                    target=self.kpi_targets["api_response_time"],
                    unit="milliseconds",
                    trend=response_time_trend,
                    change_percent=-5.2,
                    timestamp=datetime.now()
                ),
                "error_rate": BusinessKPI(
                    name="Error Rate",
                    value=error_rate * 100,  # Convert to percentage
                    target=2.0,  # 2% target
                    unit="percentage",
                    trend=error_rate_trend,
                    change_percent=-12.5,
                    timestamp=datetime.now()
                )
            }
            
        except Exception as e:
            self.logger.error(f"Failed to calculate performance metrics: {str(e)}")
            return {}
    
    async def _calculate_engagement_metrics(self, date: datetime) -> Dict[str, BusinessKPI]:
        """Calculate engagement-related metrics"""
        try:
            # TODO: Implement actual engagement calculations
            # Mock engagement data
            avg_session_duration = 8.5  # minutes
            screens_per_session = 12.3
            feature_adoption_rate = 0.65  # 65%
            
            return {
                "avg_session_duration": BusinessKPI(
                    name="Average Session Duration",
                    value=avg_session_duration,
                    target=10.0,  # 10 minutes target
                    unit="minutes",
                    trend="up",
                    change_percent=6.2,
                    timestamp=datetime.now()
                ),
                "feature_adoption_rate": BusinessKPI(
                    name="Feature Adoption Rate",
                    value=feature_adoption_rate,
                    target=0.70,  # 70% target
                    unit="percentage",
                    trend="up",
                    change_percent=3.8,
                    timestamp=datetime.now()
                )
            }
            
        except Exception as e:
            self.logger.error(f"Failed to calculate engagement metrics: {str(e)}")
            return {}
    
    async def _check_kpi_alerts(self, kpis: Dict[str, BusinessKPI]):
        """Check KPIs against targets and trigger alerts if needed"""
        try:
            for kpi_name, kpi in kpis.items():
                # Check if KPI is significantly below target
                if kpi.value < kpi.target * 0.8:  # 20% below target
                    await alerting_service.trigger_alert(
                        rule_name=f"kpi_below_target_{kpi_name}",
                        title=f"KPI Alert: {kpi.name} Below Target",
                        message=f"{kpi.name} is {kpi.value:.2f} {kpi.unit}, which is {((kpi.target - kpi.value) / kpi.target * 100):.1f}% below target of {kpi.target:.2f} {kpi.unit}",
                        source="business_intelligence",
                        tags={"kpi": kpi_name, "metric_type": "business"},
                        override_severity=AlertSeverity.HIGH if kpi.value < kpi.target * 0.7 else AlertSeverity.MEDIUM
                    )
                
                # Check for negative trends
                if kpi.trend == "down" and abs(kpi.change_percent) > 10:  # More than 10% decline
                    await alerting_service.trigger_alert(
                        rule_name=f"kpi_declining_{kpi_name}",
                        title=f"KPI Trend Alert: {kpi.name} Declining",
                        message=f"{kpi.name} has declined by {abs(kpi.change_percent):.1f}% compared to previous period",
                        source="business_intelligence",
                        tags={"kpi": kpi_name, "metric_type": "trend"},
                        override_severity=AlertSeverity.MEDIUM
                    )
                    
        except Exception as e:
            self.logger.error(f"Failed to check KPI alerts: {str(e)}")
    
    def _is_cache_valid(self, cache_key: str, minutes: int = 5) -> bool:
        """Check if cached data is still valid"""
        if cache_key not in self.metric_cache:
            return False
        
        last_calc = self.last_calculation_time.get(cache_key)
        if not last_calc:
            return False
        
        return datetime.now() - last_calc < timedelta(minutes=minutes)
    
    async def get_business_summary(self) -> Dict[str, Any]:
        """Get comprehensive business summary"""
        try:
            kpis = await self.calculate_daily_kpis()
            
            # Calculate summary statistics
            total_kpis = len(kpis)
            kpis_on_target = sum(1 for kpi in kpis.values() if kpi.value >= kpi.target * 0.9)
            kpis_below_target = total_kpis - kpis_on_target
            
            # Calculate overall health score
            health_score = (kpis_on_target / total_kpis * 100) if total_kpis > 0 else 0
            
            return {
                "summary": {
                    "total_kpis": total_kpis,
                    "kpis_on_target": kpis_on_target,
                    "kpis_below_target": kpis_below_target,
                    "health_score": health_score,
                    "last_updated": datetime.now().isoformat()
                },
                "kpis": {name: {
                    "name": kpi.name,
                    "value": kpi.value,
                    "target": kpi.target,
                    "unit": kpi.unit,
                    "trend": kpi.trend,
                    "change_percent": kpi.change_percent,
                    "status": "on_target" if kpi.value >= kpi.target * 0.9 else "below_target"
                } for name, kpi in kpis.items()},
                "alerts": {
                    "active_business_alerts": len([
                        alert for alert in alerting_service.get_active_alerts()
                        if alert.source == "business_intelligence"
                    ])
                }
            }
            
        except Exception as e:
            self.logger.error(f"Failed to get business summary: {str(e)}")
            return {"error": "Failed to generate business summary"}

# Global business intelligence service instance
business_intelligence_service = BusinessIntelligenceService()
