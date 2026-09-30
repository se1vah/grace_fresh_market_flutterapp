import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/env_config.dart';
import 'providers/shop_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';
import 'views/main_navigation_screen.dart';

import 'firebase_options.dart';
import 'services/notification_service.dart';
import 'utils/cookie_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent cookie & auth token storage
  await CookieHelper.init();

  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Register background FCM handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notifications
  await NotificationService.initialize();

  runApp(const GraceFreshMarketApp());
}

class GraceFreshMarketApp extends StatefulWidget {
  const GraceFreshMarketApp({super.key});

  @override
  State<GraceFreshMarketApp> createState() => _GraceFreshMarketAppState();
}

class _GraceFreshMarketAppState extends State<GraceFreshMarketApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          debugPrint(
            'getInitialMessage triggered in GraceFreshMarketApp initState',
          );
          NotificationService.navigateToNotificationScreen();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        title: EnvConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(
              textScaler: const TextScaler.linear(0.92),
            ),
            child: child!,
          );
        },
        home: const MainNavigationScreen(),
      ),
    );
  }
}
