// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_bottom_nav_bar.dart';
import '../widgets/grace_drawer.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final FocusNode _newPasswordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  int _currentStep = 1; // 1: Email Entry, 2: Confirmation Code, 3: New Password
  bool _isLoading = false;
  String? _inlineError;

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    String prefillEmail = widget.initialEmail?.trim() ?? '';
    // If initial string does not look like email (no @), check if user entered email
    _emailController = TextEditingController(text: prefillEmail);

    _otpControllers = List.generate(4, (_) => TextEditingController());
    _otpFocusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    _emailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// Step 1: Send OTP API Call
  void _handleSendOtp() async {
    setState(() {
      _inlineError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_emailFormKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.forgotPassword(email: email);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response['statusCode'] == 200) {
      setState(() {
        _currentStep = 2;
        _inlineError = null;
        _autovalidateMode = AutovalidateMode.disabled;
      });
      // Focus first OTP field
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } else {
      setState(() {
        _inlineError =
            response['message'] ?? response['error'] ?? 'Failed to send OTP. Please try again.';
      });
    }
  }

  /// Step 2: Confirm OTP API Call
  void _handleVerifyOtp() async {
    setState(() {
      _inlineError = null;
    });

    final email = _emailController.text.trim();
    final confirmationCode =
        _otpControllers.map((c) => c.text.trim()).join();

    if (confirmationCode.length < 4) {
      setState(() {
        _inlineError = 'Please enter all 4 digits of the confirmation code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await _apiService.confirmForgotPassword(
      email: email,
      confirmationCode: confirmationCode,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (response['statusCode'] == 200) {
      setState(() {
        _currentStep = 3;
        _inlineError = null;
        _autovalidateMode = AutovalidateMode.disabled;
      });
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) {
          _newPasswordFocusNode.requestFocus();
        }
      });
    } else {
      setState(() {
        _inlineError =
            response['message'] ?? response['error'] ?? 'Invalid confirmation code.';
      });
    }
  }

  /// Step 4: Final Password Reset Submit Call
  void _handleResetPasswordSubmit() async {
    setState(() {
      _inlineError = null;
      _autovalidateMode = AutovalidateMode.onUserInteraction;
    });

    if (!_passwordFormKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final confirmationCode =
        _otpControllers.map((c) => c.text.trim()).join();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() {
        _inlineError = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = context.read<AuthProvider>();
    final String? fcmToken = await NotificationService.getFcmToken();

    final result = await authProvider.resetPasswordSubmit(
      email: email,
      confirmationCode: confirmationCode,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
      fcmToken: fcmToken,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome back! Login successful.',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        MainNavigationScreen.navigateToTab(context, 3);
      }
    } else {
      setState(() {
        _inlineError =
            result['message'] ?? 'Failed to reset password. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // Top Hero Banner Header matching design screenshot
                Stack(
                  children: [
                    SizedBox(
                      height: 180,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/fresh-basket.jpg',
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/images/fresh_basket.jpg',
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 180,
                                    color: AppTheme.darkGreen,
                                    child: const Center(
                                      child: Icon(
                                        Icons.shopping_basket,
                                        size: 60,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                            ),
                      ),
                    ),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.black.withOpacity(0.75),
                          ],
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 20,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Password',
                            style: GoogleFonts.outfit(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Follow the steps to reset your password and secure your account.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Main Form Card Container
                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24.0),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _getStepTitle(),
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            _getStepSubtitle(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Server / Validation Error Banner
                        if (_inlineError != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFCA5A5),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppTheme.deleteRed,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _inlineError!,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: AppTheme.deleteRed,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // STEP 1: EMAIL ENTRY STEP
                        if (_currentStep == 1) _buildEmailStep(),

                        // STEP 2: CONFIRMATION CODE STEP
                        if (_currentStep == 2) _buildOtpStep(),

                        // STEP 3: NEW PASSWORD STEP
                        if (_currentStep == 3) _buildNewPasswordStep(),

                        const SizedBox(height: 20),

                        // Back to Sign In link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Remembered your password? ',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pop();
                                    },
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGreen,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppTheme.darkGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (index == 3 && _currentStep == 1) {
            // Already on Profile / Auth section
          } else {
            MainNavigationScreen.navigateToTab(context, index);
          }
        },
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1:
        return 'Forgot Password';
      case 2:
        return 'Enter Confirmation Code';
      case 3:
        return 'Set New Password';
      default:
        return 'Forgot Password';
    }
  }

  String _getStepSubtitle() {
    switch (_currentStep) {
      case 1:
        return 'Enter your registered email address to receive a 4-digit confirmation code.';
      case 2:
        return 'We sent a 4-digit confirmation code to\n${_emailController.text.trim()}';
      case 3:
        return 'Enter and confirm your new password below.';
      default:
        return '';
    }
  }

  /// Step 1 UI Widget
  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('Email Address'),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleSendOtp(),
            enabled: !_isLoading,
            decoration: _buildInputDecoration(
              hintText: 'farmer@example.com',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Email Address is required';
              }
              final email = value.trim();
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Send OTP Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                disabledBackgroundColor:
                    AppTheme.darkGreen.withOpacity(0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Send OTP',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 2 UI Widget (4-digit OTP code)
  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldLabel('Confirmation Code'),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            return SizedBox(
              width: 60,
              height: 60,
              child: TextFormField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4), // Allow pasting 4 digits
                ],
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: const Color(0xFFF4F5F2),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppTheme.darkGreen,
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  if (value.length > 1) {
                    // Handle paste of multiple digits
                    final digits = value.replaceAll(RegExp(r'\D'), '');
                    for (int i = 0; i < 4 && i < digits.length; i++) {
                      _otpControllers[i].text = digits[i];
                    }
                    if (digits.length >= 4) {
                      _otpFocusNodes[3].requestFocus();
                    } else {
                      _otpFocusNodes[digits.length].requestFocus();
                    }
                    return;
                  }

                  if (value.isNotEmpty && index < 3) {
                    _otpFocusNodes[index + 1].requestFocus();
                  } else if (value.isEmpty && index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 28),

        // Submit Button for Confirmation Code
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleVerifyOtp,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkGreen,
              disabledBackgroundColor:
                  AppTheme.darkGreen.withOpacity(0.5),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Submit',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_outline,
                        size: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: _isLoading
                ? null
                : () {
                    setState(() {
                      _currentStep = 1;
                      _inlineError = null;
                    });
                  },
            child: Text(
              'Change Email Address',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGreen,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Step 3 UI Widget (New Password Entry)
  Widget _buildNewPasswordStep() {
    return Form(
      key: _passwordFormKey,
      autovalidateMode: _autovalidateMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFieldLabel('New Password'),
          TextFormField(
            controller: _newPasswordController,
            focusNode: _newPasswordFocusNode,
            obscureText: _obscureNewPassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                _confirmPasswordFocusNode.requestFocus(),
            enabled: !_isLoading,
            decoration: _buildInputDecoration(
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'New Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          _buildFieldLabel('Confirm New Password'),
          TextFormField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            obscureText: _obscureConfirmPassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleResetPasswordSubmit(),
            enabled: !_isLoading,
            decoration: _buildInputDecoration(
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.grey.shade600,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your new password';
              }
              if (value != _newPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),

          // Final Submit Button
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleResetPasswordSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                disabledBackgroundColor:
                    AppTheme.darkGreen.withOpacity(0.5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Submit',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 20,
                          color: Colors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF4F5F2),
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
        borderSide: const BorderSide(color: AppTheme.deleteRed, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.deleteRed, width: 1.5),
      ),
      errorStyle: GoogleFonts.outfit(color: AppTheme.deleteRed, fontSize: 12),
    );
  }
}
