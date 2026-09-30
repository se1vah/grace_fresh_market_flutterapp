import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../models/category.dart';
import '../../../providers/shop_provider.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/skeleton_loader.dart';

class CategoryPills extends StatelessWidget {
  const CategoryPills({super.key});

  Widget _buildFallbackIcon(String name, bool isSelected) {
    final lower = name.toLowerCase().trim();
    IconData iconData = Icons.category_rounded;

    if (lower == 'all') {
      iconData = Icons.grid_view_rounded;
    } else if (lower.contains('juice') || lower.contains('drink')) {
      iconData = Icons.local_drink_rounded;
    } else if (lower.contains('fruit')) {
      iconData = Icons.apple_rounded;
    } else if (lower.contains('veg')) {
      iconData = Icons.eco_rounded;
    } else if (lower.contains('dairy') || lower.contains('milk')) {
      iconData = Icons.water_drop_rounded;
    } else if (lower.contains('snack') || lower.contains('bakery')) {
      iconData = Icons.bakery_dining_rounded;
    }

    return Icon(
      iconData,
      size: 14,
      color: isSelected ? Colors.white : AppTheme.darkGreen,
    );
  }

  Widget _buildCategoryImage(CategoryModel cat, bool isSelected) {
    final image = cat.categoryImage;

    Widget imageContent;
    if (image != null && image.trim().isNotEmpty) {
      if (image.startsWith('assets/')) {
        imageContent = Image.asset(
          image,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(cat.categoryName, isSelected),
        );
      } else {
        imageContent = Image.network(
          image,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackIcon(cat.categoryName, isSelected),
        );
      }
    } else {
      imageContent = _buildFallbackIcon(cat.categoryName, isSelected);
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Colors.white.withAlpha(50)
            : AppTheme.darkGreen.withAlpha(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Center(child: imageContent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        if (shopProvider.isLoadingCategories) {
          return const CategoryPillsSkeleton();
        }

        final categories = shopProvider.categories;

        return SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final dynamic categoryId = cat.id;
              final bool isSelected =
                  shopProvider.selectedCategoryId == categoryId;

              return InkWell(
                onTap: () {
                  shopProvider.selectCategory(categoryId);
                },
                borderRadius: BorderRadius.circular(24),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.darkGreen
                        : const Color(0xFFF2F4F1),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.darkGreen.withAlpha(51),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCategoryImage(cat, isSelected),
                      const SizedBox(width: 8),
                      Text(
                        cat.categoryName,
                        style: GoogleFonts.outfit(
                          color: isSelected ? Colors.white : AppTheme.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
