import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';

final exchangeRateRepositoryProvider = Provider<ExchangeRateRepository>((ref) {
  return ExchangeRateRepository(ref.watch(apiClientProvider));
});

class ExchangeRateRepository {
  final ApiClient _client;
  ExchangeRateRepository(this._client);

  Future<ExchangeRate> fetch() async {
    try {
      final response = await _client.dio.get(ApiEndpoints.exchangeRates);
      return ExchangeRate.fromJson(response.data);
    } catch (_) {
      return ExchangeRate.fallback();
    }
  }
}
