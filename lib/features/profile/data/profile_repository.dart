import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cypcar/core/api/api_client.dart';
import 'package:cypcar/core/api/api_endpoints.dart';
import 'package:cypcar/features/auth/domain/models/user_model.dart';
import 'package:cypcar/features/profile/domain/models/profile_model.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(apiClientProvider));
});

class ProfileRepository {
  final ApiClient _client;
  ProfileRepository(this._client);

  Future<PublicProfile> getProfile(String userId) async {
    final res = await _client.dio.get(ApiEndpoints.userProfile(userId));
    return PublicProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> updateName(String fullName) async {
    final res = await _client.dio.patch(ApiEndpoints.me, data: {'full_name': fullName});
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> updateWhatsapp(String? number) async {
    final res = await _client.dio.patch(
      ApiEndpoints.changeWhatsapp,
      data: {'whatsapp_number': number},
    );
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> changeEmail(String newEmail, String password) async {
    final res = await _client.dio.patch(ApiEndpoints.changeEmail, data: {
      'new_email': newEmail,
      'password': password,
    });
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> changePhone(String newPhone, String password) async {
    final res = await _client.dio.patch(ApiEndpoints.changePhone, data: {
      'new_phone_number': newPhone,
      'password': password,
    });
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> changePassword(String current, String newPass) async {
    await _client.dio.patch(ApiEndpoints.changePassword, data: {
      'current_password': current,
      'new_password': newPass,
    });
  }

  Future<UserModel> uploadPhoto(XFile file) async {
    final bytes = await file.readAsBytes();
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });
    final res = await _client.dio.patch(ApiEndpoints.updatePhoto, data: formData);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<UserModel> deletePhoto() async {
    final res = await _client.dio.delete(ApiEndpoints.deletePhoto);
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> deleteAccount(String password) async {
    await _client.dio.delete(ApiEndpoints.deleteAccount, data: {'password': password});
  }

  Future<bool> toggleBlock(String userId) async {
    final res = await _client.dio.post(ApiEndpoints.blockUser(userId));
    return (res.data as Map<String, dynamic>)['is_blocked'] as bool;
  }
}
