import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/cart_item.dart';
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

  Map<String, dynamic>? _extractOrderInfo(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }

    // Check if raw is explicitly a failed response
    if (raw['success'] == false || raw['status'] == false) {
      return null;
    }

    // 1. Data root map
    final dataMap = (raw['data'] is Map<String, dynamic>)
        ? raw['data'] as Map<String, dynamic>
        : raw;

    // 2. Order map: response.data.order
    final orderMap = (dataMap['order'] is Map<String, dynamic>)
        ? dataMap['order'] as Map<String, dynamic>
        : (raw['order'] is Map<String, dynamic>
              ? raw['order'] as Map<String, dynamic>
              : null);

    final targetOrder =
        orderMap ??
        (dataMap.containsKey('orderId') || dataMap.containsKey('id')
            ? dataMap
            : null);
    if (targetOrder == null) {
      return null;
    }

    // 3. Order ID: response.data.order.orderId
    final rawOrderId =
        targetOrder['orderId'] ??
        targetOrder['id'] ??
        targetOrder['order_id'] ??
        dataMap['orderId'];

    if (rawOrderId == null) {
      return null;
    }

    String orderIdStr = rawOrderId.toString().trim();
    if (!orderIdStr.startsWith('#')) {
      if (!orderIdStr.toUpperCase().startsWith('GFM-')) {
        orderIdStr = '#GFM-$orderIdStr';
      } else {
        orderIdStr = '#$orderIdStr';
      }
    }

    // 4. Delivery Address: response.data.order.address
    final addressMap = (targetOrder['address'] is Map<String, dynamic>)
        ? targetOrder['address'] as Map<String, dynamic>
        : (dataMap['address'] is Map<String, dynamic>
              ? dataMap['address'] as Map<String, dynamic>
              : <String, dynamic>{});

    final fullName =
        (addressMap['fullName'] ??
                addressMap['full_name'] ??
                addressMap['name'] ??
                '')
            .toString();

    final phoneNumber =
        (addressMap['phoneNumber'] ??
                addressMap['phone_number'] ??
                addressMap['phone'] ??
                '')
            .toString();

    final buildingName =
        (addressMap['buildingName'] ??
                addressMap['building_name'] ??
                addressMap['house'] ??
                '')
            .toString();

    final streetName =
        (addressMap['streetName'] ??
                addressMap['street_name'] ??
                addressMap['street'] ??
                '')
            .toString();

    final city = (addressMap['city'] ?? '').toString();
    final state = (addressMap['state'] ?? '').toString();
    final pincode =
        (addressMap['pincode'] ??
                addressMap['pinCode'] ??
                addressMap['zip'] ??
                '')
            .toString();

    // 5. Order Summary Items: response.data.items
    List<dynamic> rawItems = [];
    if (dataMap['items'] is List) {
      rawItems = dataMap['items'] as List<dynamic>;
    } else if (targetOrder['items'] is List) {
      rawItems = targetOrder['items'] as List<dynamic>;
    } else if (raw['items'] is List) {
      rawItems = raw['items'] as List<dynamic>;
    }

    final parsedItems = rawItems.map<Map<String, dynamic>>((item) {
      final Map<String, dynamic> map = (item is Map<String, dynamic>)
          ? item
          : (item is Map ? Map<String, dynamic>.from(item) : {});

      final subcategoryName =
          (map['subcategoryName'] ??
                  map['subcategory_name'] ??
                  map['name'] ??
                  map['title'] ??
                  'Item')
              .toString();

      String image = '';
      if (map['subcategoryImage'] is List && (map['subcategoryImage'] as List).isNotEmpty) {
        image = (map['subcategoryImage'] as List).first.toString();
      } else if (map['images'] is List && (map['images'] as List).isNotEmpty) {
        image = (map['images'] as List).first.toString();
      } else {
        image = (map['subcategoryImage'] ??
                map['imageUrl'] ??
                map['image_url'] ??
                map['image'] ??
                map['img'] ??
                '')
            .toString();
      }

      final subCategoryType = (map['sub_category_type'] ??
              map['subCategoryType'] ??
              map['subcategory_type'] ??
              map['subcategoryType'] ??
              map['category_type'] ??
              map['categoryType'] ??
              map['unit'] ??
              (map['subcategory'] is Map
                  ? (map['subcategory'] as Map)['sub_category_type'] ??
                        (map['subcategory'] as Map)['category_type']
                  : null))
          ?.toString()
          .trim();

      final rawQty = map['quantity'] ?? map['qty'] ?? map['selectedWeight'] ?? 1;
      final numQty = parseQuantityFromWeight(rawQty.toString(), 1);

      final String displayQty = _formatOrderPlacedQuantity(numQty, rawQty.toString(), subCategoryType);

      final priceNum =
          num.tryParse(
            (map['price'] ?? map['amount'] ?? map['rate'] ?? 0).toString(),
          ) ??
          0.0;

      final itemTotalNum =
          num.tryParse(
            (map['itemTotal'] ??
                    map['item_total'] ??
                    map['total'] ??
                    (priceNum * numQty))
                .toString(),
          ) ??
          (priceNum * numQty);

      return {
        'subcategoryName': subcategoryName,
        'image': image,
        'quantity': displayQty,
        'price': priceNum,
        'itemTotal': itemTotalNum,
      };
    }).toList();

    // 6. Subtotal: response.data.order.subTotal
    final subTotal =
        num.tryParse(
          (targetOrder['subTotal'] ??
                  targetOrder['sub_total'] ??
                  dataMap['subTotal'] ??
                  0)
              .toString(),
        ) ??
        0.0;

    // 7. Delivery Fee: response.data.order.deliveryFee
    final deliveryFee =
        num.tryParse(
          (targetOrder['deliveryFee'] ??
                  targetOrder['delivery_fee'] ??
                  dataMap['deliveryFee'] ??
                  0)
              .toString(),
        ) ??
        0.0;

    // 8. Total: response.data.order.total
    final total =
        num.tryParse(
          (targetOrder['total'] ??
                  targetOrder['grandTotal'] ??
                  dataMap['total'] ??
                  0)
              .toString(),
        ) ??
        (subTotal + deliveryFee);

    // 9. Payment Method: response.data.order.paymentMethod.paymentType
    String paymentType = 'Cash on Delivery';
    if (targetOrder['paymentMethod'] is Map<String, dynamic>) {
      final pm = targetOrder['paymentMethod'] as Map<String, dynamic>;
      paymentType =
          (pm['paymentType'] ??
                  pm['type'] ??
                  pm['method'] ??
                  'Cash on Delivery')
              .toString();
    } else if (targetOrder['paymentMethod'] is String &&
        (targetOrder['paymentMethod'] as String).isNotEmpty) {
      paymentType = targetOrder['paymentMethod'] as String;
    } else if (dataMap['paymentMethod'] is Map<String, dynamic>) {
      final pm = dataMap['paymentMethod'] as Map<String, dynamic>;
      paymentType = (pm['paymentType'] ?? pm['type'] ?? 'Cash on Delivery')
          .toString();
    } else if (dataMap['paymentMethod'] is String &&
        (dataMap['paymentMethod'] as String).isNotEmpty) {
      paymentType = dataMap['paymentMethod'] as String;
    }

    return {
      'orderId': orderIdStr,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'buildingName': buildingName,
      'streetName': streetName,
      'city': city,
      'state': state,
      'pincode': pincode,
      'items': parsedItems,
      'subTotal': subTotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'paymentType': paymentType,
    };
  }

  static String _formatOrderPlacedQuantity(num numQty, String rawQtyStr, String? subCategoryType) {
    final trimmed = rawQtyStr.trim();
    if (trimmed.endsWith('G') || trimmed.endsWith('g') || trimmed.endsWith('KG') || trimmed.endsWith('kg') || trimmed.contains('Qty')) {
      if (trimmed.endsWith('g') && !trimmed.endsWith('kg')) {
        final val = trimmed.replaceAll(RegExp(r'[^0-9.]'), '').trim();
        if (val.isNotEmpty) return '$val G';
      }
      if (trimmed.endsWith('kg') || trimmed.endsWith('KG')) {
        final val = trimmed.replaceAll(RegExp(r'[^0-9.]'), '').trim();
        if (val.isNotEmpty) return '$val KG';
      }
      return trimmed;
    }

    final lowerType = subCategoryType?.toLowerCase().trim();
    final isGram = lowerType == 'gram' || lowerType == 'g';
    final isQuantity = lowerType == 'quantity' || lowerType == 'qty';

    if (isGram || subCategoryType == null || subCategoryType.isEmpty) {
      if ((numQty - 0.25).abs() < 0.0001) return '250 G';
      if ((numQty - 0.5).abs() < 0.0001) return '500 G';
      if ((numQty - 0.75).abs() < 0.0001) return '750 G';
      if (numQty < 1.0) {
        final grams = (numQty * 1000).round();
        return '$grams G';
      }
      final kgStr = numQty % 1 == 0 ? numQty.toInt().toString() : numQty.toString();
      return '$kgStr KG';
    }

    if (isQuantity) {
      final qtyStr = numQty % 1 == 0 ? numQty.toInt().toString() : numQty.toString();
      return '$qtyStr Qty';
    }

    final qtyStr = numQty % 1 == 0 ? numQty.toInt().toString() : numQty.toString();
    return '$qtyStr $subCategoryType';
  }

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
    final info = _extractOrderInfo(orderData);

    // If order info is invalid or failed, display the Error Message View
    if (info == null) {
      return _buildErrorView(context, _extractErrorMessage());
    }

    final items = info['items'] as List<Map<String, dynamic>>;

    // Address formatting lines
    final fullName = info['fullName'] as String;
    final phoneNumber = info['phoneNumber'] as String;
    final buildingName = info['buildingName'] as String;
    final streetName = info['streetName'] as String;
    final city = info['city'] as String;
    final state = info['state'] as String;
    final pincode = info['pincode'] as String;

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
                    text: info['orderId'].toString(),
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

            // Order Details Card
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
                  // Delivery Address Header
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

                  // Delivery Address Lines
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

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Color(0xFFEEEEEE), height: 1),
                  ),

                  // Order Summary Header
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name =
                          item['subcategoryName']?.toString() ?? 'Item';
                      final qty = item['quantity']?.toString() ?? '1';
                      final itemTotal =
                          (item['itemTotal'] as num?)?.toDouble() ?? 0.0;
                      final imgUrl = item['image']?.toString() ?? '';

                      return Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F6F3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: CustomNetworkImage(
                              imageUrl: imgUrl,
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
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  qty,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${itemTotal.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Color(0xFFEEEEEE), height: 1),
                  ),

                  // Payment Method Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method:',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        info['paymentType'].toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

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
                        '₹${(info['total'] as num).toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(initialIndex: 3),
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
