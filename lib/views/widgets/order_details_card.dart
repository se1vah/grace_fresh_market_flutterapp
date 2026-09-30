import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'skeleton_loader.dart';

class OrderDetailsCard extends StatefulWidget {
  final OrderModel? order;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;

  const OrderDetailsCard({
    super.key,
    this.order,
    this.initiallyExpanded = false,
    this.margin,
    this.isLoading = false,
  });

  const OrderDetailsCard.skeleton({
    super.key,
    this.margin,
  })  : order = null,
        initiallyExpanded = false,
        isLoading = true;

  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<OrderDetailsCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(covariant OrderDetailsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      setState(() {
        _isExpanded = widget.initiallyExpanded;
      });
    }
  }

  String _formatMainDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return '';
    }
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatStepDateTime(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) {
      return '';
    }
    try {
      final dt = DateTime.parse(rawDate).toLocal();
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      final dayName = days[dt.weekday - 1];
      final monthName = months[dt.month - 1];

      String daySuffix = 'th';
      if (dt.day == 1 || dt.day == 21 || dt.day == 31) {
        daySuffix = 'st';
      } else if (dt.day == 2 || dt.day == 22) {
        daySuffix = 'nd';
      } else if (dt.day == 3 || dt.day == 23) {
        daySuffix = 'rd';
      }

      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';

      return '$dayName, ${dt.day}$daySuffix $monthName ${dt.year} $hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading || widget.order == null) {
      return _buildSkeletonCard(context);
    }

    final order = widget.order!;
    final statusLower = order.currentStatus.toLowerCase();
    final isDelivered = statusLower == 'delivered';

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Solid Green Border Accent
              Container(
                width: 5,
                color: const Color(0xFF1E6838),
              ),
              // Card Body Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Order # on left, Status Pill on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${order.id}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          _buildStatusPill(isDelivered, order.currentStatus),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Main Date Display Header e.g. Sep 25, 2026
                      Text(
                        _formatMainDate(order.effectiveCreatedAt),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),

                      // Order History Timeline Steps
                      _buildTimeline(order),

                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 14),

                      // View Order Toggle Row
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View Order',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              _isExpanded
                                  ? Icons.keyboard_arrow_up
                                  : Icons.expand_more,
                              size: 20,
                              color: AppTheme.darkGreen,
                            ),
                          ],
                        ),
                      ),

                      // Expanded Order Details Section
                      if (_isExpanded) _buildExpandedOrderDetails(order),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(bool isDelivered, String currentStatus) {
    if (isDelivered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 15, color: Color(0xFF374151)),
            const SizedBox(width: 5),
            Text(
              'Delivered',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF374151),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              size: 15,
              color: Color(0xFF386626),
            ),
            const SizedBox(width: 5),
            Text(
              'In Progress',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF386626),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTimeline(OrderModel order) {
    final statusList = order.statusHistory;

    final stepsDef = [
      {
        'key': 'ordered',
        'title': 'Ordered',
        'subtitle': 'Your Order has been placed.',
      },
      {
        'key': 'packed',
        'title': 'Packed',
        'subtitle': 'Seller has processed your order.',
      },
      {
        'key': 'out for delivery',
        'title': 'Out for Delivery',
        'subtitle': 'Your item is out for delivery',
      },
      {
        'key': 'delivered',
        'title': 'Delivered',
        'subtitle': 'Your item has been delivered',
      },
    ];

    final Map<String, StatusHistoryItemModel> historyMap = {};
    for (var item in statusList) {
      final key = item.status.toLowerCase().trim();
      historyMap[key] = item;
    }

    int highestCompletedIndex = -1;
    for (int i = 0; i < stepsDef.length; i++) {
      final key = stepsDef[i]['key']!;
      if (historyMap.containsKey(key)) {
        highestCompletedIndex = i;
      }
    }

    final currentStatusLower = order.currentStatus.toLowerCase();
    if (currentStatusLower == 'delivered') {
      highestCompletedIndex = 3;
    } else if (currentStatusLower.contains('out') || currentStatusLower.contains('delivery')) {
      if (highestCompletedIndex < 2) highestCompletedIndex = 2;
    } else if (currentStatusLower == 'packed') {
      if (highestCompletedIndex < 1) highestCompletedIndex = 1;
    } else if (highestCompletedIndex < 0) {
      highestCompletedIndex = 0;
    }

    return Column(
      children: List.generate(stepsDef.length, (index) {
        final step = stepsDef[index];
        final key = step['key']!;
        final isCompleted = index <= highestCompletedIndex;
        final historyItem = historyMap[key];

        String? dateStr;
        if (key == 'ordered') {
          dateStr = historyItem?.createdAt ?? order.effectiveCreatedAt;
        } else if (historyItem != null &&
            historyItem.createdAt != null &&
            historyItem.createdAt!.isNotEmpty) {
          dateStr = historyItem.createdAt;
        } else if (isCompleted &&
            key == 'delivered' &&
            order.effectiveCreatedAt != null) {
          dateStr = order.orderStatus?.createdAt ?? order.effectiveCreatedAt;
        }

        final formattedTime = _formatStepDateTime(dateStr);
        final isLast = index == stepsDef.length - 1;

        return _buildTimelineStepItem(
          title: step['title']!,
          subtitle: step['subtitle']!,
          dateTimeStr: formattedTime,
          isCompleted: isCompleted,
          isLast: isLast,
        );
      }),
    );
  }

  Widget _buildTimelineStepItem({
    required String title,
    required String subtitle,
    required String dateTimeStr,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? const Color(0xFF22C55E) : Colors.white,
                    border: Border.all(
                      color: isCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFF9CA3AF),
                      width: 1.8,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: isCompleted
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: title,
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isCompleted
                                ? const Color(0xFF374151)
                                : const Color(0xFF4B5563),
                          ),
                        ),
                        if (dateTimeStr.isNotEmpty)
                          TextSpan(
                            text: '  $dateTimeStr',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedOrderDetails(OrderModel order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildDeliveryAddressSection(order),
        const SizedBox(height: 16),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 16),
        _buildOrderSummarySection(order),
        const SizedBox(height: 8),
        const Divider(height: 1, color: Color(0xFFF0F0F0)),
        const SizedBox(height: 16),
        _buildPaymentAndTotalSection(order),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(OrderModel order) {
    final addr = order.address;
    UserModel? user;
    try {
      user = Provider.of<AuthProvider>(context, listen: false).user;
    } catch (_) {}

    String getNonEmpty(List<dynamic> options) {
      for (var opt in options) {
        if (opt != null && opt.toString().trim().isNotEmpty) {
          return opt.toString().trim();
        }
      }
      return '';
    }

    final name = getNonEmpty([
      addr?['fullName'],
      addr?['full_name'],
      addr?['name'],
      addr?['receiverName'],
      addr?['userName'],
      user?.fullName,
    ]);

    final line1 = getNonEmpty([
      addr?['buildingName'],
      addr?['addressLine1'],
      addr?['street'],
    ]);

    String line2 = '';
    final streetName = getNonEmpty([addr?['streetName'], addr?['addressLine2']]);
    final city = getNonEmpty([addr?['city']]);
    final state = getNonEmpty([addr?['state']]);
    final pincode = getNonEmpty([addr?['pincode'], addr?['pinCode'], addr?['zip']]);

    final line2Parts = <String>[];
    if (streetName.isNotEmpty) line2Parts.add(streetName);
    if (city.isNotEmpty) line2Parts.add(city);
    if (state.isNotEmpty) line2Parts.add(state);
    if (pincode.isNotEmpty) line2Parts.add(pincode);

    if (line2Parts.isNotEmpty) {
      line2 = line2Parts.join(', ');
    }

    final phone = getNonEmpty([
      addr?['mobileNumber'],
      addr?['mobile_number'],
      addr?['phone'],
      addr?['phoneNumber'],
      addr?['phone_number'],
      addr?['mobile'],
      user?.phoneNumber,
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: Color(0xFF111827),
            ),
            const SizedBox(width: 8),
            Text(
              'Delivery Address',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty) ...[
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 3),
              ],
              if (line1.isNotEmpty) ...[
                Text(
                  line1,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
              ],
              if (line2.isNotEmpty) ...[
                Text(
                  line2,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 3),
              ],
              if (phone.isNotEmpty)
                Text(
                  'Phone: $phone',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummarySection(OrderModel order) {
    final items = order.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 20,
              color: Color(0xFF111827),
            ),
            const SizedBox(width: 8),
            Text(
              'Order Summary',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...items.map((item) => _buildOrderItemRow(item)),
      ],
    );
  }

  Widget _buildOrderItemRow(OrderItemModel item) {
    final imageUrl = item.images.isNotEmpty ? item.images.first : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 48,
              height: 48,
              color: const Color(0xFFF9FAFB),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/fresh_basket.jpg',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/images/fresh_basket.jpg',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.subcategoryName ?? 'Item',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.formattedQuantityDisplay,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${item.itemTotal.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndTotalSection(OrderModel order) {
    final paymentName = (order.paymentMethod?['name'] ??
            order.paymentMethod?['type'] ??
            'COD')
        .toString();

    final deliveryFee = order.deliveryFee > 0
        ? order.deliveryFee
        : (order.cartSummary?.deliveryFee ?? 0.0);

    final totalAmount = order.total > 0 ? order.total : order.effectiveAmount;
    final displayTotal = totalAmount;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Method:',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            Text(
              paymentName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
          ],
        ),
        if (deliveryFee > 0) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Fee:',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                '₹${deliveryFee.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            Text(
              '₹${displayTotal.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E6838),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 20.0),
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Solid Green Border Accent Skeleton
              Container(
                width: 5,
                color: const Color(0xFF1E6838).withAlpha(120),
              ),
              // Card Body Content Skeleton
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 18.0, 16.0, 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Order # on left, Status Pill on right
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SkeletonBox(width: 110, height: 16, borderRadius: 4),
                          SkeletonBox(width: 90, height: 26, borderRadius: 16),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Main Date Display Header e.g. Sep 25, 2026
                      const SkeletonBox(width: 130, height: 20, borderRadius: 4),
                      const SizedBox(height: 14),

                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 16),

                      // Order Timeline Steps Skeleton (4 steps)
                      Column(
                        children: List.generate(4, (stepIndex) {
                          final isLast = stepIndex == 3;
                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Node & connecting vertical line
                                SizedBox(
                                  width: 24,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 2),
                                      const SkeletonBox(
                                        width: 16,
                                        height: 16,
                                        shape: BoxShape.circle,
                                      ),
                                      if (!isLast)
                                        Expanded(
                                          child: Container(
                                            width: 2,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 2,
                                            ),
                                            color: const Color(0xFFE5E7EB),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 14.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: const [
                                        Row(
                                          children: [
                                            SkeletonBox(
                                              width: 90,
                                              height: 14,
                                              borderRadius: 4,
                                            ),
                                            SizedBox(width: 10),
                                            SkeletonBox(
                                              width: 120,
                                              height: 12,
                                              borderRadius: 4,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 6),
                                        SkeletonBox(
                                          width: 160,
                                          height: 12,
                                          borderRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 14),

                      // View Order Toggle Row Skeleton
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SkeletonBox(width: 80, height: 16, borderRadius: 4),
                          SizedBox(width: 6),
                          SkeletonBox(width: 16, height: 16, borderRadius: 4),
                        ],
                      ),
                    ],
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

/// Standalone Skeleton loader widget matching OrderDetailsCard
class OrderDetailsCardSkeleton extends StatelessWidget {
  final EdgeInsetsGeometry? margin;

  const OrderDetailsCardSkeleton({super.key, this.margin});

  @override
  Widget build(BuildContext context) {
    return OrderDetailsCard.skeleton(margin: margin);
  }
}
