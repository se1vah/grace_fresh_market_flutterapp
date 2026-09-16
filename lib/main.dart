import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/env_config.dart';
import 'providers/shop_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'views/main_navigation_screen.dart';

import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  runApp(const GraceFreshMarketApp());
}

class GraceFreshMarketApp extends StatelessWidget {
  const GraceFreshMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
