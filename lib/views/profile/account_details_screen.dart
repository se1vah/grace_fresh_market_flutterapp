import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/env_config.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/image_picker_helper.dart';
import '../main_navigation_screen.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_bottom_nav_bar.dart';
import '../widgets/grace_drawer.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = true;
  bool _isSaving = false;

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _profileImageUrl;
  Uint8List? _selectedImageBytes;
  String? _selectedImageFileName;

  // Custom validation error strings (cleared on typing)
  String? _emailError;
  String? _fullNameError;
  String? _phoneError;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _loadUserProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    // Pre-fill from current auth user first
    if (currentUser != null) {
      _fullNameController.text = currentUser.fullName;
      _phoneController.text = currentUser.phoneNumber;
      _emailController.text = currentUser.email;
      _profileImageUrl = currentUser.profileImage;
    }

    try {
      // Fetch fresh profile data via GET http://localhost/api/user/profile
      final profileData = await _apiService.getUserProfile();
      if (profileData.isNotEmpty) {
        final fetchedUser = UserModel.fromJson(profileData);
        if (mounted) {
          setState(() {
            if (fetchedUser.fullName.isNotEmpty) {
              _fullNameController.text = fetchedUser.fullName;
            }
            if (fetchedUser.phoneNumber.isNotEmpty) {
              _phoneController.text = fetchedUser.phoneNumber;
            }
            if (fetchedUser.email.isNotEmpty) {
              _emailController.text = fetchedUser.email;
            }
            if (fetchedUser.profileImage != null &&
                fetchedUser.profileImage!.isNotEmpty) {
              _profileImageUrl = fetchedUser.profileImage;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error pre-filling profile from API: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePickImage() async {
    if (_isSaving) return;
    try {
      final pickerResult = await pickProfileImage();
      if (pickerResult != null) {
        setState(() {
          _selectedImageBytes = pickerResult.bytes;
          _selectedImageFileName = pickerResult.fileName;
          _profileImageUrl = pickerResult.dataUrl;
        });
        _showSnackBar('Profile photo selected successfully.');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showSnackBar(msg, isError: true);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;

    final email = _emailController.text.trim();
    final fullName = _fullNameController.text.trim();
    final phone = _phoneController.text.trim();
    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    bool hasError = false;

    setState(() {
      _emailError = null;
      _fullNameError = null;
      _phoneError = null;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    if (email.isEmpty) {
      _emailError = 'Email Address is required.';
      hasError = true;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Please enter a valid email address.';
      hasError = true;
    }

    if (fullName.isEmpty) {
      _fullNameError = 'Full Name is required.';
      hasError = true;
    }

    if (phone.isEmpty) {
      _phoneError = 'Phone Number is required.';
      hasError = true;
    } else if (phone.length < 7) {
      _phoneError = 'Phone Number must be at least 7 digits.';
      hasError = true;
    }

    if (newPass.isNotEmpty || confirmPass.isNotEmpty) {
      if (currentPass.isEmpty) {
        _currentPasswordError =
            'Current password is required to change password.';
        hasError = true;
      }
      if (newPass.length < 6) {
        _newPasswordError = 'New password must be at least 6 characters.';
        hasError = true;
      }
      if (confirmPass.isEmpty) {
        _confirmPasswordError = 'Please confirm your new password.';
        hasError = true;
      } else if (newPass != confirmPass) {
        _confirmPasswordError = 'Passwords do not match.';
        hasError = true;
      }
    }

    if (hasError) {
      setState(() {});
      _showSnackBar('Please fix the validation errors above.', isError: true);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();

    final result = await authProvider.updateUserProfile(
      fullName: fullName,
      phoneNumber: phone,
      email: email,
      currentPassword: currentPass.isNotEmpty ? currentPass : null,
      newPassword: newPass.isNotEmpty ? newPass : null,
      confirmPassword: confirmPass.isNotEmpty ? confirmPass : null,
      profileImage: _profileImageUrl,
      imageBytes: _selectedImageBytes,
      imageFileName: _selectedImageFileName,
    );

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (result['success'] == true) {
        _showSnackBar('Profile changes saved successfully!');
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      } else {
        final errorMsg =
            result['message']?.toString() ??
            'Failed to update account details. Please try again.';
        final lowerMsg = errorMsg.toLowerCase();

        setState(() {
          if (lowerMsg.contains('current password') ||
              lowerMsg.contains('password incorrect') ||
              lowerMsg.contains('invalid password') ||
              lowerMsg.contains('wrong password')) {
            _currentPasswordError = errorMsg;
          } else if (lowerMsg.contains('new password')) {
            _newPasswordError = errorMsg;
          } else if (lowerMsg.contains('confirm password')) {
            _confirmPasswordError = errorMsg;
          } else if (lowerMsg.contains('email')) {
            _emailError = errorMsg;
          } else if (lowerMsg.contains('phone')) {
            _phoneError = errorMsg;
          } else if (lowerMsg.contains('name')) {
            _fullNameError = errorMsg;
          }
        });

        _showSnackBar(errorMsg, isError: true);
      }
    }
  }

  Widget _buildProfileAvatarImage(String? imageUrl) {
    Widget buildFallbackIcon() {
      return Container(
        color: AppTheme.lightGreenBadge,
        child: const Icon(Icons.person, size: 55, color: AppTheme.darkGreen),
      );
    }

    Widget buildDefaultAssetImage() {
      return Image.asset(
        'assets/images/Profile.jpg',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => buildFallbackIcon(),
      );
    }

    if (imageUrl == null || imageUrl.trim().isEmpty) {
      return buildDefaultAssetImage();
    }

    final trimmed = imageUrl.trim();

    if (trimmed.startsWith('data:image') && trimmed.contains('base64,')) {
      try {
        final base64Str = trimmed.split('base64,').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              buildDefaultAssetImage(),
        );
      } catch (_) {
        return buildDefaultAssetImage();
      }
    }

    final fullUrl = EnvConfig.formatImageUrl(trimmed);
    return Image.network(
      fullUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => buildDefaultAssetImage(),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white)),
        backgroundColor: isError ? AppTheme.deleteRed : AppTheme.darkGreen,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'profile'),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          MainNavigationScreen.navigateToTab(context, index);
        },
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.darkGreen),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Sub-header with Back Button and Title
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: AppTheme.darkGreen,
                              ),
                              onPressed: () => Navigator.pop(context),
                              tooltip: 'Back to Profile',
                            ),
                            Expanded(
                              child: Text(
                                'Account Details',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Profile Image Avatar with Edit Badge
                        Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.limeGreen,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(20),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _buildProfileAvatarImage(_profileImageUrl),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _isSaving ? null : _handlePickImage,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppTheme.darkGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(30),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: AppTheme.limeGreen,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Update your personal information below to keep your Grass Fresh profile current.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Card 1: Personal Information
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Email Address Field (Editable)
                              _buildFieldLabel('Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                enabled: true,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.mail_outline,
                                  hintText: 'Enter email address',
                                  errorText: _emailError,
                                ),
                                onChanged: (val) {
                                  if (_emailError != null) {
                                    setState(() {
                                      _emailError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // Full Name Field
                              _buildFieldLabel('Full Name'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _fullNameController,
                                keyboardType: TextInputType.name,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.person_outline,
                                  hintText: 'Enter your full name',
                                  errorText: _fullNameError,
                                ),
                                onChanged: (val) {
                                  if (_fullNameError != null) {
                                    setState(() {
                                      _fullNameError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // Phone Number Field (Numbers Only)
                              _buildFieldLabel('Phone Number'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.phone_outlined,
                                  hintText: 'Enter phone number',
                                  errorText: _phoneError,
                                ),
                                onChanged: (val) {
                                  if (_phoneError != null) {
                                    setState(() {
                                      _phoneError = null;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Card 2: Security Section
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(10),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Security',
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Divider(
                                height: 1,
                                color: Color(0xFFF0F0F0),
                              ),
                              const SizedBox(height: 16),

                              // Current Password
                              _buildFieldLabel('Current Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _currentPasswordController,
                                obscureText: _obscureCurrentPassword,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                ),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.key_outlined,
                                  hintText: 'Enter current password',
                                  errorText: _currentPasswordError,
                                  suffixWidget: IconButton(
                                    icon: Icon(
                                      _obscureCurrentPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureCurrentPassword =
                                            !_obscureCurrentPassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (val) {
                                  if (_currentPasswordError != null) {
                                    setState(() {
                                      _currentPasswordError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // New Password
                              _buildFieldLabel('New Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                ),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.lock_reset,
                                  hintText: 'Create a new password',
                                  errorText: _newPasswordError,
                                  suffixWidget: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureNewPassword =
                                            !_obscureNewPassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (val) {
                                  if (_newPasswordError != null) {
                                    setState(() {
                                      _newPasswordError = null;
                                    });
                                  }
                                },
                              ),
                              const SizedBox(height: 20),

                              // Confirm New Password
                              _buildFieldLabel('Confirm New Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                ),
                                decoration: _inputDecoration(
                                  prefixIcon: Icons.check_circle_outline,
                                  hintText: 'Confirm your new password',
                                  errorText: _confirmPasswordError,
                                  suffixWidget: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (val) {
                                  if (_confirmPasswordError != null) {
                                    setState(() {
                                      _confirmPasswordError = null;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkGreen,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppTheme.darkGreen
                                  .withAlpha(150),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF4A2E2B),
                                width: 1.5,
                              ),
                              backgroundColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A2E2B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required IconData prefixIcon,
    IconData? suffixIcon,
    Widget? suffixWidget,
    String? hintText,
    String? errorText,
    Color fillColor = const Color(0xFFF4F6F4),
  }) {
    return InputDecoration(
      filled: true,
      fillColor: fillColor,
      hintText: hintText,
      errorText: errorText,
      errorMaxLines: 2,
      hintStyle: GoogleFonts.outfit(
        color: AppTheme.textSecondary.withAlpha(180),
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: AppTheme.darkGreen, size: 20),
      suffixIcon:
          suffixWidget ??
          (suffixIcon != null
              ? Icon(suffixIcon, color: AppTheme.textSecondary, size: 18)
              : null),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.darkGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.deleteRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.deleteRed, width: 1.5),
      ),
    );
  }
}
