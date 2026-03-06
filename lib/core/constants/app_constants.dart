class AppConstants {
  AppConstants._();

  // static const String baseUrl = 'http://10.0.2.2:8001/api/v1'; // Android emulator
  // static const String baseUrl = 'http://localhost:8001/api/v1'; // Web / iOS simulator
  static const String baseUrl = 'http://192.168.1.25:8001/api/v1'; // Gerçek cihaz (aynı ağ)
  // static const String baseUrl = 'https://api.cypcar.com/api/v1'; // Production

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  static const int connectTimeout = 15000;
  static const int receiveTimeout = 15000;

  static const int defaultPageSize = 20;
}
