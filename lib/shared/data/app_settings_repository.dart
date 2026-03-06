import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  return AppSettingsRepository(ref.watch(apiClientProvider));
});

class AppSettingsRepository {
  final ApiClient _client;
  AppSettingsRepository(this._client);

  Future<AppSettings> fetch() async {
    try {
      final response = await _client.dio.get('/admin/settings');
      return AppSettings.fromJson(response.data);
    } catch (_) {
      return AppSettings.defaults();
    }
  }
}
