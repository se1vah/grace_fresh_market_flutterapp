/// Centralized Environment Configuration & Common Data Variables.
///
/// Supports compile-time environment variable overrides via `--dart-define`:
/// E.g.: `flutter run --dart-define=SERVER_HOST=http://192.168.1.100:3000 --dart-define=ENV=production`
class EnvConfig {
  EnvConfig._();

  /// Server Host IP / Domain Base URL
  static const String serverHost = String.fromEnvironment(
    'SERVER_HOST',
    defaultValue: 'https://grace-fresh-market-eta.vercel.app',
  );

  /// Shop API Endpoint Path
  static const String shopApiEndpoint = String.fromEnvironment(
    'SHOP_API_ENDPOINT',
    defaultValue: '/api/shop',
  );

  /// User API Endpoint Path
  static const String userApiEndpoint = String.fromEnvironment(
    'USER_API_ENDPOINT',
    defaultValue: '/api/users',
  );

  /// Cart API Endpoint Path
  static const String cartApiEndpoint = String.fromEnvironment(
    'CART_API_ENDPOINT',
    defaultValue: '/api/user/cart',
  );

  /// Full Base URL for Shop API
  static String get baseUrl => '$serverHost$shopApiEndpoint';

  /// Full Base URL for App Setting API
  static String get appSettingUrl => '$baseUrl/app-setting';

  /// Full Base URL for User API
  static String get userBaseUrl => '$serverHost$userApiEndpoint';

  /// Full Base URL for User Profile API: http://localhost/api/user/profile
  static String get userProfileUrl => '$serverHost/api/user/profile';

  /// Full Base URL for User Delete API: DELETE https://grace-fresh-market-eta.vercel.app/api/user/delete/:userId
  static String userDeleteUrl(String userId) =>
      '$serverHost/api/user/delete/$userId';

  /// Full Base URL for Cart Add API
  static String get cartAddUrl => '$serverHost$cartApiEndpoint/add';

  /// Full Base URL for Cart Get All API
  static String get cartGetAllUrl => '$serverHost$cartApiEndpoint/get-all';

  /// Full Base URL for Cart Delete API
  static String cartDeleteUrl(dynamic subcategoryId) =>
      '$serverHost$cartApiEndpoint?subcategoryId=$subcategoryId';

  /// Full Base URL for Cart Update API
  static String get cartUpdateUrl => '$serverHost$cartApiEndpoint';

  /// Full Base URL for Order Create API
  static String get orderCreateUrl => '$serverHost/api/user/orders/create';

  /// Full Base URL for Order Get All API
  static String get orderGetAllUrl => '$serverHost/api/users/orders/get-all';

  /// Full Base URL for Order Get By ID API: GET https://grace-fresh-market-eta.vercel.app/api/users/orders/{orderId}
  static String getOrderByIdUrl(dynamic orderId, {dynamic notificationId}) {
    final baseUrl = '$serverHost/api/users/orders/$orderId';
    if (notificationId != null &&
        notificationId.toString().trim().isNotEmpty) {
      return '$baseUrl?notificationId=${notificationId.toString().trim()}';
    }
    return baseUrl;
  }

  /// Full Base URL for User Notifications API: GET /api/user/notifications
  static String get notificationsUrl => '$serverHost/api/user/notifications';

  /// Full Base URL for User Address Get All API
  static String get addressGetAllUrl => '$serverHost/api/user/address/get-all';

  /// Full Base URL for User Address Create API
  static String get addressCreateUrl => '$serverHost/api/user/address/create';

  /// Full Base URL for User Address Set Default API
  static String get addressSetDefaultUrl => '$serverHost/api/user/address';

  /// Full Base URL for User Address Delete API
  static String get addressDeleteUrl => '$serverHost/api/user/address';

  /// Full Base URL for User Address Update API
  static String get addressUpdateUrl => '$serverHost/api/user/address';

  /// Application Name
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Grace Fresh Market',
  );

  /// Default API Request Timeout (seconds)
  static const int apiTimeoutSeconds = int.fromEnvironment(
    'API_TIMEOUT',
    defaultValue: 25,
  );

  /// Short API Request Timeout for quick fetches (seconds)
  static const int shortTimeoutSeconds = int.fromEnvironment(
    'SHORT_TIMEOUT',
    defaultValue: 15,
  );

  /// Current Application Environment (development, staging, production)
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  /// Whether the app is in Development mode
  static bool get isDevelopment => environment == 'development';

  /// Whether the app is in Production mode
  static bool get isProduction => environment == 'production';

  /// Cookie Key Name for User Auth Token
  static const String authCookieName = String.fromEnvironment(
    'AUTH_COOKIE_NAME',
    defaultValue: 'user_token',
  );

  /// Cookie Key Name for User Profile Data
  static const String userCookieName = String.fromEnvironment(
    'USER_COOKIE_NAME',
    defaultValue: 'user_data',
  );

  /// Helper method to format image URLs safely.
  /// If the image URL is relative (e.g. `/uploads/spinach.jpg` or `uploads/spinach.jpg`),
  /// it prepends the configured [serverHost].
  static String formatImageUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return trimmed;

    if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
      if (trimmed.startsWith('/')) {
        return '$serverHost$trimmed';
      } else {
        return '$serverHost/$trimmed';
      }
    }
    return trimmed;
  }
}
