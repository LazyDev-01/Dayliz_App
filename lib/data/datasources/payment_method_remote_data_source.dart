import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/payment_method_model.dart';
import '../../core/error/exceptions.dart';

abstract class PaymentMethodRemoteDataSource {
  /// Gets all payment methods for a user
  /// Throws a [ServerException] for all error codes
  Future<List<PaymentMethodModel>> getPaymentMethods(String userId);

  /// Gets a specific payment method by ID
  /// Throws a [ServerException] for all error codes
  Future<PaymentMethodModel> getPaymentMethod(String id);

  /// Gets the default payment method for a user
  /// Throws a [ServerException] for all error codes
  Future<PaymentMethodModel?> getDefaultPaymentMethod(String userId);

  /// Adds a new payment method
  /// Throws a [ServerException] for all error codes
  Future<PaymentMethodModel> addPaymentMethod(PaymentMethodModel paymentMethod);

  /// Updates an existing payment method
  /// Throws a [ServerException] for all error codes
  Future<PaymentMethodModel> updatePaymentMethod(PaymentMethodModel paymentMethod);

  /// Deletes a payment method
  /// Throws a [ServerException] for all error codes
  Future<bool> deletePaymentMethod(String id);

  /// Sets a payment method as default
  /// Throws a [ServerException] for all error codes
  /// Returns the updated payment method
  Future<PaymentMethodModel> setDefaultPaymentMethod(String id, String userId);
}

class PaymentMethodRemoteDataSourceImpl implements PaymentMethodRemoteDataSource {
  final http.Client client;
  final String baseUrl;

  PaymentMethodRemoteDataSourceImpl({
    required this.client,
    required this.baseUrl,
  });

  @override
  Future<List<PaymentMethodModel>> getPaymentMethods(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/payment_methods?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> paymentMethodsJson = json.decode(response.body);
      return paymentMethodsJson
          .map((json) => PaymentMethodModel.fromJson(json))
          .toList();
    } else {
      throw ServerException(message: 'Failed to load payment methods');
    }
  }

  @override
  Future<PaymentMethodModel> getPaymentMethod(String id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/payment_methods/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return PaymentMethodModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException(message: 'Failed to load payment method');
    }
  }

  @override
  Future<PaymentMethodModel?> getDefaultPaymentMethod(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/payment_methods?user_id=$userId&is_default=true'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> paymentMethodsJson = json.decode(response.body);
      if (paymentMethodsJson.isEmpty) {
        return null;
      }
      return PaymentMethodModel.fromJson(paymentMethodsJson.first);
    } else {
      throw ServerException(message: 'Failed to load default payment method');
    }
  }

  @override
  Future<PaymentMethodModel> addPaymentMethod(PaymentMethodModel paymentMethod) async {
    final response = await client.post(
      Uri.parse('$baseUrl/payment_methods'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(paymentMethod.toJson()),
    );

    if (response.statusCode == 201) {
      return PaymentMethodModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException(message: 'Failed to add payment method');
    }
  }

  @override
  Future<PaymentMethodModel> updatePaymentMethod(PaymentMethodModel paymentMethod) async {
    final response = await client.put(
      Uri.parse('$baseUrl/payment_methods/${paymentMethod.id}'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(paymentMethod.toJson()),
    );

    if (response.statusCode == 200) {
      return PaymentMethodModel.fromJson(json.decode(response.body));
    } else {
      throw ServerException(message: 'Failed to update payment method');
    }
  }

  @override
  Future<bool> deletePaymentMethod(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/payment_methods/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 204) {
      return true;
    } else {
      throw ServerException(message: 'Failed to delete payment method');
    }
  }

  @override
  Future<PaymentMethodModel> setDefaultPaymentMethod(String id, String userId) async {
    // First, update all payment methods to not be default
    final resetResponse = await client.put(
      Uri.parse('$baseUrl/payment_methods/reset_default?user_id=$userId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (resetResponse.statusCode != 200) {
      throw ServerException(message: 'Failed to reset default payment methods');
    }

    // Then set the specified payment method as default
    final response = await client.put(
      Uri.parse('$baseUrl/payment_methods/$id/set_default'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      // Return the updated payment method
      return getPaymentMethod(id);
    } else {
      throw ServerException(message: 'Failed to set default payment method');
    }
  }
} 