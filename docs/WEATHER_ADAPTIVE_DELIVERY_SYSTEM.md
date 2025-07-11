# Weather-Adaptive Delivery System
## Climate-Based Dynamic Pricing & Timing

## 🌦️ WEATHER CLASSIFICATION SYSTEM

### **Weather Conditions & Impact:**
```
☀️ NORMAL WEATHER:
├── Conditions: Clear, Partly Cloudy, Light Clouds
├── Delivery Time: 15-30 minutes (standard)
├── Delivery Fee: Standard structure (₹25/₹20/Free)
├── Operations: Normal capacity

🌧️ BAD WEATHER:
├── Conditions: Rain, Drizzle, Light Storm, Heavy Clouds
├── Delivery Time: 30-45 minutes (extended)
├── Delivery Fee: ₹30 flat rate (overrides all rules)
├── Operations: Reduced capacity, safety protocols

⛈️ EXTREME WEATHER:
├── Conditions: Heavy Storm, Cyclone, Flood, Hail
├── Delivery Time: Service suspended
├── Delivery Fee: N/A
├── Operations: Complete suspension until safe
```

## 🔧 TECHNICAL IMPLEMENTATION

### **Weather API Integration:**
```dart
class WeatherService {
  static const String API_KEY = 'your_weather_api_key';
  static const String BASE_URL = 'https://api.openweathermap.org/data/2.5';
  
  Future<WeatherData> getCurrentWeather(double lat, double lng) async {
    final response = await http.get(
      Uri.parse('$BASE_URL/weather?lat=$lat&lon=$lng&appid=$API_KEY')
    );
    return WeatherData.fromJson(json.decode(response.body));
  }
  
  WeatherCondition classifyWeather(WeatherData data) {
    // Rain conditions
    if (data.weather.any((w) => w.main.toLowerCase().contains('rain'))) {
      return data.rain?.oneHour != null && data.rain!.oneHour! > 2.5 
        ? WeatherCondition.extreme 
        : WeatherCondition.bad;
    }
    
    // Storm conditions
    if (data.weather.any((w) => w.main.toLowerCase().contains('storm'))) {
      return WeatherCondition.extreme;
    }
    
    // Wind conditions
    if (data.wind.speed > 15) { // 15 m/s = ~54 km/h
      return WeatherCondition.bad;
    }
    
    return WeatherCondition.normal;
  }
}
```

### **Dynamic Pricing Logic:**
```dart
class DeliveryPricingService {
  Future<DeliveryFeeResult> calculateDeliveryFee({
    required double orderValue,
    required String zoneId,
  }) async {
    // Get current weather for zone
    final weather = await WeatherService().getCurrentWeatherForZone(zoneId);
    final condition = WeatherService().classifyWeather(weather);
    
    switch (condition) {
      case WeatherCondition.normal:
        return _calculateNormalFee(orderValue);
      
      case WeatherCondition.bad:
        return DeliveryFeeResult(
          fee: 30.0,
          reason: 'Weather surcharge applied due to rain/storm',
          estimatedTime: '30-45 minutes',
          weatherImpact: true,
        );
      
      case WeatherCondition.extreme:
        return DeliveryFeeResult(
          fee: 0.0,
          reason: 'Service temporarily suspended due to extreme weather',
          estimatedTime: 'Service unavailable',
          serviceAvailable: false,
        );
    }
  }
  
  DeliveryFeeResult _calculateNormalFee(double orderValue) {
    if (orderValue >= 499) {
      return DeliveryFeeResult(fee: 0.0, reason: 'Free delivery');
    } else if (orderValue >= 200) {
      return DeliveryFeeResult(fee: 20.0, reason: 'Standard delivery');
    } else {
      return DeliveryFeeResult(fee: 25.0, reason: 'Standard delivery');
    }
  }
}
```

### **Database Schema:**
```sql
-- Weather monitoring table
CREATE TABLE zone_weather_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id UUID REFERENCES zones(id),
  weather_condition VARCHAR(20), -- 'normal', 'bad', 'extreme'
  weather_data JSONB, -- Raw weather API response
  delivery_fee_override DECIMAL(10,2),
  delivery_time_multiplier DECIMAL(3,2),
  service_available BOOLEAN DEFAULT true,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Weather-based delivery rules
CREATE TABLE weather_delivery_rules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  zone_id UUID REFERENCES zones(id),
  weather_condition VARCHAR(20),
  delivery_fee DECIMAL(10,2),
  delivery_time_min INTEGER, -- minimum delivery time in minutes
  delivery_time_max INTEGER, -- maximum delivery time in minutes
  service_suspended BOOLEAN DEFAULT false,
  notification_message TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default rules
INSERT INTO weather_delivery_rules (zone_id, weather_condition, delivery_fee, delivery_time_min, delivery_time_max, notification_message) VALUES
('zone_id_here', 'normal', NULL, 15, 30, 'Standard delivery timing'),
('zone_id_here', 'bad', 30.00, 30, 45, 'Weather surcharge applied due to rain/storm conditions'),
('zone_id_here', 'extreme', NULL, NULL, NULL, 'Service temporarily suspended due to extreme weather conditions');
```

## 📱 USER EXPERIENCE

### **Weather Notifications:**
```dart
class WeatherNotificationService {
  void showWeatherImpactDialog(BuildContext context, WeatherCondition condition) {
    String title, message, icon;
    
    switch (condition) {
      case WeatherCondition.bad:
        title = 'Weather Update';
        message = 'Due to current weather conditions:\n'
                 '• Delivery fee: ₹30 (flat rate)\n'
                 '• Estimated time: 30-45 minutes\n'
                 '• Our delivery partners are taking extra care for your safety';
        icon = '🌧️';
        break;
        
      case WeatherCondition.extreme:
        title = 'Service Alert';
        message = 'Service is temporarily suspended due to extreme weather conditions. '
                 'We\'ll resume delivery as soon as it\'s safe. '
                 'You can still place orders for later delivery.';
        icon = '⛈️';
        break;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [Text(icon), SizedBox(width: 8), Text(title)]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Understood'),
          ),
        ],
      ),
    );
  }
}
```

### **Checkout Screen Updates:**
```dart
class CheckoutScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DeliveryFeeResult>(
      future: DeliveryPricingService().calculateDeliveryFee(
        orderValue: cartTotal,
        zoneId: userZoneId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final deliveryInfo = snapshot.data!;
          
          return Column(
            children: [
              // Weather impact indicator
              if (deliveryInfo.weatherImpact)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.cloud, color: Colors.orange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Weather surcharge applied: ${deliveryInfo.reason}',
                          style: TextStyle(color: Colors.orange.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Delivery fee display
              ListTile(
                title: Text('Delivery Fee'),
                trailing: Text(
                  deliveryInfo.fee > 0 ? '₹${deliveryInfo.fee}' : 'FREE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: deliveryInfo.weatherImpact ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              
              // Estimated delivery time
              ListTile(
                title: Text('Estimated Delivery'),
                trailing: Text(deliveryInfo.estimatedTime),
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }
}
```

## 🔄 AUTOMATIC WEATHER MONITORING

### **Background Weather Updates:**
```dart
class WeatherMonitoringService {
  Timer? _weatherTimer;
  
  void startWeatherMonitoring() {
    // Check weather every 15 minutes
    _weatherTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      _updateWeatherForAllZones();
    });
  }
  
  Future<void> _updateWeatherForAllZones() async {
    final zones = await DatabaseService().getAllActiveZones();
    
    for (final zone in zones) {
      try {
        final weather = await WeatherService().getCurrentWeatherForZone(zone.id);
        final condition = WeatherService().classifyWeather(weather);
        
        // Update database
        await DatabaseService().updateZoneWeatherStatus(zone.id, condition, weather);
        
        // Send notifications if weather changed significantly
        await _handleWeatherChange(zone.id, condition);
        
      } catch (e) {
        print('Failed to update weather for zone ${zone.id}: $e');
      }
    }
  }
  
  Future<void> _handleWeatherChange(String zoneId, WeatherCondition newCondition) async {
    final previousCondition = await DatabaseService().getPreviousWeatherCondition(zoneId);
    
    if (previousCondition != newCondition) {
      // Notify customers with pending orders
      await NotificationService().sendWeatherUpdateToZoneCustomers(zoneId, newCondition);
      
      // Notify delivery agents
      await NotificationService().sendWeatherUpdateToAgents(zoneId, newCondition);
      
      // Update admin dashboard
      await AdminNotificationService().notifyWeatherChange(zoneId, newCondition);
    }
  }
}
```

This weather-adaptive system ensures your delivery service remains reliable and fair during all weather conditions while keeping customers informed and delivery agents safe!
