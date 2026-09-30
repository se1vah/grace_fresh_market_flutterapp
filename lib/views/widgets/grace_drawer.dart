// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../auth/login_screen.dart';
import '../main_navigation_screen.dart';
import '../profile/delivery_address_screen.dart';
import '../profile/my_orders_screen.dart';
import 'about_us_dialog.dart';
import 'help_support_dialog.dart';

class GraceDrawer extends StatelessWidget {
  final String? currentRoute;

  const GraceDrawer({super.key, this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isAuthenticated;

    // Detect if home is active (default for main navigation tab 0)
    final isHomeActive = currentRoute == 'home' || currentRoute == null;

    return Drawer(
      backgroundColor: const Color(0xFFF6F6F6),
      elevation: 8,
      width: 280,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Main Drawer Navigation List
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: isHomeActive
                          ? Icons.home_rounded
                          : Icons.home_outlined,
                      title: 'Home',
                      isActive: isHomeActive,
                      onTap: () {
                        Navigator.of(context).pop();
                        MainNavigationScreen.navigateToTab(context, 0);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.local_shipping_outlined,
                      title: 'My Orders',
                      isActive: currentRoute == 'orders',
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != 'orders') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const MyOrdersScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.location_on_outlined,
                      title: 'My Addresses',
                      isActive: currentRoute == 'addresses',
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != 'addresses') {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DeliveryAddressScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_none_outlined,
                      title: 'Notifications',
                      isActive: currentRoute == 'notifications',
                      badgeCount: 0,
                      onTap: () {
                        Navigator.of(context).pop();
                        if (currentRoute != 'notifications') {
                          MainNavigationScreen.navigateToTab(context, 2);
                        }
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18.0),
                      child: Divider(
                        color: Color(0xFFE5E7EB),
                        height: 1,
                        thickness: 1,
                      ),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      isActive: false,
                      onTap: () {
                        Navigator.of(context).pop();
                        HelpSupportDialog.show(context);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline_rounded,
                      title: 'About Us',
                      isActive: false,
                      onTap: () {
                        Navigator.of(context).pop();
                        AboutUsDialog.show(context);
                      },
                    ),
                  ],
                ),
              ),

              // Bottom Sign Out / Sign In Button matching screenshot border & styling
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      if (isLoggedIn) {
                        authProvider.logout();
                        context.read<CartProvider>().clearCart();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Signed out successfully',
                              style: GoogleFonts.outfit(),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF4A3E3D),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isLoggedIn
                              ? Icons.output_rounded
                              : Icons.login_rounded,
                          color: const Color(0xFF4A3E3D),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isLoggedIn ? 'Log Out' : 'Sign In',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF4A3E3D),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    int? badgeCount,
  }) {
    const activeBgColor = Color(
      0xFFC5F368,
    ); // Bright lime green pill matching screenshot
    const activeTextColor = Color(
      0xFF384318,
    ); // Dark olive green text matching screenshot
    const inactiveTextColor = Color(0xFF374151); // Dark charcoal text
    const inactiveIconColor = Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? activeBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? activeTextColor : inactiveIconColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: isActive ? activeTextColor : inactiveTextColor,
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ),
              if (badgeCount != null && badgeCount > 0)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD32F2F),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badgeCount',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
