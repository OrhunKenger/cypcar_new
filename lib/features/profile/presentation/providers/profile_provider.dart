import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cypcar/features/profile/data/profile_repository.dart';
import 'package:cypcar/features/profile/domain/models/profile_model.dart';

final profileProvider = FutureProvider.family<PublicProfile, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});
