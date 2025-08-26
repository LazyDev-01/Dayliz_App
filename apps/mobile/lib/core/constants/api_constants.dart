/// API Constants for the application
class ApiConstants {
  ApiConstants._();

  // Base URLs - Use environment variable or fallback to localhost for development
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );
  static const String apiVersion = '/api/v1';
  static const String baseApiUrl = '$baseUrl$apiVersion';

  // Timeouts
  static const int connectionTimeout = 15000; // 15 seconds
  static const int receiveTimeout = 15000; // 15 seconds

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';

  // User endpoints
  static const String userProfileEndpoint = '/user/profile';
  static const String updateProfileEndpoint = '/user/profile/update';
  static const String changePasswordEndpoint = '/user/change-password';

  // Product endpoints
  static const String productsEndpoint = '/products';
  static const String productDetailsEndpoint = '/products/'; // Append product ID
  static const String featuredProductsEndpoint = '/products/featured';
  static const String searchProductsEndpoint = '/products/search';
  static const String categoriesEndpoint = '/categories';
  static const String categoryProductsEndpoint = '/categories/'; // Append category ID

  // Cart and order endpoints
  static const String cartEndpoint = '/cart';
  static const String addToCartEndpoint = '/cart/add';
  static const String removeFromCartEndpoint = '/cart/remove';
  static const String updateCartEndpoint = '/cart/update';
  static const String checkoutEndpoint = '/checkout';
  static const String ordersEndpoint = '/orders';
  static const String orderDetailsEndpoint = '/orders/'; // Append order ID

  // Wishlist endpoints
  static const String wishlistEndpoint = '/wishlist';
  static const String addToWishlistEndpoint = '/wishlist/add';
  static const String removeFromWishlistEndpoint = '/wishlist/remove';

  // Reviews endpoints
  static const String reviewsEndpoint = '/reviews';
  static const String addReviewEndpoint = '/reviews/add';

  // Address endpoints
  static const String addressesEndpoint = '/addresses';
  static const String addAddressEndpoint = '/addresses/add';
  static const String updateAddressEndpoint = '/addresses/update';
  static const String deleteAddressEndpoint = '/addresses/delete';

  // Payment endpoints
  static const String paymentMethodsEndpoint = '/payment-methods';
  static const String addPaymentMethodEndpoint = '/payment-methods/add';

  // Payment processing endpoints
  static const String createOrderWithPaymentEndpoint = '/payments/create-order-with-payment';
  static const String verifyPaymentEndpoint = '/payments/razorpay/verify';
  static const String paymentStatusEndpoint = '/payments/status';
  static const String retryPaymentEndpoint = '/payments/retry';
  static const String razorpayWebhookEndpoint = '/payments/webhook/razorpay';
} 