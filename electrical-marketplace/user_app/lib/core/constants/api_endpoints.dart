// Use local LAN IP because USB connection is constantly dropping and wiping adb reverse
String _baseUrl = 'http://10.1.44.21:4000';

class ApiEndpoints {
  static String baseUrl = _baseUrl;

  // Auth
  static const String sendOtp = '/api/auth/send-otp';
  static const String verifyOtp = '/api/auth/verify-otp';
  static const String refreshToken = '/api/auth/refresh';
  static const String profile = '/api/auth/profile';

  // Products
  static const String categories = '/api/categories';
  static const String products = '/api/products';
  static String productDetail(String id) => '/api/products/$id';

  // Vendors
  static const String vendors = '/api/vendors/by-variant';
  static const String vendorsAll = '/api/vendors/all';

  // Cart
  static const String cart = '/api/cart';
  static String cartItem(String id) => '/api/cart/$id';

  // Orders
  static const String orders = '/api/orders';
  static String orderDetail(String id) => '/api/orders/$id';

  // Addresses
  static const String addresses = '/api/addresses';
  static String addressDetail(String id) => '/api/addresses/$id';
  static String setDefaultAddress(String id) =>
      '/api/addresses/$id/set-default';

  // Payment
  static const String createPayment = '/api/payment/create';
  static const String verifyPayment = '/api/payment/verify';

  // Notifications
  static const String notificationToken = '/api/notifications/token';

  // Brands
  static const String brands = '/api/brands';
}
