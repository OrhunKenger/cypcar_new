import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/shared/data/exchange_rate_repository.dart';
import 'package:cypcar/shared/models/exchange_rate_model.dart';

final exchangeRateProvider = FutureProvider<ExchangeRate>((ref) {
  return ref.watch(exchangeRateRepositoryProvider).fetch();
});
