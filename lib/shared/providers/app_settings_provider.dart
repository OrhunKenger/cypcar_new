import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/shared/data/app_settings_repository.dart';
import 'package:cypcar/shared/models/app_settings_model.dart';

final appSettingsProvider = FutureProvider<AppSettings>((ref) {
  return ref.watch(appSettingsRepositoryProvider).fetch();
});
