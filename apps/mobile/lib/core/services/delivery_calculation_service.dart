import 'package:flutter/foundation.dart';

/// Service for calculating delivery fees and estimates with weather adaptation
class DeliveryCalculationService {
  // Delivery fee constants - Updated fee structure
  static const double _deliveryFee100to499 = 25.0;
  static const double _deliveryFee500to799 = 20.0;
  static const double _deliveryFee800to999 = 15.0;
  static const double _freeDeliveryThreshold = 999.0;
  static const double _badWeatherDeliveryFee = 30.0;

  // Delivery time constants (in minutes)
  static const int _normalDeliveryTimeMin = 15;
  static const int _normalDeliveryTimeMax = 30;
  static const int _badWeatherDeliveryTimeMin = 30;
  static const int _badWeatherDeliveryTimeMax = 45;

  /// Calculate delivery fee based on cart total and weather
  /// Note: cartTotal should be the item total only, excluding taxes and other charges
  static DeliveryFeeResult calculateDeliveryFee({
    required double cartTotal,
    required bool isBadWeather,
  }) {
    if (isBadWeather) {
      // Fixed fee for bad weather, no free delivery
      return DeliveryFeeResult(
        fee: _badWeatherDeliveryFee,
        isFree: false,
        weatherImpact: true,
        weatherMessage: 'Weather surcharge applied due to adverse conditions',
      );
    }

    // Normal weather delivery fee logic based on new brackets
    if (cartTotal >= _freeDeliveryThreshold) {
      // ₹999+ = Free delivery
      return DeliveryFeeResult(
        fee: 0.0,
        isFree: true,
        weatherImpact: false,
      );
    } else if (cartTotal >= 800) {
      // ₹800-999 = ₹15
      return DeliveryFeeResult(
        fee: _deliveryFee800to999,
        isFree: false,
        weatherImpact: false,
      );
    } else if (cartTotal >= 500) {
      // ₹500-799 = ₹20
      return DeliveryFeeResult(
        fee: _deliveryFee500to799,
        isFree: false,
        weatherImpact: false,
      );
    } else if (cartTotal >= 100) {
      // ₹100-499 = ₹25
      return DeliveryFeeResult(
        fee: _deliveryFee100to499,
        isFree: false,
        weatherImpact: false,
      );
    } else {
      // Below ₹100 = ₹25 (same as ₹100-499 bracket)
      return DeliveryFeeResult(
        fee: _deliveryFee100to499,
        isFree: false,
        weatherImpact: false,
      );
    }
  }

  /// Calculate delivery time estimate based on weather
  static DeliveryTimeResult calculateDeliveryTime({
    required bool isBadWeather,
  }) {
    if (isBadWeather) {
      return DeliveryTimeResult(
        estimateText: 'Delivery in $_badWeatherDeliveryTimeMin-$_badWeatherDeliveryTimeMax minutes (due to weather)',
        minMinutes: _badWeatherDeliveryTimeMin,
        maxMinutes: _badWeatherDeliveryTimeMax,
        weatherImpact: true,
      );
    }

    return DeliveryTimeResult(
      estimateText: 'Delivery in $_normalDeliveryTimeMin-$_normalDeliveryTimeMax minutes',
      minMinutes: _normalDeliveryTimeMin,
      maxMinutes: _normalDeliveryTimeMax,
      weatherImpact: false,
    );
  }



  /// Get current weather status (mock implementation for now)
  static Future<bool> getCurrentWeatherStatus() async {
    try {
      // TODO: Integrate with actual weather API
      // For now, return false (normal weather)
      // In production, this would call OpenWeatherMap API or similar
      
      debugPrint('DeliveryCalculationService: Checking weather status...');
      
      // Mock weather check - you can replace this with actual API call
      // For testing, you can manually return true to simulate bad weather
      return false; // Normal weather
      
    } catch (e) {
      debugPrint('DeliveryCalculationService: Weather check failed: $e');
      // Default to normal weather if API fails
      return false;
    }
  }
}

/// Result class for delivery fee calculation
class DeliveryFeeResult {
  final double fee;
  final bool isFree;
  final bool weatherImpact;
  final String? weatherMessage;

  DeliveryFeeResult({
    required this.fee,
    required this.isFree,
    required this.weatherImpact,
    this.weatherMessage,
  });

  String get displayText {
    if (isFree) return 'FREE';
    return '₹${fee.toStringAsFixed(0)}';
  }
}

/// Result class for delivery time calculation
class DeliveryTimeResult {
  final String estimateText;
  final int minMinutes;
  final int maxMinutes;
  final bool weatherImpact;

  DeliveryTimeResult({
    required this.estimateText,
    required this.minMinutes,
    required this.maxMinutes,
    required this.weatherImpact,
  });
}


