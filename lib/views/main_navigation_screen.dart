import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
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

  static bool isInsideMainNavigation(BuildContext context) {
    return context.findAncestorStateOfType<_MainNavigationScreenState>() != null;
  }

  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (state != null) {
      state.setIndex(index);
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
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    if (_currentIndex == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CartProvider>().fetchCartItems();
      });
    }
  }

  void setIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    if (index == 1) {
      context.read<CartProvider>().fetchCartItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    final List<Widget> screens = [
      const HomeScreen(),
      const CartScreen(),
      const NotificationsScreen(),
      authProvider.isAuthenticated ? const ProfileScreen() : const LoginScreen(),
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
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setIndex(index);
        },
      ),
    );
  }
}
