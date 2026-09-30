// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/notification_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_drawer.dart';
import '../widgets/order_details_dialog.dart';
import '../widgets/skeleton_loader.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => NotificationsScreenState();
}

class NotificationsScreenState extends State<NotificationsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<NotificationModel> _notifications = [];
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authProvider = Provider.of<AuthProvider>(context, listen: false);
        _authProvider?.addLogoutListener(_onLogout);
      }
    });
    _fetchNotifications();
  }

  @override
  void dispose() {
    _authProvider?.removeLogoutListener(_onLogout);
    super.dispose();
  }

  void _onLogout() {
    clearNotifications();
  }

  void clearNotifications() {
    if (mounted) {
      setState(() {
        _notifications = [];
        _errorMessage = null;
        _isLoading = false;
      });
    }
  }

  void refreshNotifications() {
    _fetchNotifications();
  }

  Future<void> _fetchNotifications({int retryCount = 0}) async {
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      clearNotifications();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await ApiService().getUserNotifications();
      if (mounted) {
        if (!auth.isAuthenticated) {
          clearNotifications();
          return;
        }
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (retryCount < 2) {
        await Future.delayed(Duration(milliseconds: 400 * (retryCount + 1)));
        if (mounted) {
          return _fetchNotifications(retryCount: retryCount + 1);
        }
      }
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  String _formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative || difference.inMinutes < 1) {
      return '1 min ago';
    }

    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '$hrs ${hrs == 1 ? 'hr' : 'hr'} ago';
    } else {
      final days =
          difference.inDays > 0 ? difference.inDays : (difference.inHours ~/ 24);
      final count = days > 0 ? days : 1;
      return '$count ${count == 1 ? 'day' : 'days'} ago';
    }
  }

  IconData _getIconForType(String type) {
    final normalized = type.trim().toLowerCase();
    switch (normalized) {
      case 'ordered':
        return Icons.shopping_bag_outlined;
      case 'packed':
        return Icons.inventory_2_outlined;
      case 'out_for_delivery':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.local_shipping;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated && _notifications.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        clearNotifications();
      });
    }

    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'notifications'),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: AppTheme.darkGreen,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      if (unreadCount > 0 && authProvider.isAuthenticated)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGreenBadge,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$unreadCount New',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isLoading && authProvider.isAuthenticated)
                    const NotificationsScreenSkeleton()
                  else if (_errorMessage != null &&
                      _notifications.isEmpty &&
                      authProvider.isAuthenticated)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 36,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 56,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to load notifications',
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchNotifications,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.darkGreen,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_notifications.isEmpty || !authProvider.isAuthenticated)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none_outlined,
                            size: 64,
                            color: AppTheme.darkGreen.withAlpha(76),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No notifications',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You have no new notifications at this time.',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildNotificationCard(_notifications[index]);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? extractOrderIdFromNotification(NotificationModel item) {
    if (item.orderId != null) {
      final str = item.orderId.toString().trim();
      if (str.isNotEmpty) {
        final digits = str.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) return digits;
      }
    }

    final text = '${item.title} ${item.content}';
    final RegExp regex = RegExp(
      r'(?:#GFM-|\bGFM-|\bOrder\s*#?\s*|#)(\d+)',
      caseSensitive: false,
    );

    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(1);
    }

    return null;
  }

  void _markAsRead(NotificationModel item) {
    if (item.isRead) return;
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == item.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  Widget _buildNotificationCard(NotificationModel item) {
    final relativeTime = _formatRelativeTime(item.createdAt);
    final iconData = _getIconForType(item.type);
    final isUnread = !item.isRead;
    final orderId = extractOrderIdFromNotification(item);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEEEEEE),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _markAsRead(item);
              if (orderId != null && orderId.isNotEmpty) {
                OrderDetailsDialog.show(
                  context,
                  orderId,
                  notificationId: item.id,
                );
              }
            },
            child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                color: AppTheme.darkGreen,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCE7D9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: AppTheme.darkGreen,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF2D3748),
                                    ),
                                  ),
                                ),
                                if (relativeTime.isNotEmpty) ...[
                                  Text(
                                    relativeTime,
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      color: const Color(0xFF718096),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (isUnread)
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.darkGreen,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.content,
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: const Color(0xFF555555),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}
