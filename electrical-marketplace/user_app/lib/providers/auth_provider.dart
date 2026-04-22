import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../core/storage/secure_storage.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _service;

  AuthNotifier(this._service) : super(const AsyncValue.loading()) {
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      final loggedIn = await SecureStorage.isLoggedIn();
      if (!loggedIn) {
        state = const AsyncValue.data(null);
        return;
      }
      final user = await _service.getProfile();
      state = AsyncValue.data(user);
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<dynamic> sendOtp(String phone) async {
    final result = await _service.sendOtp(phone);
    if (result is User) {
      state = AsyncValue.data(result);
    }
    return result;
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const AsyncValue.loading();
    try {
      final user = await _service.verifyOtp(phone, otp);
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    final user = await _service.updateProfile(name: name, email: email);
    state = AsyncValue.data(user);
  }

  Future<void> logout() async {
    await _service.logout();
    state = const AsyncValue.data(null);
  }

  bool get isLoggedIn => state.valueOrNull != null;
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});
