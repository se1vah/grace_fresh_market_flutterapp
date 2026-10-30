import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/order_model.dart';
import '../../services/invoice_service.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';
import '../profile/my_orders_screen.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_bottom_nav_bar.dart';
import '../widgets/grace_drawer.dart';

class OrderPlacedPage extends StatelessWidget {
  final Map<String, dynamic>? orderData;
  final String? errorMessage;

  const OrderPlacedPage({super.key, this.orderData, this.errorMessage});

  String _extractErrorMessage() {
    if (errorMessage != null && errorMessage!.trim().isNotEmpty) {
      return errorMessage!.trim();
    }
    if (orderData != null) {
      if (orderData!['message'] != null &&
          orderData!['message'].toString().trim().isNotEmpty) {
        return orderData!['message'].toString().trim();
      }
      if (orderData!['error'] != null &&
          orderData!['error'].toString().trim().isNotEmpty) {
        return orderData!['error'].toString().trim();
      }
      if (orderData!['errors'] != null &&
          orderData!['errors'].toString().trim().isNotEmpty) {
        return orderData!['errors'].toString().trim();
      }
    }
    return 'Failed to place order or load order details. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    if (orderData == null ||
        orderData!['success'] == false ||
        orderData!['status'] == false) {
      return _buildErrorView(context, _extractErrorMessage());
    }

    final order = OrderModel.fromJson(orderData!);
    if (order.id == null || (order.id == 0 && order.items.isEmpty)) {
      return _buildErrorView(context, _extractErrorMessage());
    }

    String rawId = order.id.toString().trim();
    String displayOrderId = rawId;
    if (!displayOrderId.startsWith('#')) {
      if (!displayOrderId.toUpperCase().startsWith('GFM-')) {
        displayOrderId = '#GFM-$displayOrderId';
      } else {
        displayOrderId = '#$displayOrderId';
      }
    }

    // Address formatting
    final addr = order.address;
    String getNonEmpty(List<dynamic> options) {
      for (var opt in options) {
        if (opt != null && opt.toString().trim().isNotEmpty) {
          return opt.toString().trim();
        }
      }
      return '';
    }

    final fullName = getNonEmpty([
      addr?['fullName'],
      addr?['full_name'],
      addr?['name'],
      addr?['receiverName'],
      addr?['userName'],
    ]);

    final buildingName = getNonEmpty([
      addr?['buildingName'],
      addr?['building_name'],
      addr?['addressLine1'],
      addr?['street'],
      addr?['house'],
    ]);

    final streetName = getNonEmpty([
      addr?['streetName'],
      addr?['street_name'],
      addr?['addressLine2'],
    ]);

    final city = getNonEmpty([addr?['city']]);
    final state = getNonEmpty([addr?['state']]);
    final pincode = getNonEmpty([
      addr?['pincode'],
      addr?['pinCode'],
      addr?['zip'],
    ]);

    final phoneNumber = getNonEmpty([
      addr?['phoneNumber'],
      addr?['phone_number'],
      addr?['phone'],
      addr?['mobile'],
    ]);

    String addressLine1 = '';
    if (buildingName.isNotEmpty && streetName.isNotEmpty) {
      addressLine1 = '$buildingName, $streetName';
    } else if (streetName.isNotEmpty) {
      addressLine1 = streetName;
    } else if (buildingName.isNotEmpty) {
      addressLine1 = buildingName;
    }

    String addressLine2 = '';
    List<String> cityParts = [];
    if (city.isNotEmpty) cityParts.add(city);
    if (state.isNotEmpty) cityParts.add(state);
    if (pincode.isNotEmpty) cityParts.add(pincode);
    addressLine2 = cityParts.join(', ');

    // Payment Method
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

    // Summary calculations
    final items = order.items;
    final origSub = order.calculatedOriginalSubTotal;
    final offerSav = order.calculatedTotalSavings;
    final subTotal = order.calculatedSubTotal;
    final isFreeDel = order.isFreeDelivery;
    final baseDel = order.baseDeliveryFee;
    final deliveryFee = order.deliveryFee;
    final grandTotal = order.effectiveAmount;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'orders'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Success Checkmark Badge
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppTheme.darkGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.limeGreen,
                size: 42,
              ),
            ),
            const SizedBox(height: 16),

            // Order Placed Title
            Text(
              'Order Placed\nSuccessfully!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),

            // Confirmation Subtitle
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Thank you for choosing Grace Fresh Market.\nYour order ',
                  ),
                  TextSpan(
                    text: displayOrderId,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  const TextSpan(text: ' is confirmed.'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Delivery Address Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppTheme.darkGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Delivery Address',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (fullName.isNotEmpty)
                          Text(
                            fullName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        if (addressLine1.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            addressLine1,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (addressLine2.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            addressLine2,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                        if (phoneNumber.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Phone: $phoneNumber',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Payment Method Card (Matching OrderDetailsCard)
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppTheme.darkGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payment Method',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
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
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Order Summary Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.receipt_long_outlined,
                        color: AppTheme.darkGreen,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Order Summary',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Products List in Order Summary
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final imageUrl = item.images.isNotEmpty
                          ? item.images.first
                          : '';
                      final name = item.subcategoryName ?? 'Item';
                      final qtyDisplay = item.formattedQuantityDisplay;
                      final unitPrice =
                          item.subcategoryAmount ??
                          (item.itemTotal /
                              (item.quantity > 0 ? item.quantity : 1));
                      final itemTotal = item.itemTotal;
                      final totalOrig = item.totalOriginalAmount;
                      final totalOffer = item.totalOfferAmount;
                      final hasOffer = item.hasOffer;

                      return Row(
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
                                          decoration:
                                              TextDecoration.lineThrough,
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
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Color(0xFFEEEEEE), height: 1),
                  ),

                  // Order Calculations
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
                        'Subtotal (${items.length} items)',
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

                  // Total Row
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

                  // Green Highlight Savings Banner
                  if (offerSav > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
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
              ),
            ),
            const SizedBox(height: 28),

            // Download Invoice Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  InvoiceService.downloadInvoice(
                    context: context,
                    order: order,
                  );
                },
                icon: const Icon(
                  Icons.picture_as_pdf_outlined,
                  color: AppTheme.darkGreen,
                ),
                label: Text(
                  'Download Invoice',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.darkGreen, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) =>
                          const MainNavigationScreen(initialIndex: 3),
                    ),
                    (route) => false,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const MyOrdersScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.darkGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'View My Order',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  MainNavigationScreen.navigateToTab(context, 0);
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF4A3E3D),
                  side: const BorderSide(color: Color(0xFF4A3E3D), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Continue Shopping',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4A3E3D),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          MainNavigationScreen.navigateToTab(context, index);
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String msg) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'cart'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFDC2626),
                  size: 46,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Order Placement Failed',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFCA5A5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(8),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        msg,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF991B1B),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    MainNavigationScreen.navigateToTab(context, 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.darkGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Cart',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    MainNavigationScreen.navigateToTab(context, 0);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4A3E3D),
                    side: const BorderSide(
                      color: Color(0xFF4A3E3D),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go to Home',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A3E3D),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: 1,
        onTap: (index) {
          MainNavigationScreen.navigateToTab(context, index);
        },
      ),
    );
  }
}
