import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/shop_provider.dart';
import '../../theme/app_theme.dart';
import '../item_details/item_details_screen.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_drawer.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/skeleton_loader.dart';
import 'widgets/category_pills.dart';
import 'widgets/item_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'home'),
      body: RefreshIndicator(
        onRefresh: () async {
          final shop = Provider.of<ShopProvider>(context, listen: false);
          await shop.fetchCategories();
          await shop.fetchSubCategories();
        },
        color: AppTheme.darkGreen,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Dynamic Category Pills Row
                  const CategoryPills(),

                  const SizedBox(height: 16),

                  // Search Bar Input with Dynamic Search Suggestions
                  Consumer<ShopProvider>(
                    builder: (context, shopProvider, child) {
                      final hasQuery = shopProvider.searchQuery
                          .trim()
                          .isNotEmpty;
                      final suggestions = shopProvider.activeItems;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(8),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  shopProvider.setSearchQuery(value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search Item',
                                  hintStyle: GoogleFonts.outfit(
                                    color: const Color(0xFF9CA3AF),
                                    fontSize: 15,
                                  ),
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(
                                      left: 16.0,
                                      right: 10.0,
                                    ),
                                    child: Icon(
                                      Icons.search,
                                      color: Color(0xFF6B7280),
                                      size: 22,
                                    ),
                                  ),
                                  suffixIcon: hasQuery
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            shopProvider.setSearchQuery(
                                              '',
                                              immediate: true,
                                            );
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),

                            // Search Suggestions Box (Filtered by Selected Category)
                            if (hasQuery) ...[
                              const SizedBox(height: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(20),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                constraints: const BoxConstraints(
                                  maxHeight: 250,
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: suggestions.isEmpty
                                      ? Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Text(
                                            'No items found in selected category',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                          itemCount: suggestions.length,
                                          separatorBuilder: (context, index) =>
                                              const Divider(
                                                height: 1,
                                                color: Color(0xFFF0F0F0),
                                              ),
                                          itemBuilder: (context, index) {
                                            final item = suggestions[index];
                                            return Material(
                                              color: Colors.transparent,
                                              child: ListTile(
                                                dense: true,
                                                leading: Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFF7F8F6,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: CustomNetworkImage(
                                                    imageUrl: item.image,
                                                    itemName:
                                                        item.subcategoryName,
                                                    fit: BoxFit.cover,
                                                    isGray: item.isOutOfStock,
                                                  ),
                                                ),
                                                title: Text(
                                                  item.subcategoryName,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textDark,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  '₹${item.amount.toStringAsFixed(2)} / kg',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppTheme.darkGreen,
                                                  ),
                                                ),
                                                trailing: const Icon(
                                                  Icons.chevron_right,
                                                  color: Colors.grey,
                                                  size: 20,
                                                ),
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
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Grid Items Container (Filtered by Selected Category)
            Consumer<ShopProvider>(
              builder: (context, shopProvider, child) {
                if (shopProvider.isLoadingItems) {
                  return const SliverProductGridSkeleton();
                }

                final items = shopProvider.activeItems;

                if (items.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 56,
                              color: AppTheme.darkGreen.withAlpha(76),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No active items found',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Try selecting a different category or search term.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return ItemCard(item: items[index]);
                    }, childCount: items.length),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
