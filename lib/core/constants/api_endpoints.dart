/// Constants for API endpoints
class ApiEndpoints {
  /// Base URL for the API
  static const String baseUrl = 'https://api.dayliz.com/v1';

  /// Endpoint for categories
  static const String categories = '/categories';

  /// Endpoint for subcategories 
  static const String subcategories = '/subcategories';

  /// Endpoint for categories with subcategories
  static const String categoriesWithSubcategories = '/categories/with-subcategories';

  /// Endpoint for products
  static const String products = '/products';

  /// Endpoint for cart
  static const String cart = '/cart';

  /// Endpoint for users
  static const String users = '/users';

  /// Endpoint for authentication
  static const String auth = '/auth';

  /// Login endpoint
  static const String login = '/auth/login';

  /// Register endpoint
  static const String register = '/auth/register';

  /// Forgot password endpoint
  static const String forgotPassword = '/auth/forgot-password';
} 