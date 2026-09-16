import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../views/auth/login_screen.dart';

class AuthDialogHelper {
  /// Displays an alert message ("Please login first.") via SnackBar without any separate popup container,
  /// then navigates the user to the [LoginScreen].
  static void showLoginRequiredAlert(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Please login first.',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }
}
