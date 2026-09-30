import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/env_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/about_us_dialog.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_drawer.dart';
import '../widgets/help_support_dialog.dart';
import '../widgets/skeleton_loader.dart';
import 'account_details_screen.dart';
import 'delivery_address_screen.dart';
import 'my_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().fetchUserProfile();
      }
    });
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
      key: ValueKey(fullUrl),
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => buildDefaultAssetImage(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    final userName = user?.fullName ?? '';
    final userEmail = user?.email ?? '';
    final userPhone = user?.phoneNumber ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: authProvider.isLoading
                ? const ProfileScreenSkeleton()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Header Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 20,
                        ),
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
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AccountDetailsScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.limeGreen,
                                    width: 0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: _buildProfileAvatarImage(
                                  user?.profileImage,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              userName,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              userEmail,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            if (userPhone.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                userPhone,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 2),
                            // Container(
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 12,
                            //     vertical: 4,
                            //   ),
                            //   decoration: BoxDecoration(
                            //     color: AppTheme.lightGreenBadge,
                            //     borderRadius: BorderRadius.circular(12),
                            //   ),
                            //   child: Row(
                            //     mainAxisSize: MainAxisSize.min,
                            //     children: [
                            //       const Icon(
                            //         Icons.check_circle,
                            //         color: AppTheme.primaryGreen,
                            //         size: 16,
                            //       ),
                            //       const SizedBox(width: 6),
                            //       Text(
                            //         'Authenticated',
                            //         style: GoogleFonts.outfit(
                            //           fontSize: 12,
                            //           fontWeight: FontWeight.bold,
                            //           color: AppTheme.darkGreen,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Section 1: Account & Orders
                      _buildSectionHeader('Account & Orders'),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withAlpha(10),
                        child: Column(
                          children: [
                            _buildListTile(
                              Icons.person_outline,
                              'Account Details',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AccountDetailsScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildListTile(
                              Icons.shopping_bag_outlined,
                              'My Orders',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyOrdersScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildListTile(
                              Icons.location_on_outlined,
                              'Delivery Addresses',
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const DeliveryAddressScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Section 2: Help & Information
                      _buildSectionHeader('Help & Information'),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 2,
                        shadowColor: Colors.black.withAlpha(10),
                        child: Column(
                          children: [
                            _buildListTile(
                              Icons.help_outline,
                              'Help & Support',
                              () {
                                HelpSupportDialog.show(context);
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildListTile(Icons.info_outline, 'About Us', () {
                              AboutUsDialog.show(context, initialIndex: 0);
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      // Clearly styled Logout button
                      Center(
                        child: SizedBox(
                          width: 200,
                          height: 40,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              authProvider.logout();
                              context.read<CartProvider>().clearCart();

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Logged out successfully',
                                    style: GoogleFonts.outfit(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.logout,
                              color: AppTheme.deleteRed,
                              size: 20,
                            ),
                            label: Text(
                              'Log Out',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.deleteRed,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: AppTheme.deleteRed,
                                width: 1.5,
                              ),
                              backgroundColor: const Color(0xFFFEF2F2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkGreen,
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    VoidCallback onTap, {
    Color titleColor = AppTheme.textDark,
    Color iconColor = AppTheme.darkGreen,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
