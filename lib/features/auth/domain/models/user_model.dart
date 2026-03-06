class UserModel {
  final String id;
  final String email;
  final String? phone;
  final String fullName;
  final String? profilePhotoUrl;
  final String? whatsappNumber;
  final bool isActive;
  final bool isAdmin;
  final bool isEmailVerified;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.profilePhotoUrl,
    this.whatsappNumber,
    required this.isActive,
    required this.isAdmin,
    this.isEmailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'],
        email: j['email'],
        phone: j['phone_number'],
        fullName: j['full_name'],
        profilePhotoUrl: j['profile_photo_url'],
        whatsappNumber: j['whatsapp_number'],
        isActive: j['is_active'] ?? true,
        isAdmin: j['is_admin'] ?? false,
        isEmailVerified: j['is_email_verified'] ?? false,
      );
}
