# Dayliz App Monitoring Dashboard Setup

## Overview

This document provides comprehensive setup instructions for the Dayliz App monitoring dashboard, including Firebase integration, backend monitoring, and business metrics tracking.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   FastAPI Backend │    │   Supabase DB   │
│                 │    │                  │    │                 │
│ • Crashlytics   │────│ • Monitoring API │────│ • Performance   │
│ • Performance   │    │ • Health Checks  │    │ • Query Metrics │
│ • Business      │    │ • Alert System   │    │ • Connection    │
│   Metrics       │    │ • Resource Usage │    │   Monitoring    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                        │                        │
         └────────────────────────┼────────────────────────┘
                                  │
                    ┌─────────────────────────┐
                    │   Monitoring Dashboard  │
                    │                         │
                    │ • Real-time Metrics     │
                    │ • Alert Management      │
                    │ • Performance Analytics │
                    │ • Business Intelligence │
                    └─────────────────────────┘
```

## 1. Firebase Setup

### 1.1 Firebase Project Configuration

1. **Create Firebase Project** (if not already created):
   ```bash
   # Visit https://console.firebase.google.com/
   # Create new project: "dayliz-monitoring"
   ```

2. **Enable Required Services**:
   - Firebase Crashlytics
   - Firebase Performance Monitoring
   - Firebase Analytics
   - Firebase Cloud Messaging (for alerts)

3. **Download Configuration Files**:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS

### 1.2 Flutter Integration

1. **Add Dependencies** to `pubspec.yaml`:
   ```yaml
   dependencies:
     firebase_core: ^2.24.2
     firebase_crashlytics: ^3.4.8
     firebase_performance: ^0.9.3+8
     firebase_analytics: ^10.7.4
     connectivity_plus: ^5.0.2
     device_info_plus: ^9.1.1
     package_info_plus: ^4.2.0
   ```

2. **Initialize Firebase** in `main.dart`:
   ```dart
   import 'package:firebase_core/firebase_core.dart';
   import 'core/services/app_monitoring_integration.dart';
   
   void main() async {
     WidgetsFlutterBinding.ensureInitialized();
     
     // Initialize Firebase
     await Firebase.initializeApp();
     
     // Initialize monitoring
     await AppMonitoringIntegration().initialize();
     
     runApp(MyApp());
   }
   ```

3. **Configure Crashlytics** in build files:
   
   **Android** (`android/app/build.gradle`):
   ```gradle
   plugins {
     id 'com.google.gms.google-services'
     id 'com.google.firebase.crashlytics'
   }
   ```
   
   **iOS** (`ios/Runner.xcodeproj`):
   - Add Firebase SDK
   - Configure build phases for Crashlytics

## 2. Backend Monitoring Setup

### 2.1 FastAPI Monitoring Integration

1. **Install Dependencies**:
   ```bash
   pip install psutil
   pip install prometheus-client  # Optional for Prometheus integration
   ```

2. **Environment Variables** (`.env`):
   ```env
   # Monitoring Configuration
   MONITORING_ENABLED=true
   
   # Alert Configuration
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   SMTP_USERNAME=alerts@dayliz.com
   SMTP_PASSWORD=your_app_password
   ALERT_FROM_EMAIL=alerts@dayliz.com
   ALERT_TO_EMAIL=admin@dayliz.com
   
   # Slack Integration
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK
   
   # Alert Thresholds
   ERROR_RATE_THRESHOLD=0.05
   RESPONSE_TIME_THRESHOLD=2000
   CPU_THRESHOLD=80
   MEMORY_THRESHOLD=80
   ```

3. **Start Monitoring** with the application:
   ```python
   # In main.py startup event
   @app.on_event("startup")
   async def startup_event():
       # Initialize monitoring
       monitoring_service.logger.info("Monitoring service started")
   ```

### 2.2 Monitoring Endpoints

The following endpoints are available for monitoring:

- **Health Check**: `GET /api/v1/monitoring/health`
- **Detailed Health**: `GET /api/v1/monitoring/health/detailed`
- **API Metrics**: `GET /api/v1/monitoring/metrics/api`
- **System Metrics**: `GET /api/v1/monitoring/metrics/system`
- **Business Metrics**: `GET /api/v1/monitoring/metrics/business`
- **Dashboard**: `GET /api/v1/monitoring/dashboard`

## 3. Database Monitoring

### 3.1 Supabase Monitoring

1. **Enable Supabase Monitoring**:
   - Go to Supabase Dashboard
   - Navigate to Settings → Monitoring
   - Enable performance insights

2. **Custom Database Metrics**:
   ```sql
   -- Create monitoring views
   CREATE VIEW api_performance_summary AS
   SELECT 
     DATE_TRUNC('hour', created_at) as hour,
     COUNT(*) as request_count,
     AVG(response_time_ms) as avg_response_time,
     COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_count
   FROM api_logs 
   GROUP BY hour
   ORDER BY hour DESC;
   ```

### 3.2 Connection Pool Monitoring

Monitor database connection health:
```python
# In monitoring service
async def check_database_health():
    try:
        # Test database connection
        result = await supabase_client.from_("health_check").select("1").limit(1).execute()
        return {"status": "healthy", "response_time": "..."}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}
```

## 4. Business Metrics Configuration

### 4.1 Key Performance Indicators (KPIs)

Track these critical business metrics:

1. **Order Funnel Metrics**:
   - Cart creation rate
   - Checkout initiation rate
   - Payment completion rate
   - Order fulfillment rate

2. **User Engagement Metrics**:
   - Daily/Monthly Active Users
   - Session duration
   - Screen view frequency
   - Feature adoption rates

3. **Revenue Metrics**:
   - Average Order Value (AOV)
   - Revenue per user
   - Payment method distribution
   - Refund rates

4. **Operational Metrics**:
   - Delivery success rate
   - Average delivery time
   - Customer satisfaction scores
   - Support ticket volume

### 4.2 Custom Event Tracking

Implement custom event tracking throughout the app:

```dart
// Example: Track order completion
await BusinessMetricsService().trackOrderLifecycle('completed',
  orderId: order.id,
  orderValue: order.totalAmount,
  paymentMethod: order.paymentMethod,
  itemCount: order.items.length,
);

// Example: Track user engagement
await BusinessMetricsService().trackEngagementEvent('feature_used',
  feature: 'product_search',
  duration: searchDuration,
  outcome: 'success',
);
```

## 5. Alert Configuration

### 5.1 Alert Rules

Configure alerts for critical issues:

```python
# High-priority alerts
CRITICAL_ALERTS = {
    "payment_failure_spike": {
        "threshold": 0.10,  # 10% failure rate
        "channels": ["email", "slack", "sms"],
        "cooldown": 2  # minutes
    },
    "database_connection_failure": {
        "threshold": 5,  # 5 consecutive failures
        "channels": ["email", "slack", "sms"],
        "cooldown": 1  # minute
    }
}

# Medium-priority alerts
MEDIUM_ALERTS = {
    "high_response_time": {
        "threshold": 2000,  # 2 seconds
        "channels": ["email", "slack"],
        "cooldown": 10  # minutes
    },
    "high_error_rate": {
        "threshold": 0.05,  # 5% error rate
        "channels": ["email", "slack"],
        "cooldown": 5  # minutes
    }
}
```

### 5.2 Alert Channels Setup

1. **Email Alerts**:
   - Configure SMTP settings
   - Set up email templates
   - Define recipient lists

2. **Slack Integration**:
   - Create Slack webhook
   - Configure channel routing
   - Set up alert formatting

3. **SMS Alerts** (for critical issues):
   - Integrate with Twilio or AWS SNS
   - Configure emergency contact list
   - Set up escalation procedures

## 6. Dashboard Visualization

### 6.1 Real-time Dashboard

Create a real-time monitoring dashboard with:

1. **System Health Overview**:
   - Service status indicators
   - Response time graphs
   - Error rate trends
   - Resource utilization

2. **Business Metrics**:
   - Order volume trends
   - Revenue metrics
   - User engagement stats
   - Conversion funnel

3. **Alert Management**:
   - Active alerts list
   - Alert history
   - Acknowledgment status
   - Resolution tracking

### 6.2 Dashboard Access

```bash
# Access monitoring dashboard
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:8000/api/v1/monitoring/dashboard
```

## 7. Production Deployment

### 7.1 Environment-Specific Configuration

1. **Development Environment**:
   - Reduced alert thresholds
   - Console logging enabled
   - Debug metrics collection

2. **Staging Environment**:
   - Production-like monitoring
   - Test alert channels
   - Performance baseline establishment

3. **Production Environment**:
   - Full monitoring enabled
   - All alert channels active
   - Optimized metric collection

### 7.2 Monitoring Checklist

Before production deployment:

- [ ] Firebase services configured and tested
- [ ] Backend monitoring endpoints functional
- [ ] Database monitoring enabled
- [ ] Alert rules configured and tested
- [ ] Dashboard accessible and displaying data
- [ ] Alert channels tested (email, Slack, SMS)
- [ ] Performance baselines established
- [ ] Escalation procedures documented
- [ ] Monitoring documentation complete

## 8. Maintenance and Optimization

### 8.1 Regular Monitoring Tasks

1. **Daily**:
   - Review alert summary
   - Check system health dashboard
   - Monitor key business metrics

2. **Weekly**:
   - Analyze performance trends
   - Review alert effectiveness
   - Update monitoring thresholds

3. **Monthly**:
   - Performance optimization review
   - Monitoring system health check
   - Alert rule refinement

### 8.2 Monitoring Best Practices

1. **Metric Collection**:
   - Collect only actionable metrics
   - Avoid metric explosion
   - Use appropriate sampling rates

2. **Alert Management**:
   - Minimize false positives
   - Ensure alerts are actionable
   - Implement proper escalation

3. **Performance**:
   - Monitor the monitoring system
   - Optimize metric storage
   - Regular cleanup of old data

## 9. Troubleshooting

### 9.1 Common Issues

1. **Firebase Not Initializing**:
   - Check configuration files
   - Verify project settings
   - Review console errors

2. **Monitoring Endpoints Not Responding**:
   - Check service health
   - Verify authentication
   - Review server logs

3. **Alerts Not Firing**:
   - Verify alert rules
   - Check threshold values
   - Test alert channels

### 9.2 Debug Commands

```bash
# Check monitoring service health
curl http://localhost:8000/api/v1/monitoring/health

# View system metrics
curl -H "Authorization: Bearer TOKEN" \
     http://localhost:8000/api/v1/monitoring/metrics/system

# Test alert system
curl -X POST -H "Authorization: Bearer TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"event_type": "test_alert", "message": "Test alert"}' \
     http://localhost:8000/api/v1/monitoring/events/business
```

---

**Document Version**: 1.0  
**Last Updated**: January 21, 2025  
**Next Review**: February 21, 2025
