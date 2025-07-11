from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import logging

from app.core.monitoring import monitoring_service
from app.api.v1.auth import get_current_user
from app.schemas.user import User

router = APIRouter()

# Configure logging for monitoring endpoints
monitor_logger = logging.getLogger("monitoring_api")
monitor_logger.setLevel(logging.INFO)

@router.get("/health")
async def health_check():
    """
    Public health check endpoint
    
    Returns basic health status without sensitive information
    """
    try:
        health_status = monitoring_service.get_health_status()
        
        # Return simplified health status for public consumption
        return {
            "status": health_status["status"],
            "timestamp": health_status["timestamp"],
            "uptime_seconds": health_status["uptime_seconds"],
            "message": "Dayliz API is running" if health_status["status"] == "healthy" else "Service experiencing issues"
        }
        
    except Exception as e:
        monitor_logger.error(f"Health check failed: {str(e)}")
        return {
            "status": "unhealthy",
            "timestamp": datetime.now().isoformat(),
            "message": "Health check failed"
        }

@router.get("/health/detailed")
async def detailed_health_check(current_user: User = Depends(get_current_user)):
    """
    Detailed health check with full metrics (admin access required)
    """
    try:
        # TODO: Add admin role check
        # For now, allow all authenticated users
        
        health_status = monitoring_service.get_health_status()
        
        monitor_logger.info(f"Detailed health check accessed by user: {current_user.id}")
        
        return health_status
        
    except Exception as e:
        monitor_logger.error(f"Detailed health check failed: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve health status"
        )

@router.get("/metrics/api")
async def get_api_metrics(current_user: User = Depends(get_current_user)):
    """
    Get API performance metrics
    """
    try:
        api_metrics = monitoring_service.get_api_metrics()
        
        monitor_logger.info(f"API metrics accessed by user: {current_user.id}")
        
        return {
            "success": True,
            "data": api_metrics,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        monitor_logger.error(f"Failed to get API metrics: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve API metrics"
        )

@router.get("/metrics/system")
async def get_system_metrics(current_user: User = Depends(get_current_user)):
    """
    Get system resource metrics
    """
    try:
        system_metrics = monitoring_service.get_system_metrics()
        
        monitor_logger.info(f"System metrics accessed by user: {current_user.id}")
        
        return {
            "success": True,
            "data": system_metrics,
            "timestamp": datetime.now().isoformat()
        }
        
    except Exception as e:
        monitor_logger.error(f"Failed to get system metrics: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve system metrics"
        )

@router.get("/metrics/business")
async def get_business_metrics(
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    metric_type: Optional[str] = None,
    current_user: User = Depends(get_current_user)
):
    """
    Get business metrics with optional filtering
    """
    try:
        # TODO: Add admin role check for business metrics
        
        # Parse date filters
        start_datetime = None
        end_datetime = None
        
        if start_date:
            try:
                start_datetime = datetime.fromisoformat(start_date)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid start_date format. Use ISO format (YYYY-MM-DDTHH:MM:SS)"
                )
        
        if end_date:
            try:
                end_datetime = datetime.fromisoformat(end_date)
            except ValueError:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid end_date format. Use ISO format (YYYY-MM-DDTHH:MM:SS)"
                )
        
        # Filter custom metrics
        filtered_metrics = {}
        for key, metric in monitoring_service.custom_metrics.items():
            # Apply date filter
            if start_datetime and metric.timestamp < start_datetime:
                continue
            if end_datetime and metric.timestamp > end_datetime:
                continue
            
            # Apply metric type filter
            if metric_type and metric_type not in metric.metric_name:
                continue
            
            filtered_metrics[key] = {
                "timestamp": metric.timestamp.isoformat(),
                "metric_name": metric.metric_name,
                "value": metric.value,
                "tags": metric.tags,
                "unit": metric.unit
            }
        
        monitor_logger.info(f"Business metrics accessed by user: {current_user.id}")
        
        return {
            "success": True,
            "data": {
                "metrics": filtered_metrics,
                "count": len(filtered_metrics),
                "filters": {
                    "start_date": start_date,
                    "end_date": end_date,
                    "metric_type": metric_type
                }
            },
            "timestamp": datetime.now().isoformat()
        }
        
    except HTTPException:
        raise
    except Exception as e:
        monitor_logger.error(f"Failed to get business metrics: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve business metrics"
        )

@router.post("/metrics/custom")
async def record_custom_metric(
    metric_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """
    Record a custom metric
    """
    try:
        # Validate required fields
        required_fields = ["name", "value"]
        for field in required_fields:
            if field not in metric_data:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail=f"Missing required field: {field}"
                )
        
        # Extract metric data
        name = metric_data["name"]
        value = float(metric_data["value"])
        tags = metric_data.get("tags", {})
        unit = metric_data.get("unit", "count")
        
        # Add user context to tags
        tags["user_id"] = current_user.id
        tags["recorded_by"] = "api"
        
        # Record the metric
        monitoring_service.record_custom_metric(name, value, tags, unit)
        
        monitor_logger.info(f"Custom metric recorded by user {current_user.id}: {name} = {value}")
        
        return {
            "success": True,
            "message": "Custom metric recorded successfully",
            "metric": {
                "name": name,
                "value": value,
                "tags": tags,
                "unit": unit
            },
            "timestamp": datetime.now().isoformat()
        }
        
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid metric value: {str(e)}"
        )
    except HTTPException:
        raise
    except Exception as e:
        monitor_logger.error(f"Failed to record custom metric: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to record custom metric"
        )

@router.post("/events/business")
async def record_business_event(
    event_data: Dict[str, Any],
    current_user: User = Depends(get_current_user)
):
    """
    Record a business event for analytics
    """
    try:
        # Validate required fields
        if "event_type" not in event_data:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Missing required field: event_type"
            )
        
        event_type = event_data["event_type"]
        
        # Add user context
        enriched_event_data = {
            **event_data,
            "user_id": current_user.id,
            "recorded_by": "api",
            "api_timestamp": datetime.now().isoformat()
        }
        
        # Record the business event
        monitoring_service.record_business_event(event_type, enriched_event_data)
        
        monitor_logger.info(f"Business event recorded by user {current_user.id}: {event_type}")
        
        return {
            "success": True,
            "message": "Business event recorded successfully",
            "event": {
                "event_type": event_type,
                "timestamp": datetime.now().isoformat()
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        monitor_logger.error(f"Failed to record business event: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to record business event"
        )

@router.get("/alerts/status")
async def get_alert_status(current_user: User = Depends(get_current_user)):
    """
    Get current alert status and recent alerts
    """
    try:
        # TODO: Implement alert history storage and retrieval
        # For now, return basic alert configuration
        
        alert_config = {
            "error_rate_threshold": monitoring_service.error_rate_threshold,
            "response_time_threshold": monitoring_service.response_time_threshold,
            "cpu_threshold": monitoring_service.cpu_threshold,
            "memory_threshold": monitoring_service.memory_threshold,
            "alert_cooldown_minutes": monitoring_service.alert_cooldown.total_seconds() / 60
        }
        
        # Get current health status to check for active issues
        health_status = monitoring_service.get_health_status()
        
        return {
            "success": True,
            "data": {
                "alert_config": alert_config,
                "current_issues": health_status.get("issues", []),
                "last_check": datetime.now().isoformat()
            }
        }
        
    except Exception as e:
        monitor_logger.error(f"Failed to get alert status: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve alert status"
        )

@router.get("/dashboard")
async def get_monitoring_dashboard(current_user: User = Depends(get_current_user)):
    """
    Get comprehensive monitoring dashboard data
    """
    try:
        # Get all monitoring data
        health_status = monitoring_service.get_health_status()
        api_metrics = monitoring_service.get_api_metrics()
        system_metrics = monitoring_service.get_system_metrics()
        
        # Calculate additional dashboard metrics
        uptime_hours = health_status["uptime_seconds"] / 3600
        
        # Get recent business metrics (last 24 hours)
        recent_business_metrics = {}
        cutoff_time = datetime.now() - timedelta(hours=24)
        
        for key, metric in monitoring_service.custom_metrics.items():
            if metric.timestamp >= cutoff_time:
                metric_type = metric.metric_name.split('_')[0]
                if metric_type not in recent_business_metrics:
                    recent_business_metrics[metric_type] = 0
                recent_business_metrics[metric_type] += metric.value
        
        dashboard_data = {
            "overview": {
                "status": health_status["status"],
                "uptime_hours": round(uptime_hours, 2),
                "total_requests": api_metrics["total_requests"],
                "error_rate": api_metrics["error_rate"],
                "avg_response_time": api_metrics["avg_response_time"]
            },
            "system": {
                "cpu_percent": system_metrics.get("cpu_percent", 0),
                "memory_percent": system_metrics.get("memory_percent", 0),
                "disk_percent": system_metrics.get("disk_percent", 0)
            },
            "business_metrics_24h": recent_business_metrics,
            "issues": health_status.get("issues", []),
            "last_updated": datetime.now().isoformat()
        }
        
        monitor_logger.info(f"Monitoring dashboard accessed by user: {current_user.id}")
        
        return {
            "success": True,
            "data": dashboard_data
        }
        
    except Exception as e:
        monitor_logger.error(f"Failed to get monitoring dashboard: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to retrieve monitoring dashboard"
        )
