/// Class that holds all API constants for the app
class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.dayliz.com/v1';
  
  // API Key
  static const String apiKey = 'dayliz_api_key';
  
  // Endpoints
  static const String authEndpoint = '/auth';
  static const String productsEndpoint = '/products';
  static const String categoriesEndpoint = '/categories';
  static const String cartEndpoint = '/cart';
  static const String ordersEndpoint = '/orders';
  static const String usersEndpoint = '/users';
  static const String addressesEndpoint = '/addresses';
  static const String wishlistEndpoint = '/wishlist';
  
  // Auth endpoints
  static const String loginEndpoint = '$authEndpoint/login';
  static const String registerEndpoint = '$authEndpoint/register';
  static const String forgotPasswordEndpoint = '$authEndpoint/forgot-password';
  static const String resetPasswordEndpoint = '$authEndpoint/reset-password';
  static const String verifyEmailEndpoint = '$authEndpoint/verify-email';
} 