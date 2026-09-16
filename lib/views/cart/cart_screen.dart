import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_drawer.dart';
import '../widgets/custom_network_image.dart';

import '../item_details/item_details_screen.dart';
import '../profile/delivery_address_screen.dart';
import '../../models/sub_category_item.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartProvider>(context, listen: false).fetchCartItems();
    });
  }

  List<String> _generateCartItemOptions(SubCategoryItem item) {
    final maxStock = item.effectiveStock.clamp(1, 50);
    final List<String> list = [];

    if (item.isQuantityType) {
      for (int i = 1; i <= maxStock; i++) {
        list.add('$i Qty');
      }
    } else {
      final int totalQuarters = maxStock * 4;
      for (int q = 1; q <= totalQuarters; q++) {
        final double kg = q * 0.25;
        if (q == 1) {
          list.add('250g');
        } else if (q == 2) {
          list.add('500g');
        } else if (q == 3) {
          list.add('750g');
        } else {
          if (kg % 1 == 0) {
            list.add('${kg.toInt()}kg');
          } else if ((kg * 10) % 1 == 0) {
            list.add('${kg.toStringAsFixed(1)}kg');
          } else {
            list.add('${kg.toStringAsFixed(2)}kg');
          }
        }
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'cart'),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final items = cartProvider.items;

          return RefreshIndicator(
            onRefresh: () async {
              await cartProvider.fetchCartItems();
            },
            color: AppTheme.darkGreen,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Your Card',
                        style: GoogleFonts.outfit(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      Text(
                        '${cartProvider.itemCount} items',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty) ...[
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
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: AppTheme.darkGreen.withAlpha(76),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your cart is empty',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add items from Home screen to view them here',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final cartItem = items[index];
                        final item = cartItem.item;
                        final options = _generateCartItemOptions(item);

                        String currentSelected = cartItem.selectedWeight;
                        if (!options.contains(currentSelected)) {
                          currentSelected = options.firstWhere(
                            (opt) =>
                                opt == currentSelected ||
                                opt.startsWith('$currentSelected '),
                            orElse: () => options.isNotEmpty
                                ? options.first
                                : (item.isQuantityType ? '1 Qty' : '1kg'),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(8),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ItemDetailsScreen(item: item),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF7F8F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: CustomNetworkImage(
                                    imageUrl: item.image,
                                    itemName: item.subcategoryName,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ItemDetailsScreen(
                                                        item: item,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Text(
                                              item.subcategoryName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textDark,
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.grey,
                                            size: 22,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await cartProvider.removeItemAt(
                                                index,
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              final errorMsg = e
                                                  .toString()
                                                  .replaceAll(
                                                    'Exception: ',
                                                    '',
                                                  );
                                              ScaffoldMessenger.of(context)
                                                  .hideCurrentSnackBar();
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    errorMsg,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                  duration: const Duration(
                                                    seconds: 4,
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Category Label with Icon
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.lightGreenBadge,
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Icon(
                                            item.isQuantityType
                                                ? Icons.numbers_rounded
                                                : Icons.scale_rounded,
                                            size: 14,
                                            color: AppTheme.darkGreen,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.isQuantityType
                                              ? 'Select Quantity:'
                                              : 'Select Weight:',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.darkGreen,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    // Quick Selection Chips Row
                                    if (options.isNotEmpty) ...[
                                      SizedBox(
                                        height: 32,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: options.length > 4
                                              ? 4
                                              : options.length,
                                          itemBuilder: (context, chipIndex) {
                                            final opt = options[chipIndex];
                                            final isOptSelected =
                                                opt == currentSelected;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                right: 6.0,
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  onTap: () async {
                                                    try {
                                                      await cartProvider
                                                          .updateItemWeight(
                                                            item.id,
                                                            opt,
                                                          );
                                                    } catch (e) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      final errorMsg = e
                                                          .toString()
                                                          .replaceAll(
                                                            'Exception: ',
                                                            '',
                                                          );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).hideCurrentSnackBar();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            errorMsg,
                                                            style:
                                                                GoogleFonts.outfit(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                          duration:
                                                              const Duration(
                                                                seconds: 4,
                                                              ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: AnimatedContainer(
                                                    duration: const Duration(
                                                      milliseconds: 150,
                                                    ),
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isOptSelected
                                                          ? AppTheme.darkGreen
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            16,
                                                          ),
                                                      border: Border.all(
                                                        color: isOptSelected
                                                            ? AppTheme.darkGreen
                                                            : AppTheme.darkGreen
                                                                  .withAlpha(
                                                                    40,
                                                                  ),
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        opt,
                                                        style: GoogleFonts.outfit(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              isOptSelected
                                                              ? FontWeight.bold
                                                              : FontWeight.w600,
                                                          color: isOptSelected
                                                              ? Colors.white
                                                              : AppTheme
                                                                    .textDark,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],

                                    // Modern Card Dropdown Selector
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.darkGreen.withAlpha(
                                            50,
                                          ),
                                          width: 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withAlpha(6),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(
                                              color: AppTheme.lightGreenBadge,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              item.isQuantityType
                                                  ? Icons
                                                        .shopping_basket_rounded
                                                  : Icons.balance_rounded,
                                              size: 16,
                                              color: AppTheme.darkGreen,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: DropdownButtonHideUnderline(
                                              child: DropdownButton<String>(
                                                value: currentSelected,
                                                isExpanded: true,
                                                isDense: true,
                                                icon: const Icon(
                                                  Icons.unfold_more_rounded,
                                                  color: AppTheme.darkGreen,
                                                  size: 20,
                                                ),
                                                style: GoogleFonts.outfit(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.textDark,
                                                ),
                                                items: options.map((opt) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: opt,
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          opt,
                                                          style: GoogleFonts.outfit(
                                                            fontSize: 14,
                                                            fontWeight:
                                                                opt ==
                                                                    currentSelected
                                                                ? FontWeight
                                                                      .bold
                                                                : FontWeight
                                                                      .w500,
                                                            color:
                                                                opt ==
                                                                    currentSelected
                                                                ? AppTheme
                                                                      .darkGreen
                                                                : AppTheme
                                                                      .textDark,
                                                          ),
                                                        ),
                                                        if (opt ==
                                                            currentSelected)
                                                          const Icon(
                                                            Icons
                                                                .check_circle_rounded,
                                                            size: 15,
                                                            color: AppTheme
                                                                .darkGreen,
                                                          ),
                                                      ],
                                                    ),
                                                  );
                                                }).toList(),
                                                onChanged: (newValue) async {
                                                  if (newValue != null) {
                                                    try {
                                                      await cartProvider
                                                          .updateItemWeight(
                                                            item.id,
                                                            newValue,
                                                          );
                                                    } catch (e) {
                                                      if (!context.mounted) {
                                                        return;
                                                      }
                                                      final errorMsg = e
                                                          .toString()
                                                          .replaceAll(
                                                            'Exception: ',
                                                            '',
                                                          );
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).hideCurrentSnackBar();
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
                                                          content: Text(
                                                            errorMsg,
                                                            style:
                                                                GoogleFonts.outfit(
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                          duration:
                                                              const Duration(
                                                                seconds: 4,
                                                              ),
                                                          behavior:
                                                              SnackBarBehavior
                                                                  .floating,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // Dynamic Price Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB5ED66),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '₹${cartItem.totalPrice.toStringAsFixed(2)}/$currentSelected',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    _buildAddressSection(context, cartProvider),
                    const SizedBox(height: 20),
                    _buildPaymentMethodSection(context, cartProvider),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Summary',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Color(0xFFEEEEEE), height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Subtotal (${cartProvider.itemCount} items)',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                '₹${cartProvider.subtotal.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          if (cartProvider.deliveryFee > 0) ...[
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Delivery Fee',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  '₹${cartProvider.deliveryFee.toStringAsFixed(2)}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFFEEEEEE), height: 1),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                '₹${cartProvider.grandTotal.toStringAsFixed(2)}',
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order placed successfully!',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppTheme.darkGreen,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Place Order',
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, CartProvider cartProvider) {
    final details = cartProvider.checkoutDetails;
    final isLoading = cartProvider.isLoadingCheckout;
    final addr = details?.deliveryAddress;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: AppTheme.darkGreen,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Delivery Address',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DeliveryAddressScreen(),
                    ),
                  );
                  if (context.mounted) {
                    Provider.of<CartProvider>(
                      context,
                      listen: false,
                    ).fetchCheckoutDetails();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.darkGreen, width: 1.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Edit',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ),
            ),
          ] else if (addr != null) ...[
            if (addr.fullName.isNotEmpty) ...[
              Text(
                addr.fullName,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
            ],
            if (addr.formattedAddressLines.isNotEmpty) ...[
              Text(
                addr.formattedAddressLines,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            if (addr.phoneNumber.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Phone: ${addr.phoneNumber}',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ] else ...[
            Text(
              cartProvider.checkoutError ??
                  'No default address found. Please add or select an address.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection(
    BuildContext context,
    CartProvider cartProvider,
  ) {
    final details = cartProvider.checkoutDetails;
    final isLoading = cartProvider.isLoadingCheckout;
    final methods = details?.paymentMethods ?? [];
    final selectedMethod = methods.isNotEmpty ? methods.first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ),
            ),
          ] else if (selectedMethod != null) ...[
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
                          selectedMethod.displayTitle,
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
                  if (selectedMethod.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 32),
                      child: Text(
                        selectedMethod.description,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
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
                          'Cash on Delivery (COD)',
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
                      "Pay when your fresh produce arrives at your door. We accept exact cash or card via our driver's terminal.",
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
        ],
      ),
    );
  }
}
