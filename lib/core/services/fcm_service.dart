import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/core/storage/secure_storage.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

class FcmService {
  final ApiClient _client;
  final SecureStorageService _storage;

  FcmService(this._client, this._storage);

  Future<void> init() async {
    if (Firebase.apps.isEmpty) return;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await messaging.getToken();
    if (token != null) await _saveToken(token);

    messaging.onTokenRefresh.listen(_saveToken);

    FirebaseMessaging.onMessage.listen(_handleForeground);
  }

  Future<void> _saveToken(String token) async {
    final hasToken = await _storage.hasTokens();
    if (!hasToken) return;
    try {
      await _client.dio.patch(ApiEndpoints.fcmToken, data: {'fcm_token': token});
    } catch (_) {}
  }

  void _handleForeground(RemoteMessage message) {
    // Foreground bildirimler — snackbar veya in-app gösterim için genişletilebilir
  }
}
