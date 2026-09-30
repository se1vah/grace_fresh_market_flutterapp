import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'auth/login_screen.dart';
import 'cart/cart_screen.dart';
import 'home/home_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import 'widgets/grace_bottom_nav_bar.dart';
import 'widgets/grace_drawer.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  static MainNavigationScreenState? activeState;

  static bool isInsideMainNavigation(BuildContext context) {
    return activeState != null ||
        context.findAncestorStateOfType<MainNavigationScreenState>() != null;
  }

  static void navigateToTab(BuildContext context, int index) {
    if (activeState != null && activeState!.mounted) {
      try {
        Navigator.of(activeState!.context).popUntil((route) => route.isFirst);
      } catch (_) {}
      activeState!.setIndex(index);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainNavigationScreen(initialIndex: index),
        ),
        (route) => false,
      );
    }
  }

  @override
  State<MainNavigationScreen> createState() => MainNavigationScreenState();
}

class MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<NotificationsScreenState> _notificationsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    MainNavigationScreen.activeState = this;
    if (NotificationService.shouldNavigateToNotificationScreen) {
      NotificationService.shouldNavigateToNotificationScreen = false;
      _currentIndex = 2;
    } else {
      _currentIndex = widget.initialIndex;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService.checkPendingNotificationNavigation(context);
      }
      if (_currentIndex == 1) {
        context.read<CartProvider>().fetchCartItems();
      } else if (_currentIndex == 2) {
        _notificationsKey.currentState?.refreshNotifications();
      }
    });
  }

  @override
  void dispose() {
    if (MainNavigationScreen.activeState == this) {
      MainNavigationScreen.activeState = null;
    }
    super.dispose();
  }

  void openNotificationTab() {
    if (!mounted) return;
    try {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {}
    setIndex(2);
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      context.read<CartProvider>().fetchCartItems();
    } else if (index == 2) {
      _notificationsKey.currentState?.refreshNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final List<Widget> screens = [
      const HomeScreen(),
      const CartScreen(),
      NotificationsScreen(key: _notificationsKey),
      authProvider.isAuthenticated
          ? const ProfileScreen()
          : const LoginScreen(),
    ];

    String routeName;
    switch (_currentIndex) {
      case 0:
        routeName = 'home';
        break;
      case 1:
        routeName = 'cart';
        break;
      case 2:
        routeName = 'notifications';
        break;
      case 3:
        routeName = 'orders';
        break;
      default:
        routeName = 'home';
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      drawer: GraceDrawer(currentRoute: routeName),
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setIndex(index);
        },
      ),
    );
  }
}
