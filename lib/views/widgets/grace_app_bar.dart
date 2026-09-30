import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

class GraceAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onMenuPressed;

  const GraceAppBar({super.key, this.onMenuPressed});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.menu_rounded,
          color: AppTheme.darkGreen,
          size: 26,
        ),
        tooltip: 'Open Menu',
        onPressed: () {
          if (onMenuPressed != null) {
            onMenuPressed!();
          } else {
            Scaffold.of(context).openDrawer();
          }
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.darkGreen,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'G',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Grace Fresh Market',
            style: GoogleFonts.outfit(
              color: AppTheme.darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }
}
