import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cypcar/features/auth/data/auth_repository.dart';
import 'package:cypcar/features/auth/domain/models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repo;
  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final user = await _repo.getMe();
    if (mounted) state = AsyncValue.data(user);
  }

  Future<void> refresh() async {
    final user = await _repo.getMe();
    if (mounted) state = AsyncValue.data(user);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.login(email, password));
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.register(
          fullName: fullName,
          email: email,
          phone: phone,
          password: password,
        ));
  }

  Future<void> logout() async {
    await _repo.logout();
    if (mounted) state = const AsyncValue.data(null);
  }

  bool get isLoggedIn => state.valueOrNull != null;
}
