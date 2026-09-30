import '../config/env_config.dart';

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? profileImage;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.profileImage,
    this.fcmToken,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawImage = json['profileImage'] ??
        json['profile_image'] ??
        json['avatar'] ??
        json['image'];
    String? formattedImage;
    if (rawImage != null && rawImage.toString().trim().isNotEmpty) {
      formattedImage = EnvConfig.formatImageUrl(rawImage.toString());
    }

    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '1',
      fullName: json['full_name'] ?? json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber:
          json['phone_number'] ?? json['phoneNumber'] ?? json['phone'] ?? '',
      profileImage: formattedImage,
      fcmToken: json['fcmToken'] ?? json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      if (profileImage != null) 'profile_image': profileImage,
      if (fcmToken != null) 'fcm_token': fcmToken,
    };
  }
}

