import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_method_model.dart';
import '../../core/error/exceptions.dart';

abstract class PaymentMethodLocalDataSource {
  /// Gets all cached payment methods for a user
  /// Throws a [CacheException] if no cached data is present
  Future<List<PaymentMethodModel>> getPaymentMethods(String userId);

  /// Gets a specific cached payment method by ID
  /// Throws a [CacheException] if no cached data is present
  Future<PaymentMethodModel> getPaymentMethod(String id);

  /// Gets the default payment method for a user
  /// Throws a [CacheException] if no cached data is present
  Future<PaymentMethodModel> getDefaultPaymentMethod(String userId);

  /// Caches payment methods
  Future<void> cachePaymentMethods(String userId, List<PaymentMethodModel> paymentMethods);

  /// Caches a single payment method
  Future<void> cachePaymentMethod(PaymentMethodModel paymentMethod);

  /// Removes a payment method from cache
  Future<void> removePaymentMethod(String id);
}

class PaymentMethodLocalDataSourceImpl implements PaymentMethodLocalDataSource {
  final SharedPreferences sharedPreferences;

  PaymentMethodLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
    final jsonString = sharedPreferences.getString('CACHED_PAYMENT_METHODS_$userId');
    if (jsonString != null) {
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((e) => PaymentMethodModel.fromJson(e)).toList();
    } else {
      throw CacheException(message: 'No cached payment methods found');
    }
  }

  @override
  Future<PaymentMethodModel> getPaymentMethod(String id) async {
    // Since payment methods are stored by user ID, we need to search all
    // cached payment methods to find the one with the matching ID
    final allKeys = sharedPreferences.getKeys().where(
          (key) => key.startsWith('CACHED_PAYMENT_METHODS_'),
        );

    for (final key in allKeys) {
      final jsonString = sharedPreferences.getString(key);
      if (jsonString != null) {
        final List<dynamic> jsonData = json.decode(jsonString);
        final paymentMethods = jsonData.map((e) => PaymentMethodModel.fromJson(e)).toList();
        
        final paymentMethod = paymentMethods.firstWhere(
          (method) => method.id == id,
          orElse: () => throw CacheException(message: 'Payment method not found in cache'),
        );
        
        return paymentMethod;
      }
    }
    
    throw CacheException(message: 'Payment method not found in cache');
  }

  @override
  Future<PaymentMethodModel> getDefaultPaymentMethod(String userId) async {
    try {
      final paymentMethods = await getPaymentMethods(userId);
      final defaultPaymentMethod = paymentMethods.firstWhere(
        (method) => method.isDefault,
        orElse: () => throw CacheException(message: 'No default payment method found in cache'),
      );
      return defaultPaymentMethod;
    } catch (e) {
      throw CacheException(message: 'No default payment method found in cache');
    }
  }

  @override
  Future<void> cachePaymentMethods(String userId, List<PaymentMethodModel> paymentMethods) async {
    final List<Map<String, dynamic>> jsonData = paymentMethods.map((e) => e.toJson()).toList();
    await sharedPreferences.setString(
      'CACHED_PAYMENT_METHODS_$userId',
      json.encode(jsonData),
    );
  }

  @override
  Future<void> cachePaymentMethod(PaymentMethodModel paymentMethod) async {
    try {
      final paymentMethods = await getPaymentMethods(paymentMethod.userId);
      final existingIndex = paymentMethods.indexWhere((p) => p.id == paymentMethod.id);
      
      if (existingIndex != -1) {
        // Replace existing payment method
        paymentMethods[existingIndex] = paymentMethod;
      } else {
        // Add new payment method
        paymentMethods.add(paymentMethod);
      }
      
      await cachePaymentMethods(paymentMethod.userId, paymentMethods);
    } catch (e) {
      // If no payment methods exist yet for this user, create a new list
      await cachePaymentMethods(paymentMethod.userId, [paymentMethod]);
    }
  }

  @override
  Future<void> removePaymentMethod(String id) async {
    try {
      final paymentMethod = await getPaymentMethod(id);
      final paymentMethods = await getPaymentMethods(paymentMethod.userId);
      
      paymentMethods.removeWhere((p) => p.id == id);
      await cachePaymentMethods(paymentMethod.userId, paymentMethods);
    } catch (e) {
      // If the payment method doesn't exist, do nothing
    }
  }
} 