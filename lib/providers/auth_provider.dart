import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../config/env_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../utils/cookie_helper.dart';

class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userToken;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAuthenticated => _isAuthenticated;
  String? get userToken => _userToken;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final ApiService _apiService = ApiService();

  AuthProvider() {
    checkAuth();
  }

  /// Centralized check on application startup or manual re-check
  Future<void> checkAuth() async {
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    if (token != null && token.isNotEmpty) {
      _userToken = token;
      _isAuthenticated = true;

      final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);
      if (userCookie != null && userCookie.isNotEmpty) {
        try {
          final Map<String, dynamic> userData = jsonDecode(userCookie);
          _user = UserModel.fromJson(userData);
        } catch (e) {
          debugPrint('Error restoring user data from cookie: $e');
        }
      }
      fetchUserProfile();
    } else {
      _userToken = null;
      _isAuthenticated = false;
      _user = null;
    }
    notifyListeners();
  }

  /// Signup method calling ApiService and updating auth state & user_token cookie
  Future<Map<String, dynamic>> signup({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
    required String confirmPassword,
    String? fcmToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? effectiveFcmToken =
          fcmToken ?? await NotificationService.getFcmToken();

      final response = await _apiService.createUser(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        password: password,
        fcmToken: effectiveFcmToken,
      );
      // Read token from API response
      String? token;
      if (response.containsKey('token') && response['token'] != null) {
        token = response['token'].toString();
      } else if (response.containsKey('user_token') &&
          response['user_token'] != null) {
        token = response['user_token'].toString();
      } else if (response.containsKey('data') && response['data'] is Map) {
        token =
            response['data']['token']?.toString() ??
            response['data']['user_token']?.toString();
      }

      if (token == null || token.isEmpty) {
        throw Exception(
          'Signup succeeded but no authentication token was returned by the server.',
        );
      }

      // Save token in browser cookie
      CookieHelper.setCookie(EnvConfig.authCookieName, token);

      _userToken = token;
      _isAuthenticated = true;

      // Extract user info from response or payload
      Map<String, dynamic> userData = {
        'full_name': fullName,
        'email': email,
        'phone_number': phoneNumber,
        'fcm_token': ?effectiveFcmToken,
      };
      if (response['user'] is Map<String, dynamic>) {
        userData = response['user'];
      } else if (response['data'] is Map<String, dynamic> &&
          response['data']['user'] is Map<String, dynamic>) {
        userData = response['data']['user'];
      }

      _user = UserModel.fromJson(userData);
      CookieHelper.setCookie(
        EnvConfig.userCookieName,
        jsonEncode(_user!.toJson()),
      );

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Signup successful!', 'token': token};
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Login method calling ApiService and updating auth state & user_token cookie
  Future<Map<String, dynamic>> login({
    required String emailOrPhone,
    required String password,
    String? fcmToken,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final String? effectiveFcmToken =
          fcmToken ?? await NotificationService.getFcmToken();

      final response = await _apiService.loginUser(
        emailOrPhone: emailOrPhone,
        password: password,
        fcmToken: effectiveFcmToken,
      );

      // Read token from API response
      String? token;
      if (response.containsKey('token') && response['token'] != null) {
        token = response['token'].toString();
      } else if (response.containsKey('user_token') &&
          response['user_token'] != null) {
        token = response['user_token'].toString();
      } else if (response.containsKey('data') && response['data'] is Map) {
        token =
            response['data']['token']?.toString() ??
            response['data']['user_token']?.toString();
      }

      if (token == null || token.isEmpty) {
        throw Exception(
          'Login succeeded but no authentication token was returned by the server.',
        );
      }

      // Save token in browser cookie
      CookieHelper.setCookie(EnvConfig.authCookieName, token);

      _userToken = token;
      _isAuthenticated = true;

      // Extract user info from response
      Map<String, dynamic> userData = {};
      if (response['user'] is Map<String, dynamic>) {
        userData = response['user'];
      } else if (response['data'] is Map<String, dynamic> &&
          response['data']['user'] is Map<String, dynamic>) {
        userData = response['data']['user'];
      } else if (response['data'] is Map<String, dynamic>) {
        userData = response['data'];
      } else {
        final isEmail = emailOrPhone.contains('@');
        userData = {
          'email': isEmail ? emailOrPhone : '',
          'phone_number': !isEmail ? emailOrPhone : '',
          'full_name': isEmail ? emailOrPhone.split('@').first : 'User',
        };
      }

      _user = UserModel.fromJson(userData);
      CookieHelper.setCookie(
        EnvConfig.userCookieName,
        jsonEncode(_user!.toJson()),
      );

      _isLoading = false;
      notifyListeners();

      return {'success': true, 'message': 'Login successful!', 'token': token};
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }

  final List<VoidCallback> _logoutListeners = [];

  void addLogoutListener(VoidCallback listener) {
    if (!_logoutListeners.contains(listener)) {
      _logoutListeners.add(listener);
    }
  }

  void removeLogoutListener(VoidCallback listener) {
    _logoutListeners.remove(listener);
  }

  /// Logout method to call user logout API with token in cookie & authorization header, then clear state
  Future<void> logout({VoidCallback? onLogout}) async {
    final token =
        _userToken ?? CookieHelper.getCookie(EnvConfig.authCookieName);

    if (token != null && token.isNotEmpty) {
      try {
        await _apiService.logoutUser(token);
      } catch (e) {
        debugPrint('Error executing logout API call: $e');
      }
    }

    CookieHelper.removeCookie(EnvConfig.authCookieName);
    CookieHelper.removeCookie(EnvConfig.userCookieName);
    _userToken = null;
    _isAuthenticated = false;
    _user = null;
    _errorMessage = null;

    for (final listener in List<VoidCallback>.from(_logoutListeners)) {
      try {
        listener();
      } catch (e) {
        debugPrint('Error in logout listener: $e');
      }
    }
    onLogout?.call();
    notifyListeners();
  }

  /// Clear any temporary error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Update user profile details
  Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    String? profileImage,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.updateUserProfile(
        fullName: fullName,
        phoneNumber: phoneNumber,
        email: email,
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
        profileImage: profileImage,
        imageBytes: imageBytes,
        imageFileName: imageFileName,
      );

      if (response['success'] == false) {
        _isLoading = false;
        _errorMessage =
            response['message']?.toString() ?? 'Failed to update profile.';
        notifyListeners();
        return {'success': false, 'message': _errorMessage};
      }

      Map<String, dynamic>? userMap;
      if (response['user'] is Map<String, dynamic>) {
        userMap = response['user'] as Map<String, dynamic>;
      } else if (response['data'] is Map<String, dynamic>) {
        final dataMap = response['data'] as Map<String, dynamic>;
        if (dataMap['user'] is Map<String, dynamic>) {
          userMap = dataMap['user'] as Map<String, dynamic>;
        } else {
          userMap = dataMap;
        }
      } else if (response.containsKey('profileImage') ||
          response.containsKey('profile_image') ||
          response.containsKey('avatar') ||
          response.containsKey('image')) {
        userMap = response;
      }

      String? updatedProfileImage;
      if (userMap != null) {
        final rawImg = userMap['profileImage'] ??
            userMap['profile_image'] ??
            userMap['avatar'] ??
            userMap['image'];
        if (rawImg != null && rawImg.toString().trim().isNotEmpty) {
          updatedProfileImage = EnvConfig.formatImageUrl(rawImg.toString());
        }
      }

      updatedProfileImage ??= (profileImage != null && profileImage.isNotEmpty
          ? EnvConfig.formatImageUrl(profileImage)
          : _user?.profileImage);

      final userId = _user?.id ?? '1';
      final updatedUser = UserModel(
        id: userId,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        profileImage: updatedProfileImage,
      );

      _user = updatedUser;
      CookieHelper.setCookie(
        EnvConfig.userCookieName,
        jsonEncode(_user!.toJson()),
      );

      try {
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      } catch (_) {}

      _isLoading = false;
      notifyListeners();

      return {
        'success': true,
        'message': response['message'] ?? 'Profile updated successfully!',
        'user': updatedUser,
      };
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }

  /// Fetch user profile from API and sync AuthProvider state
  Future<UserModel?> fetchUserProfile() async {
    try {
      final profileData = await _apiService.getUserProfile(_userToken);
      if (profileData.isNotEmpty) {
        final fetchedUser = UserModel.fromJson(profileData);
        _user = fetchedUser;
        CookieHelper.setCookie(
          EnvConfig.userCookieName,
          jsonEncode(_user!.toJson()),
        );
        notifyListeners();
        return _user;
      }
    } catch (e) {
      debugPrint('Error fetching user profile in AuthProvider: $e');
    }
    return _user;
  }

  /// Delete user account API: DELETE /api/user/delete/:userId
  Future<Map<String, dynamic>> deleteAccount() async {
    String? userId = _user?.id;
    if (userId == null || userId.isEmpty) {
      final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);
      if (userCookie != null && userCookie.isNotEmpty) {
        try {
          final Map<String, dynamic> userData = jsonDecode(userCookie);
          userId = userData['id']?.toString() ?? userData['_id']?.toString();
        } catch (_) {}
      }
    }

    if (userId == null || userId.isEmpty) {
      return {'success': false, 'message': 'User ID not found.'};
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.deleteUserAccount(userId);

      // Sign out user and clear state
      await logout();

      _isLoading = false;
      notifyListeners();

      return result;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();

      return {'success': false, 'message': _errorMessage};
    }
  }
}
