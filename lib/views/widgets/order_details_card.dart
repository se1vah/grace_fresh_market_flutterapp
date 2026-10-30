import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/order_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/invoice_service.dart';
import '../../theme/app_theme.dart';
import 'custom_network_image.dart';
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

  const OrderDetailsCard.skeleton({super.key, this.margin})
    : order = null,
      initiallyExpanded = false,
      isLoading = true;

  @override
  State<OrderDetailsCard> createState() => _OrderDetailsCardState();
}

class _OrderDetailsCardState extends State<OrderDetailsCard> {
  late bool _isExpanded;
  bool _isDownloadingInvoice = false;

  Future<void> _handleDownloadInvoice(OrderModel order) async {
    if (_isDownloadingInvoice) return;
    setState(() {
      _isDownloadingInvoice = true;
    });

    try {
      UserModel? user;
      try {
        user = Provider.of<AuthProvider>(context, listen: false).user;
      } catch (_) {}

      await InvoiceService.downloadInvoice(
        context: context,
        order: order,
        user: user,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingInvoice = false;
        });
      }
    }
  }

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

  DateTime? _parseOrderDateTime(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) {
      return null;
    }
    try {
      String cleaned = rawDate.trim();
      // If the backend serialized local time with 'Z' or '+00:00',
      // strip the UTC designator so Dart parses the exact local clock time
      // without adding the device's local timezone offset again.
      if (cleaned.endsWith('Z') || cleaned.endsWith('z')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
      cleaned = cleaned.replaceAll(RegExp(r'[+-]00:?00$'), '');
      return DateTime.parse(cleaned);
    } catch (_) {
      try {
        return DateTime.tryParse(rawDate);
      } catch (_) {
        return null;
      }
    }
  }

  String _formatMainDate(String? rawDate) {
    final dt = _parseOrderDateTime(rawDate);
    if (dt == null) {
      return '';
    }
    try {
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
    final dt = _parseOrderDateTime(rawDate);
    if (dt == null) {
      return '';
    }
    try {
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
    final isCancelled = statusLower.contains('cancel') ||
        statusLower.contains('canceled') ||
        order.statusHistory.any(
          (s) =>
              s.status.toLowerCase().contains('cancel') ||
              s.status.toLowerCase().contains('canceled'),
        );

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
              // Left Border Accent (Red for Cancelled, Grey for Delivered, Dark Green for In Progress)
              Container(
                width: 5,
                color: isCancelled
                    ? const Color(0xFFDC2626)
                    : (isDelivered
                        ? const Color(0xFF6B7280)
                        : const Color(0xFF1E6838)),
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
                            'Order #GFM-${order.id}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                          _buildStatusPill(
                            isDelivered,
                            isCancelled,
                            order.currentStatus,
                          ),
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

                      // View Order Toggle Row & Download Invoice Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
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
                          InkWell(
                            onTap: _isDownloadingInvoice
                                ? null
                                : () => _handleDownloadInvoice(order),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isDownloadingInvoice)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppTheme.darkGreen,
                                            ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.download_rounded,
                                      size: 18,
                                      color: AppTheme.darkGreen,
                                    ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Download Invoice',
                                    style: GoogleFonts.outfit(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.darkGreen,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildStatusPill(
    bool isDelivered,
    bool isCancelled,
    String currentStatus,
  ) {
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cancel_outlined,
              size: 15,
              color: Color(0xFFDC2626),
            ),
            const SizedBox(width: 5),
            Text(
              'Cancelled',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      );
    } else if (isDelivered) {
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

    final Map<String, StatusHistoryItemModel> historyMap = {};
    for (var item in statusList) {
      final key = item.status.toLowerCase().trim();
      historyMap[key] = item;
    }

    final currentStatusNorm = order.currentStatus.toLowerCase().trim();
    final bool isDelivered = currentStatusNorm == 'delivered' ||
        currentStatusNorm.contains('delivered');
    final bool isCancelled = currentStatusNorm.contains('cancel') ||
        currentStatusNorm.contains('canceled') ||
        historyMap.containsKey('cancelled') ||
        historyMap.containsKey('canceled');

    final List<Map<String, dynamic>> stepsDef;
    int highestCompletedIndex = -1;

    if (isCancelled) {
      final List<Map<String, dynamic>> cancelledSteps = [
        {
          'key': 'ordered',
          'title': 'Ordered',
          'subtitle': 'Your Order has been placed.',
          'isCancelledStep': false,
        },
      ];

      if (historyMap.containsKey('packed') ||
          historyMap.containsKey('processed')) {
        cancelledSteps.add({
          'key': 'packed',
          'title': 'Packed',
          'subtitle': 'Seller has processed your order.',
          'isCancelledStep': false,
        });
      }

      if (historyMap.containsKey('out for delivery') ||
          historyMap.containsKey('out_for_delivery') ||
          historyMap.containsKey('out-for-delivery')) {
        cancelledSteps.add({
          'key': 'out for delivery',
          'title': 'Out for Delivery',
          'subtitle': 'Your item is out for delivery',
          'isCancelledStep': false,
        });
      }

      cancelledSteps.add({
        'key': 'cancelled',
        'title': 'Cancelled',
        'subtitle': 'Your order has been cancelled.',
        'isCancelledStep': true,
      });

      stepsDef = cancelledSteps;
      highestCompletedIndex = stepsDef.length - 1;
    } else {
      stepsDef = [
        {
          'key': 'ordered',
          'title': 'Ordered',
          'subtitle': 'Your Order has been placed.',
          'isCancelledStep': false,
        },
        {
          'key': 'packed',
          'title': 'Packed',
          'subtitle': 'Seller has processed your order.',
          'isCancelledStep': false,
        },
        {
          'key': 'out for delivery',
          'title': 'Out for Delivery',
          'subtitle': 'Your item is out for delivery',
          'isCancelledStep': false,
        },
        {
          'key': 'delivered',
          'title': 'Delivered',
          'subtitle': 'Your item has been delivered',
          'isCancelledStep': false,
        },
      ];

      for (int i = 0; i < stepsDef.length; i++) {
        final key = stepsDef[i]['key'] as String;
        if (historyMap.containsKey(key)) {
          highestCompletedIndex = i;
        }
      }

      final bool isOutForDelivery = !isDelivered &&
          (currentStatusNorm == 'out for delivery' ||
              currentStatusNorm == 'out_for_delivery' ||
              currentStatusNorm == 'out-for-delivery' ||
              currentStatusNorm.contains('out') ||
              (currentStatusNorm.contains('delivery') && !isDelivered));

      final bool isPacked = !isDelivered &&
          !isOutForDelivery &&
          (currentStatusNorm == 'packed' || currentStatusNorm.contains('pack'));

      if (isDelivered) {
        highestCompletedIndex = 3;
      } else if (isOutForDelivery) {
        if (highestCompletedIndex < 2) highestCompletedIndex = 2;
      } else if (isPacked) {
        if (highestCompletedIndex < 1) highestCompletedIndex = 1;
      } else if (highestCompletedIndex < 0) {
        highestCompletedIndex = 0;
      }
    }

    // Determine when to show the ETA highlight message
    final bool showOnPacked = !isDelivered &&
        !isCancelled &&
        (highestCompletedIndex == 1);
    final bool showOnOutForDelivery = !isDelivered &&
        !isCancelled &&
        (highestCompletedIndex == 2);

    return Column(
      children: List.generate(stepsDef.length, (index) {
        final step = stepsDef[index];
        final key = step['key'] as String;
        final bool isCancelledStep = step['isCancelledStep'] == true;
        final isCompleted = index <= highestCompletedIndex;
        final historyItem = historyMap[key];

        String? dateStr;
        if (key == 'ordered') {
          dateStr = historyItem?.createdAt ?? order.effectiveCreatedAt;
        } else if (key == 'cancelled') {
          dateStr = historyItem?.createdAt ??
              historyMap['canceled']?.createdAt ??
              (order.orderStatus != null &&
                      order.orderStatus!.status.toLowerCase().contains('cancel')
                  ? order.orderStatus!.createdAt
                  : null) ??
              order.updatedAt ??
              order.effectiveCreatedAt;
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

        String? stepHighlightMessage;
        if (showOnPacked && key == 'packed') {
          stepHighlightMessage = 'The order will arrive within 20–30 minutes.';
        } else if (showOnOutForDelivery && key == 'out for delivery') {
          stepHighlightMessage = 'The order will arrive within 20–30 minutes.';
        }

        return _buildTimelineStepItem(
          title: step['title'] as String,
          subtitle: step['subtitle'] as String,
          dateTimeStr: formattedTime,
          isCompleted: isCompleted,
          isLast: isLast,
          isCancelledStep: isCancelledStep,
          highlightMessage: stepHighlightMessage,
        );
      }),
    );
  }

  Widget _buildHighlightedEtaBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF81C784).withAlpha(160),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.access_time_filled_rounded,
            size: 16,
            color: Color(0xFF1B5E20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1B5E20),
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStepItem({
    required String title,
    required String subtitle,
    required String dateTimeStr,
    required bool isCompleted,
    required bool isLast,
    bool isCancelledStep = false,
    String? highlightMessage,
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
                    color: isCancelledStep
                        ? const Color(0xFFDC2626)
                        : (isCompleted
                            ? const Color(0xFF22C55E)
                            : Colors.white),
                    border: Border.all(
                      color: isCancelledStep
                          ? const Color(0xFFDC2626)
                          : (isCompleted
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF9CA3AF)),
                      width: 1.8,
                    ),
                  ),
                  child: isCancelledStep
                      ? const Center(
                          child: Icon(
                            Icons.close,
                            size: 10,
                            color: Colors.white,
                          ),
                        )
                      : null,
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
                            color: isCancelledStep
                                ? const Color(0xFFDC2626)
                                : (isCompleted
                                    ? const Color(0xFF374151)
                                    : const Color(0xFF4B5563)),
                          ),
                        ),
                        if (dateTimeStr.isNotEmpty)
                          TextSpan(
                            text: '  $dateTimeStr',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isCancelledStep
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF9CA3AF),
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
                      color: isCancelledStep
                          ? const Color(0xFFDC2626).withAlpha(200)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                  if (highlightMessage != null && highlightMessage.isNotEmpty)
                    _buildHighlightedEtaBanner(highlightMessage),
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
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isDownloadingInvoice
                ? null
                : () => _handleDownloadInvoice(order),
            icon: _isDownloadingInvoice
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.picture_as_pdf_outlined, size: 20),
            label: Text(
              _isDownloadingInvoice
                  ? 'Generating Invoice...'
                  : 'Download Invoice',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
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
      addr?['address'],
    ]);

    String line2 = '';
    final streetName = getNonEmpty([
      addr?['streetName'],
      addr?['addressLine2'],
    ]);
    final city = getNonEmpty([addr?['city']]);
    final state = getNonEmpty([addr?['state']]);
    final pincode = getNonEmpty([
      addr?['pincode'],
      addr?['pinCode'],
      addr?['zip'],
    ]);

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
    final imageUrl = item.images.isNotEmpty ? item.images.first : '';
    final name = item.subcategoryName ?? 'Item';
    final qtyDisplay = item.formattedQuantityDisplay;
    final unitPrice =
        item.subcategoryAmount ??
        (item.itemTotal / (item.quantity > 0 ? item.quantity : 1));
    final itemTotal = item.itemTotal;
    final totalOrig = item.totalOriginalAmount;
    final totalOffer = item.totalOfferAmount;
    final hasOffer = item.hasOffer;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F3),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: CustomNetworkImage(
              imageUrl: imageUrl,
              itemName: name,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBadge,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        qtyDisplay,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Price: \u20b9${unitPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (hasOffer && totalOffer > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\u20b9${totalOrig.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF9CA3AF),
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offer Savings: -\u20b9${totalOffer.toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Actual Amount',
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '\u20b9${itemTotal.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndTotalSection(OrderModel order) {
    final rawPayment =
        (order.paymentMethod?['name'] ??
                order.paymentMethod?['type'] ??
                order.paymentMethod?['paymentType'] ??
                'COD')
            .toString();

    final paymentTitle =
        rawPayment.toLowerCase().contains('cod') ||
            rawPayment.toLowerCase().contains('cash')
        ? 'Cash on Delivery (COD)'
        : rawPayment;

    final origSub = order.calculatedOriginalSubTotal;
    final offerSav = order.calculatedTotalSavings;
    final subTotal = order.calculatedSubTotal;
    final isFreeDel = order.isFreeDelivery;
    final baseDel = order.baseDeliveryFee;
    final deliveryFee = order.deliveryFee;
    final grandTotal = order.effectiveAmount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dedicated Payment Method Container
        Text(
          'Payment Method',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAF5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.darkGreen.withAlpha(180),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.radio_button_checked,
                    color: AppTheme.darkGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: AppTheme.darkGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      paymentTitle,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5ED66),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Selected',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  'Pay when your fresh produce arrives at your door. We accept exact cash or card via our driver\'s terminal.',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Order Calculations section matching attached screenshot
        if (offerSav > 0) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original Subtotal',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                '\u20b9${origSub.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.discount_outlined,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Total Offer Savings',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
              Text(
                '-\u20b9${offerSav.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Subtotal (${order.items.length} items)',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              '\u20b9${subTotal.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Fee',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
              ),
            ),
            if (isFreeDel)
              Row(
                children: [
                  Text(
                    '\u20b9${baseDel.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF9CA3AF),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'FREE',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                ],
              )
            else
              Text(
                '\u20b9${deliveryFee.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDark,
                ),
              ),
          ],
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Color(0xFFEEEEEE), height: 1),
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              '\u20b9${grandTotal.toStringAsFixed(2)}',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
          ],
        ),

        // Green Savings Banner
        if (offerSav > 0) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'You save \u20b9${offerSav.toStringAsFixed(2)} on this order!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B5E20),
              ),
            ),
          ),
        ],
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
                      const SkeletonBox(
                        width: 130,
                        height: 20,
                        borderRadius: 4,
                      ),
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
                                    padding: const EdgeInsets.only(
                                      bottom: 14.0,
                                    ),
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
