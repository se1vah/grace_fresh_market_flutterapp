import 'package:flutter/material.dart';
import 'order_details_card.dart';

/// Animated Skeleton Pulse Box Widget
class SkeletonBox extends StatefulWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  const SkeletonBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.45, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin,
          decoration: BoxDecoration(
            color: Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFFF1F5F9),
              _animation.value,
            ),
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.circle
                ? null
                : BorderRadius.circular(widget.borderRadius),
          ),
        );
      },
    );
  }
}

/// Category Pills Skeleton Row
class CategoryPillsSkeleton extends StatelessWidget {
  const CategoryPillsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final widths = [80.0, 100.0, 90.0, 110.0, 85.0, 95.0];
          return SkeletonBox(
            width: widths[index % widths.length],
            height: 36,
            borderRadius: 24,
          );
        },
      ),
    );
  }
}

/// Product Card Skeleton Widget (Matches ItemCard)
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          const Expanded(
            child: SkeletonBox(
              width: double.infinity,
              borderRadius: 12,
            ),
          ),
          const SizedBox(height: 10),
          // Title skeleton
          const SkeletonBox(
            width: 110,
            height: 14,
            borderRadius: 4,
          ),
          const SizedBox(height: 6),
          // Subtitle skeleton
          const SkeletonBox(
            width: 70,
            height: 12,
            borderRadius: 4,
          ),
          const SizedBox(height: 10),
          // Price and button row skeleton
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 65, height: 22, borderRadius: 6),
              SkeletonBox(width: 32, height: 32, shape: BoxShape.circle),
            ],
          ),
        ],
      ),
    );
  }
}

/// Product Grid Skeleton for Home / Shop
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.68,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ProductCardSkeleton(),
    );
  }
}

/// Sliver Product Grid Skeleton for CustomScrollView
class SliverProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const SliverProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.68,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const ProductCardSkeleton(),
          childCount: itemCount,
        ),
      ),
    );
  }
}

/// Cart Items & Summary Skeleton
class CartScreenSkeleton extends StatelessWidget {
  const CartScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          const SkeletonBox(width: 140, height: 26, borderRadius: 6),
          const SizedBox(height: 20),

          // Cart Items Skeleton Cards
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    SkeletonBox(width: 64, height: 64, borderRadius: 12),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 120, height: 16, borderRadius: 4),
                          SizedBox(height: 8),
                          SkeletonBox(width: 70, height: 14, borderRadius: 4),
                        ],
                      ),
                    ),
                    SkeletonBox(width: 60, height: 32, borderRadius: 20),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),
          // Order Summary Skeleton Container
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 130, height: 20, borderRadius: 4),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 80, height: 14, borderRadius: 4),
                    SkeletonBox(width: 60, height: 14, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 90, height: 14, borderRadius: 4),
                    SkeletonBox(width: 50, height: 14, borderRadius: 4),
                  ],
                ),
                SizedBox(height: 16),
                Divider(color: Color(0xFFEEEEEE), height: 1),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 60, height: 20, borderRadius: 4),
                    SkeletonBox(width: 80, height: 24, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// My Orders Screen Timeline Skeleton
class MyOrdersScreenSkeleton extends StatelessWidget {
  const MyOrdersScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => const OrderDetailsCardSkeleton(),
      ),
    );
  }
}

/// Delivery Address Cards List Skeleton
class DeliveryAddressSkeleton extends StatelessWidget {
  const DeliveryAddressSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SkeletonBox(width: 130, height: 16, borderRadius: 4),
                    SkeletonBox(width: 60, height: 20, borderRadius: 10),
                  ],
                ),
                SizedBox(height: 10),
                SkeletonBox(width: 200, height: 14, borderRadius: 4),
                SizedBox(height: 6),
                SkeletonBox(width: 160, height: 14, borderRadius: 4),
                SizedBox(height: 10),
                SkeletonBox(width: 110, height: 12, borderRadius: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Profile Header & Items Skeleton
class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Profile Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              SkeletonBox(width: 100, height: 100, shape: BoxShape.circle),
              SizedBox(height: 16),
              SkeletonBox(width: 140, height: 20, borderRadius: 4),
              SizedBox(height: 8),
              SkeletonBox(width: 180, height: 14, borderRadius: 4),
              SizedBox(height: 6),
              SkeletonBox(width: 120, height: 14, borderRadius: 4),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Menu Items List
        ...List.generate(
          4,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  SkeletonBox(width: 38, height: 38, borderRadius: 10),
                  SizedBox(width: 14),
                  Expanded(
                    child: SkeletonBox(width: 120, height: 16, borderRadius: 4),
                  ),
                  SkeletonBox(width: 18, height: 18, borderRadius: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Notifications Screen List Skeleton
class NotificationsScreenSkeleton extends StatelessWidget {
  const NotificationsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEEEEEE)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(6),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SkeletonBox(
                      width: 4,
                      height: double.infinity,
                      borderRadius: 0,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SkeletonBox(
                              width: 48,
                              height: 48,
                              shape: BoxShape.circle,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: const [
                                      SkeletonBox(
                                        width: 120,
                                        height: 16,
                                        borderRadius: 4,
                                      ),
                                      SkeletonBox(
                                        width: 60,
                                        height: 12,
                                        borderRadius: 4,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const SkeletonBox(
                                    width: double.infinity,
                                    height: 14,
                                    borderRadius: 4,
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
      ),
    );
  }
}

