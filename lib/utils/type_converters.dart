import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';

/// Utility class for handling type conversions between different layers
/// of the application (API, database, UI).
class TypeConverters {
  // Date formatters
  static final DateFormat _isoDateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _isoDateTimeFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");
  static final NumberFormat _moneyFormat = NumberFormat.currency(
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Converts a string ID to the appropriate type
  /// All IDs are stored as strings in the app
  static String toIdString(dynamic id) {
    if (id == null) return '';
    return id.toString();
  }

  /// Converts a price value to a properly formatted double
  /// Handles both string and numeric inputs
  static double toPrice(dynamic price) {
    if (price == null) return 0.0;
    
    if (price is double) return (price * 100).round() / 100; // Round to 2 decimal places
    if (price is int) return price.toDouble();
    if (price is String) {
      try {
        return double.parse(price);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }

  /// Formats a price for display with currency symbol
  static String formatPrice(double price) {
    return _moneyFormat.format(price);
  }

  /// Converts a string date to DateTime
  static DateTime? toDateTime(dynamic date) {
    if (date == null) return null;
    
    if (date is DateTime) return date;
    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Converts a DateTime to ISO string format
  static String fromDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return dateTime.toUtc().toIso8601String();
  }

  /// Formats a DateTime for display (date only)
  static String formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _isoDateFormat.format(dateTime);
  }

  /// Formats a DateTime for display (date and time)
  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime.toLocal());
  }

  /// Converts a boolean value from various formats
  static bool toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is num) return value != 0;
    return false;
  }

  /// Safely converts a JSON map to a Dart map
  static Map<String, dynamic> toMap(dynamic json) {
    if (json == null) return {};
    if (json is Map<String, dynamic>) return json;
    if (json is String) {
      try {
        return {}; // You could add JSON parsing here if needed
      } catch (e) {
        return {};
      }
    }
    return {};
  }
}
