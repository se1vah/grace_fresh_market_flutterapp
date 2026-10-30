import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_drawer.dart';
import '../widgets/custom_network_image.dart';

import '../item_details/item_details_screen.dart';
import '../profile/delivery_address_screen.dart';
import '../../models/sub_category_item.dart';
import '../../models/cart_item.dart';
import '../widgets/skeleton_loader.dart';
import 'order_placed_page.dart';
import '../no_internet_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacingOrder = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      cartProvider.fetchCartItems();
      cartProvider.fetchCheckoutDetails();
    });
  }

  Future<void> _handlePlaceOrder() async {
    if (_isPlacingOrder) return;

    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    if (cartProvider.checkoutDetails?.deliveryAddress == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add or select a delivery address before placing your order.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    try {
      final orderResponse = await cartProvider.placeOrder();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderPlacedPage(orderData: orderResponse),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMsg,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
      }
    }
  }

  List<String> _generateCartItemOptions(SubCategoryItem item) {
    if (item.isOutOfStock) return [];
    final maxStock = item.effectiveStock.clamp(1, 50);
    final List<String> list = [];

    if (item.isQuantityType) {
      for (int i = 1; i <= maxStock; i++) {
        list.add('$i Qty');
      }
    } else if (item.isGramType) {
      if (maxStock >= 0.25) list.add('250 G');
      if (maxStock >= 0.5) list.add('500 G');
      if (maxStock >= 0.75) list.add('750 G');
      for (double kg = 1.0; kg <= maxStock + 0.0001; kg += 0.5) {
        if (kg % 1 == 0) {
          list.add('${kg.toInt()} KG');
        } else {
          list.add('${kg.toStringAsFixed(1)} KG');
        }
      }
    } else {
      final unit = item.displayUnit;
      for (int i = 1; i <= maxStock; i++) {
        list.add(unit.isNotEmpty ? '$i $unit' : '$i');
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
          if (cartProvider.isLoading) {
            return const CartScreenSkeleton();
          }

          if (cartProvider.hasNetworkError && cartProvider.items.isEmpty) {
            return NoInternetScreen(
              showBackButton: false,
              onRetry: () {
                cartProvider.fetchCartItems();
                cartProvider.fetchCheckoutDetails();
              },
            );
          }

          final items = cartProvider.items;

          return RefreshIndicator(
            onRefresh: () async {
              await cartProvider.fetchCartItems();
              await cartProvider.fetchCheckoutDetails();
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

                        String currentSelected = getOptionForCartItem(cartItem, options);
                        if (!options.contains(currentSelected)) {
                          options.add(currentSelected);
                          options.sort((a, b) => parseQuantityFromWeight(a, 0)
                              .compareTo(parseQuantityFromWeight(b, 0)));
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

                                    // Pricing & Offer Details Container
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F8F6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppTheme.darkGreen.withAlpha(30),
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Unit Price (Original Amount & Final Amount) + Offer % Badge
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Text(
                                                    '\u20b9${item.unitFinalPrice.toStringAsFixed(2)}',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.darkGreen,
                                                    ),
                                                  ),
                                                  Text(
                                                    item.priceUnitSuffix,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 12,
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                  ),
                                                  if (cartItem.hasOffer) ...[
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '\u20b9${item.unitOriginalPrice.toStringAsFixed(2)}',
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                        color: AppTheme.textSecondary,
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              if (cartItem.hasOffer)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF5252).withAlpha(25),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '${item.effectiveOfferPercentage.toStringAsFixed(0)}% OFF',
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: const Color(0xFFD32F2F),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          const Divider(height: 1, color: Color(0xFFE0E0E0)),
                                          const SizedBox(height: 6),
                                          // Item Total Row
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Item Total (${cartItem.selectedWeight})',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppTheme.textDark,
                                                ),
                                              ),
                                              Text(
                                                '\u20b9${cartItem.totalPrice.toStringAsFixed(2)}',
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
                          if (cartProvider.totalSavings > 0) ...[
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
                                  '\u20b9${cartProvider.originalSubtotal.toStringAsFixed(2)}',
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
                                  '-\u20b9${cartProvider.totalSavings.toStringAsFixed(2)}',
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
                                'Subtotal (${cartProvider.itemCount} items)',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                '\u20b9${cartProvider.subtotal.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                          if (cartProvider.items.isNotEmpty) ...[
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
                                if (cartProvider.isFreeDelivery)
                                  Row(
                                    children: [
                                      Text(
                                        '\u20b9${cartProvider.baseDeliveryFee.toStringAsFixed(2)}',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'FREE',
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2E7D32),
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Text(
                                    '\u20b9${cartProvider.deliveryFee.toStringAsFixed(2)}',
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
                                '\u20b9${cartProvider.grandTotal.toStringAsFixed(2)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGreen,
                                ),
                              ),
                            ],
                          ),
                          if (cartProvider.totalSavings > 0) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You save \u20b9${cartProvider.totalSavings.toStringAsFixed(2)} on this order!',
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
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _handlePlaceOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkGreen,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
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
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 140, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 200, height: 14, borderRadius: 4),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ] else if (addr != null) ...[
            Builder(
              builder: (context) {
                final user = Provider.of<AuthProvider>(context, listen: false).user;
                final name = addr.fullName.trim().isNotEmpty
                    ? addr.fullName.trim()
                    : (user?.fullName.trim() ?? '');
                final phone = addr.phoneNumber.trim().isNotEmpty
                    ? addr.phoneNumber.trim()
                    : (user?.phoneNumber.trim() ?? '');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name.isNotEmpty) ...[
                      Text(
                        name,
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
                    if (phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Phone: $phone',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
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
              padding: EdgeInsets.symmetric(vertical: 6.0),
              child: SkeletonBox(
                width: double.infinity,
                height: 60,
                borderRadius: 12,
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
