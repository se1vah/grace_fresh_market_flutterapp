import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/sub_category_item.dart';
import '../../models/cart_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/auth_dialog_helper.dart';
import '../main_navigation_screen.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_bottom_nav_bar.dart';
import '../widgets/grace_drawer.dart';
import '../widgets/custom_network_image.dart';

class ItemDetailsScreen extends StatefulWidget {
  final SubCategoryItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  int _selectedImageIndex = 0;
  late String _selectedOption;
  late List<String> _options;

  @override
  void initState() {
    super.initState();
    _initOptions();
  }

  @override
  void didUpdateWidget(covariant ItemDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.categoryType != widget.item.categoryType ||
        oldWidget.item.stock != widget.item.stock) {
      _initOptions();
    }
  }

  void _initOptions() {
    _options = _generateOptions();
    if (_options.isNotEmpty) {
      if (widget.item.isGramType && (_options.contains('1 KG') || _options.contains('1KG') || _options.contains('1kg'))) {
        _selectedOption = _options.contains('1 KG') ? '1 KG' : (_options.contains('1KG') ? '1KG' : '1kg');
      } else {
        _selectedOption = _options.first;
      }
    } else {
      if (widget.item.isQuantityType) {
        _selectedOption = '1 Qty';
      } else if (widget.item.isGramType) {
        _selectedOption = '1 KG';
      } else {
        final unit = widget.item.displayUnit;
        _selectedOption = unit.isNotEmpty ? '1 $unit' : '1';
      }
    }
  }

  List<String> _generateOptions() {
    final maxStock = widget.item.effectiveStock.clamp(1, 50);
    final List<String> list = [];

    if (widget.item.isQuantityType) {
      for (int i = 1; i <= maxStock; i++) {
        list.add('$i Qty');
      }
    } else if (widget.item.isGramType) {
      if (maxStock >= 0.25) list.add('250 G');
      if (maxStock >= 0.5) list.add('500 G');
      for (double kg = 1.0; kg <= maxStock + 0.0001; kg += 0.5) {
        if (kg % 1 == 0) {
          list.add('${kg.toInt()} KG');
        } else {
          list.add('${kg.toStringAsFixed(1)} KG');
        }
      }
    } else {
      final unit = widget.item.displayUnit;
      for (int i = 1; i <= maxStock; i++) {
        list.add(unit.isNotEmpty ? '$i $unit' : '$i');
      }
    }
    return list;
  }

  double _getMultiplier(String option) {
    return parseQuantityFromWeight(option, 1).toDouble();
  }

  void _handleOptionChange(String option) {
    setState(() {
      _selectedOption = option;
    });
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    if (cartProvider.isItemInCart(widget.item.id)) {
      cartProvider.updateItemWeight(widget.item.id, option).catchError((e) {
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
      });
    }
  }

  Widget _buildModernSelectorSection() {
    if (widget.item.isOutOfStock) {
      return const SizedBox.shrink();
    }

    final isQty = widget.item.isQuantityType;
    final double multiplier = _getMultiplier(_selectedOption);
    final double finalTotalPrice = widget.item.unitFinalPrice * multiplier;
    final double originalTotalPrice =
        widget.item.unitOriginalPrice * multiplier;
    final double savings = originalTotalPrice - finalTotalPrice;
    final bool hasOffer = widget.item.hasOffer && savings > 0.01;
    final double offerPct = widget.item.effectiveOfferPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Icon
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.lightGreenBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isQty ? Icons.numbers_rounded : Icons.scale_rounded,
                size: 18,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isQty ? 'Select Quantity' : 'Select Weight',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Quick Selection Chips Row
        if (_options.isNotEmpty) ...[
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _options.length > 5 ? 5 : _options.length,
              itemBuilder: (context, index) {
                final option = _options[index];
                final isSelected = option == _selectedOption;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleOptionChange(option),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.darkGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.darkGreen
                                : AppTheme.darkGreen.withAlpha(50),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.darkGreen.withAlpha(60),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.textDark,
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
          const SizedBox(height: 12),
        ],

        // Modern Card Dropdown Selector
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.darkGreen.withAlpha(60),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppTheme.lightGreenBadge,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isQty ? Icons.shopping_basket_rounded : Icons.balance_rounded,
                  size: 20,
                  color: AppTheme.darkGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isQty ? 'CHOSEN QUANTITY' : 'CHOSEN WEIGHT',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _options.contains(_selectedOption)
                            ? _selectedOption
                            : (_options.isNotEmpty ? _options.first : null),
                        isExpanded: true,
                        isDense: true,
                        icon: const Icon(
                          Icons.unfold_more_rounded,
                          color: AppTheme.darkGreen,
                          size: 22,
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                        items: _options.map((opt) {
                          final isCurrent = opt == _selectedOption;
                          return DropdownMenuItem<String>(
                            value: opt,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  opt,
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? AppTheme.darkGreen
                                        : AppTheme.textDark,
                                  ),
                                ),
                                if (isCurrent)
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 18,
                                    color: AppTheme.darkGreen,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            _handleOptionChange(newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Premium Dynamic Price Card with Offer Details
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E4D2B), Color(0xFF2E6B3E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkGreen.withAlpha(60),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL PRICE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: Colors.white.withAlpha(200),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      children: [
                        Text(
                          '₹${finalTotalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (hasOffer)
                          Text(
                            '₹${originalTotalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withAlpha(160),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.white.withAlpha(160),
                            ),
                          ),
                      ],
                    ),
                    if (hasOffer) ...[
                      const SizedBox(height: 2),
                      Text(
                        'You save ₹${savings.toStringAsFixed(2)} (${offerPct % 1 == 0 ? offerPct.round() : offerPct.toStringAsFixed(1)}% OFF)',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFB5ED66),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasOffer) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${offerPct % 1 == 0 ? offerPct.round() : offerPct.toStringAsFixed(1)}% OFF',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB5ED66),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _selectedOption,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.item.images.isNotEmpty
        ? widget.item.images
        : [widget.item.image];
    final activeIndex = _selectedImageIndex < displayImages.length
        ? _selectedImageIndex
        : 0;
    final currentImageUrl = displayImages[activeIndex];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sub-header with Back Button
              Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppTheme.darkGreen,
                    ),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Main Large Item Image Card with Offer Badge Overlay
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomNetworkImage(
                        key: ValueKey(currentImageUrl),
                        imageUrl: currentImageUrl,
                        itemName: widget.item.subcategoryName,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (widget.item.hasOffer)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF5252), Color(0xFFFF1744)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            '${widget.item.effectiveOfferPercentage % 1 == 0 ? widget.item.effectiveOfferPercentage.round() : widget.item.effectiveOfferPercentage.toStringAsFixed(1)}% OFF',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (widget.item.isOutOfStock)
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD32F2F),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withAlpha(100),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Out of Stock',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Dynamic Thumbnail Selector Tiles below main image
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayImages.length,
                  itemBuilder: (context, index) {
                    final isSelected = activeIndex == index;
                    return Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedImageIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.darkGreen
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(13),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: IgnorePointer(
                              child: CustomNetworkImage(
                                key: ValueKey(
                                  'thumb_${index}_${displayImages[index]}',
                                ),
                                imageUrl: displayImages[index],
                                itemName: widget.item.subcategoryName,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Item Title
              Text(
                widget.item.subcategoryName,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGreen,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              // Unit Base Price & Offer Badge Summary Row
              Row(
                children: [
                  Text(
                    '₹${widget.item.unitFinalPrice.toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                  Text(
                    widget.item.priceUnitSuffix,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (widget.item.hasOffer) ...[
                    const SizedBox(width: 10),
                    Text(
                      '₹${widget.item.unitOriginalPrice.toStringAsFixed(2)}',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.item.effectiveOfferPercentage % 1 == 0 ? widget.item.effectiveOfferPercentage.round() : widget.item.effectiveOfferPercentage.toStringAsFixed(1)}% OFF',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // Modern Weight / Quantity Selector & Price Section
              _buildModernSelectorSection(),

              if (widget.item.description != null &&
                  widget.item.description!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  widget.item.description!,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Cart Actions Section (Hidden if out of stock, else Add to Cart / Cart actions)
              if (!widget.item.isOutOfStock)
                Consumer<CartProvider>(
                  builder: (context, cartProvider, child) {
                    final bool isInCart = cartProvider.isItemInCart(
                      widget.item.id,
                    );

                    if (isInCart) {
                      return Row(
                        children: [
                          // "In Cart" Button
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'The item is already in the cart.',
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: AppTheme.darkGreen,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.darkGreen,
                                  size: 22,
                                ),
                                label: Text(
                                  'In Cart',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGreen,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFB5ED66),
                                  foregroundColor: AppTheme.darkGreen,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Remove Cart Button
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await cartProvider.removeFromCart(
                                      widget.item.id,
                                    );
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          '${widget.item.subcategoryName} removed from cart!',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        duration: const Duration(seconds: 2),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!context.mounted) return;
                                    final errorMsg = e.toString().replaceAll(
                                      'Exception: ',
                                      '',
                                    );
                                    ScaffoldMessenger.of(context)
                                        .hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          errorMsg,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white,
                                          ),
                                        ),
                                        backgroundColor: Colors.redAccent,
                                        duration: const Duration(seconds: 4),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                ),
                                label: Text(
                                  'Remove Cart',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final authProvider = Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          );
                          if (!authProvider.isAuthenticated) {
                            AuthDialogHelper.showLoginRequiredAlert(context);
                            return;
                          }

                          if (cartProvider.isItemProcessing(widget.item.id)) {
                            return;
                          }

                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${widget.item.subcategoryName} added to cart!',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              backgroundColor: AppTheme.darkGreen,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );

                          cartProvider
                              .addToCart(
                                widget.item,
                                weight: _selectedOption,
                                quantity: widget.item.isQuantityType
                                    ? _getMultiplier(_selectedOption)
                                    : parseQuantityFromWeight(
                                        _selectedOption,
                                        1,
                                      ),
                              )
                              .catchError((e) {
                                if (!context.mounted) return;
                                final errorMsg = e.toString().replaceAll(
                                  'Exception: ',
                                  '',
                                );
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      errorMsg,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: Colors.redAccent,
                                    duration: const Duration(seconds: 4),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                );
                              });
                        },
                        icon: const Icon(
                          Icons.shopping_basket_rounded,
                          size: 22,
                        ),
                        label: Text(
                          'Add to Cart',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.darkGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // Bottom Menu in View Item Section
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          MainNavigationScreen.navigateToTab(context, index);
        },
      ),
    );
  }
}
