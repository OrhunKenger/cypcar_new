class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/me/change-password';
  static const String changeEmail = '/auth/me/change-email';
  static const String changePhone = '/auth/me/change-phone';
  static const String changeWhatsapp = '/auth/me/whatsapp';
  static const String updatePhoto = '/auth/me/photo';
  static const String deletePhoto = '/auth/me/photo';
  static const String deleteAccount = '/auth/me';
  static const String fcmToken = '/auth/me/fcm-token';
  static const String sendVerification = '/auth/send-verification';
  static const String verifyEmail = '/auth/verify-email';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static String userProfile(String userId) => '/users/$userId';
  static String blockUser(String userId) => '/users/$userId/block';
  static const String blockedUsers = '/users/blocked';

  // Listings
  static const String listings = '/listings';
  static const String featured = '/listings/featured';
  static const String urgent = '/listings/urgent';
  static const String myListings = '/listings/my';
  static String listingDetail(String id) => '/listings/$id';
  static String listingImages(String id) => '/listings/$id/images';
  static String uploadListingImage(String id) => '/listings/$id/images';
  static String listingImage(String id, int index) => '/listings/$id/images/$index';
  static String markSold(String id) => '/listings/$id/mark-sold';
  static String renewListing(String id) => '/listings/$id/renew';
  static String reportListing(String id) => '/listings/$id/report';

  // Favorites
  static const String favorites = '/favorites';
  static String toggleFavorite(String listingId) => '/favorites/$listingId';

  // Catalog
  static const String categories = '/catalog/categories';
  static String makesByCategory(String category) => '/catalog/$category/makes';
  static String seriesByMake(String makeId) => '/catalog/makes/$makeId/series';
  static String modelsBySeries(String seriesId) => '/catalog/series/$seriesId/models';

  // Exchange Rates
  static const String exchangeRates = '/exchange-rates';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationsUnreadCount = '/notifications/unread-count';
  static const String notificationsReadAll = '/notifications/read-all';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static String notificationDelete(String id) => '/notifications/$id';
}
