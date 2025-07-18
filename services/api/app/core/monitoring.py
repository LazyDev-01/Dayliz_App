import time
import logging
import asyncio
from typing import Dict, Any, Optional, Callable
from datetime import datetime, timedelta
from contextlib import asynccontextmanager
from dataclasses import dataclass, asdict
import psutil
import json

from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.middleware.base import RequestResponseEndpoint

@dataclass
class MetricData:
    """Data structure for metrics"""
    timestamp: datetime
    metric_name: str
    value: float
    tags: Dict[str, str]
    unit: str = "count"

@dataclass
class PerformanceMetrics:
    """Performance metrics data structure"""
    request_count: int = 0
    total_response_time: float = 0.0
    error_count: int = 0
    success_count: int = 0
    avg_response_time: float = 0.0
    min_response_time: float = float('inf')
    max_response_time: float = 0.0
    
    def add_request(self, response_time: float, is_error: bool = False):
        self.request_count += 1
        self.total_response_time += response_time
        
        if is_error:
            self.error_count += 1
        else:
            self.success_count += 1
        
        self.avg_response_time = self.total_response_time / self.request_count
        self.min_response_time = min(self.min_response_time, response_time)
        self.max_response_time = max(self.max_response_time, response_time)

class MonitoringService:
    """
    Comprehensive Backend Monitoring Service for Dayliz API
    
    Features:
    - Request/Response monitoring
    - Performance metrics tracking
    - Error rate monitoring
    - Resource usage monitoring
    - Business metrics collection
    - Alert system integration
    """
    
    def __init__(self):
        self.logger = logging.getLogger("monitoring")
        self.logger.setLevel(logging.INFO)
        
        # Metrics storage
        self.metrics: Dict[str, PerformanceMetrics] = {}
        self.custom_metrics: Dict[str, MetricData] = {}
        
        # Alert thresholds
        self.error_rate_threshold = 0.05  # 5%
        self.response_time_threshold = 2000  # 2 seconds
        self.cpu_threshold = 80  # 80%
        self.memory_threshold = 80  # 80%
        
        # Monitoring state
        self.start_time = datetime.now()
        self.last_alert_time: Dict[str, datetime] = {}
        self.alert_cooldown = timedelta(minutes=5)  # 5 minutes between alerts
        
    def record_request_metric(self, endpoint: str, method: str, response_time: float, status_code: int):
        """Record request metrics"""
        metric_key = f"{method}:{endpoint}"
        
        if metric_key not in self.metrics:
            self.metrics[metric_key] = PerformanceMetrics()
        
        is_error = status_code >= 400
        self.metrics[metric_key].add_request(response_time, is_error)
        
        # Log detailed request info
        self.logger.info(
            f"Request: {method} {endpoint} - "
            f"Status: {status_code} - "
            f"Time: {response_time:.2f}ms"
        )
        
        # Check for alerts
        self._check_performance_alerts(metric_key, response_time, is_error)
    
    def record_custom_metric(self, name: str, value: float, tags: Dict[str, str] = None, unit: str = "count"):
        """Record custom business metrics"""
        metric = MetricData(
            timestamp=datetime.now(),
            metric_name=name,
            value=value,
            tags=tags or {},
            unit=unit
        )
        
        self.custom_metrics[f"{name}_{datetime.now().isoformat()}"] = metric
        
        self.logger.info(f"Custom metric: {name} = {value} {unit}")
    
    def record_business_event(self, event_type: str, event_data: Dict[str, Any]):
        """Record business events for analytics"""
        enriched_data = {
            "timestamp": datetime.now().isoformat(),
            "event_type": event_type,
            "server_id": "api-server",
            **event_data
        }
        
        self.logger.info(f"Business event: {event_type} - {json.dumps(enriched_data)}")
        
        # Record as custom metric
        self.record_custom_metric(
            f"business_event_{event_type}",
            1,
            tags={"event_type": event_type}
        )
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get current system resource metrics"""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            metrics = {
                "cpu_percent": cpu_percent,
                "memory_percent": memory.percent,
                "memory_used_gb": memory.used / (1024**3),
                "memory_total_gb": memory.total / (1024**3),
                "disk_percent": disk.percent,
                "disk_used_gb": disk.used / (1024**3),
                "disk_total_gb": disk.total / (1024**3),
                "timestamp": datetime.now().isoformat()
            }
            
            # Check for resource alerts
            self._check_resource_alerts(cpu_percent, memory.percent)
            
            return metrics
            
        except Exception as e:
            self.logger.error(f"Failed to get system metrics: {e}")
            return {}
    
    def get_api_metrics(self) -> Dict[str, Any]:
        """Get API performance metrics summary"""
        total_requests = sum(m.request_count for m in self.metrics.values())
        total_errors = sum(m.error_count for m in self.metrics.values())
        
        if total_requests == 0:
            return {
                "total_requests": 0,
                "error_rate": 0.0,
                "avg_response_time": 0.0,
                "uptime_seconds": (datetime.now() - self.start_time).total_seconds()
            }
        
        avg_response_time = sum(m.avg_response_time for m in self.metrics.values()) / len(self.metrics)
        error_rate = total_errors / total_requests
        
        return {
            "total_requests": total_requests,
            "total_errors": total_errors,
            "error_rate": error_rate,
            "avg_response_time": avg_response_time,
            "uptime_seconds": (datetime.now() - self.start_time).total_seconds(),
            "endpoints": {
                endpoint: asdict(metrics) for endpoint, metrics in self.metrics.items()
            }
        }
    
    def get_health_status(self) -> Dict[str, Any]:
        """Get overall health status"""
        system_metrics = self.get_system_metrics()
        api_metrics = self.get_api_metrics()
        
        # Determine health status
        health_status = "healthy"
        issues = []
        
        if system_metrics.get("cpu_percent", 0) > self.cpu_threshold:
            health_status = "degraded"
            issues.append(f"High CPU usage: {system_metrics['cpu_percent']:.1f}%")
        
        if system_metrics.get("memory_percent", 0) > self.memory_threshold:
            health_status = "degraded"
            issues.append(f"High memory usage: {system_metrics['memory_percent']:.1f}%")
        
        if api_metrics.get("error_rate", 0) > self.error_rate_threshold:
            health_status = "unhealthy"
            issues.append(f"High error rate: {api_metrics['error_rate']:.2%}")
        
        if api_metrics.get("avg_response_time", 0) > self.response_time_threshold:
            health_status = "degraded"
            issues.append(f"High response time: {api_metrics['avg_response_time']:.0f}ms")
        
        return {
            "status": health_status,
            "timestamp": datetime.now().isoformat(),
            "uptime_seconds": (datetime.now() - self.start_time).total_seconds(),
            "issues": issues,
            "system_metrics": system_metrics,
            "api_metrics": api_metrics
        }
    
    def _check_performance_alerts(self, endpoint: str, response_time: float, is_error: bool):
        """Check if performance alerts should be triggered"""
        now = datetime.now()
        
        # Check response time alert
        if response_time > self.response_time_threshold:
            alert_key = f"slow_response_{endpoint}"
            if self._should_send_alert(alert_key, now):
                self._send_alert(
                    "Slow Response Time",
                    f"Endpoint {endpoint} responded in {response_time:.0f}ms (threshold: {self.response_time_threshold}ms)"
                )
        
        # Check error rate alert
        if is_error:
            metrics = self.metrics.get(endpoint)
            if metrics and metrics.request_count >= 10:  # Only check after 10 requests
                error_rate = metrics.error_count / metrics.request_count
                if error_rate > self.error_rate_threshold:
                    alert_key = f"high_error_rate_{endpoint}"
                    if self._should_send_alert(alert_key, now):
                        self._send_alert(
                            "High Error Rate",
                            f"Endpoint {endpoint} has {error_rate:.2%} error rate (threshold: {self.error_rate_threshold:.2%})"
                        )
    
    def _check_resource_alerts(self, cpu_percent: float, memory_percent: float):
        """Check if resource alerts should be triggered"""
        now = datetime.now()
        
        if cpu_percent > self.cpu_threshold:
            if self._should_send_alert("high_cpu", now):
                self._send_alert(
                    "High CPU Usage",
                    f"CPU usage is {cpu_percent:.1f}% (threshold: {self.cpu_threshold}%)"
                )
        
        if memory_percent > self.memory_threshold:
            if self._should_send_alert("high_memory", now):
                self._send_alert(
                    "High Memory Usage",
                    f"Memory usage is {memory_percent:.1f}% (threshold: {self.memory_threshold}%)"
                )
    
    def _should_send_alert(self, alert_key: str, now: datetime) -> bool:
        """Check if enough time has passed since last alert"""
        last_alert = self.last_alert_time.get(alert_key)
        if last_alert is None or now - last_alert > self.alert_cooldown:
            self.last_alert_time[alert_key] = now
            return True
        return False
    
    def _send_alert(self, title: str, message: str):
        """Send alert through alerting service"""
        self.logger.warning(f"ALERT: {title} - {message}")

        # Import here to avoid circular imports
        from app.core.alerting import alerting_service, AlertSeverity

        # Determine alert rule name and severity
        rule_name = "monitoring_alert"
        severity = AlertSeverity.MEDIUM

        if "error rate" in title.lower():
            rule_name = "high_error_rate"
            severity = AlertSeverity.HIGH
        elif "response time" in title.lower():
            rule_name = "slow_response_time"
            severity = AlertSeverity.MEDIUM
        elif "cpu" in title.lower():
            rule_name = "high_cpu_usage"
            severity = AlertSeverity.HIGH
        elif "memory" in title.lower():
            rule_name = "high_memory_usage"
            severity = AlertSeverity.HIGH

        # Trigger alert asynchronously
        asyncio.create_task(alerting_service.trigger_alert(
            rule_name=rule_name,
            title=title,
            message=message,
            source="monitoring_service",
            override_severity=severity
        ))

        # Record alert as custom metric
        self.record_custom_metric(
            "alert_triggered",
            1,
            tags={"title": title, "severity": severity.value, "rule": rule_name}
        )

# Global monitoring instance
monitoring_service = MonitoringService()

class MonitoringMiddleware(BaseHTTPMiddleware):
    """FastAPI middleware for automatic request monitoring"""
    
    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        start_time = time.time()
        
        # Extract request info
        method = request.method
        path = request.url.path
        
        try:
            # Process request
            response = await call_next(request)
            
            # Calculate response time
            response_time = (time.time() - start_time) * 1000  # Convert to milliseconds
            
            # Record metrics
            monitoring_service.record_request_metric(
                endpoint=path,
                method=method,
                response_time=response_time,
                status_code=response.status_code
            )
            
            # Add monitoring headers
            response.headers["X-Response-Time"] = f"{response_time:.2f}ms"
            response.headers["X-Request-ID"] = str(id(request))
            
            return response
            
        except Exception as e:
            # Record error
            response_time = (time.time() - start_time) * 1000
            monitoring_service.record_request_metric(
                endpoint=path,
                method=method,
                response_time=response_time,
                status_code=500
            )
            
            # Log error
            monitoring_service.logger.error(f"Request failed: {method} {path} - {str(e)}")
            
            # Re-raise exception
            raise

@asynccontextmanager
async def performance_trace(operation_name: str):
    """Context manager for tracing operation performance"""
    start_time = time.time()
    
    try:
        yield
    finally:
        duration = (time.time() - start_time) * 1000
        monitoring_service.record_custom_metric(
            f"operation_{operation_name}_duration",
            duration,
            unit="milliseconds"
        )

def track_business_metric(metric_name: str, value: float, tags: Dict[str, str] = None):
    """Decorator for tracking business metrics"""
    def decorator(func: Callable):
        async def wrapper(*args, **kwargs):
            result = await func(*args, **kwargs)
            monitoring_service.record_custom_metric(metric_name, value, tags)
            return result
        return wrapper
    return decorator
