import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/core/storage/secure_storage.dart';
import 'package:cypcar/features/auth/domain/models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider), ref.watch(secureStorageProvider));
});

class AuthRepository {
  final ApiClient _client;
  final SecureStorageService _storage;
  AuthRepository(this._client, this._storage);

  Future<UserModel?> getMe() async {
    final hasToken = await _storage.hasTokens();
    if (!hasToken) return null;
    try {
      final response = await _client.dio.get(ApiEndpoints.me);
      return UserModel.fromJson(response.data);
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> login(String email, String password) async {
    final res = await _client.dio.post(ApiEndpoints.login, data: {
      'email': email,
      'password': password,
    });
    await _storage.saveTokens(
      accessToken: res.data['access_token'],
      refreshToken: res.data['refresh_token'],
    );
    final me = await _client.dio.get(ApiEndpoints.me);
    return UserModel.fromJson(me.data);
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final res = await _client.dio.post(ApiEndpoints.register, data: {
      'full_name': fullName,
      'email': email,
      'phone_number': phone,
      'password': password,
    });
    await _storage.saveTokens(
      accessToken: res.data['access_token'],
      refreshToken: res.data['refresh_token'],
    );
    final me = await _client.dio.get(ApiEndpoints.me);
    return UserModel.fromJson(me.data);
  }

  Future<void> logout() async {
    await _storage.clearTokens();
  }

  Future<void> sendVerificationEmail(String email) async {
    await _client.dio.post(ApiEndpoints.sendVerification, data: {'email': email});
  }

  Future<void> verifyEmail(String email, String code) async {
    await _client.dio.post(ApiEndpoints.verifyEmail, data: {'email': email, 'code': code});
  }

  Future<void> forgotPassword(String email) async {
    await _client.dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
  }

  Future<void> resetPassword(String email, String code, String newPassword) async {
    await _client.dio.post(ApiEndpoints.resetPassword, data: {
      'email': email,
      'code': code,
      'new_password': newPassword,
    });
  }
}
