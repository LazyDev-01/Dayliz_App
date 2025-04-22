/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Dayliz';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';
  static const String appCopyright = '© 2023 Dayliz. All rights reserved.';

  // Shared preferences keys
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String isLoggedInKey = 'is_logged_in';
  static const String isDarkModeKey = 'is_dark_mode';
  static const String languageCodeKey = 'language_code';
  static const String cartItemsKey = 'cart_items';
  static const String wishlistItemsKey = 'wishlist_items';
  static const String lastSyncTimeKey = 'last_sync_time';

  // Navigation routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String homeRoute = '/home';
  static const String productDetailsRoute = '/product-details';
  static const String cartRoute = '/cart';
  static const String checkoutRoute = '/checkout';
  static const String orderConfirmationRoute = '/order-confirmation';
  static const String profileRoute = '/profile';
  static const String editProfileRoute = '/edit-profile';
  static const String addressesRoute = '/addresses';
  static const String addAddressRoute = '/add-address';
  static const String orderHistoryRoute = '/order-history';
  static const String orderDetailsRoute = '/order-details';
  static const String wishlistRoute = '/wishlist';
  static const String categoriesRoute = '/categories';
  static const String categoryProductsRoute = '/category-products';
  static const String searchRoute = '/search';
  static const String notificationsRoute = '/notifications';
  static const String settingsRoute = '/settings';
  static const String aboutRoute = '/about';
  static const String helpRoute = '/help';

  // Default values
  static const int defaultPageSize = 10;
  static const int maxSearchResults = 20;
  static const int maxRecentSearches = 10;
  static const int maxRecentlyViewedProducts = 20;
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration defaultApiCacheTime = Duration(hours: 2);
  static const Duration defaultSplashDuration = Duration(seconds: 2);
  static const Duration defaultDebounceTime = Duration(milliseconds: 500);
} 