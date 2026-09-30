import '../config/env_config.dart';

class SubCategoryItem {
  final dynamic id;
  final String subcategoryName;
  final List<String> images;
  final double amount;
  final String status;
  final dynamic categoryId;
  final String? description;
  final String? categoryType;
  final int stock;
  final double offerPercentage;
  final double? originalAmount;

  SubCategoryItem({
    required this.id,
    required this.subcategoryName,
    required this.images,
    required this.amount,
    required this.status,
    this.categoryId,
    this.description,
    this.categoryType,
    this.stock = 50,
    this.offerPercentage = 0.0,
    this.originalAmount,
  });

  String? get subCategoryType => categoryType;

  bool get isGramType {
    if (categoryType == null) return false;
    final lower = categoryType!.trim().toLowerCase();
    return lower == 'gram' || lower == 'g';
  }

  bool get isQuantityType {
    if (categoryType == null) return false;
    final lower = categoryType!.trim().toLowerCase();
    return lower == 'quantity' || lower == 'qty';
  }

  String get displayUnit {
    if (categoryType == null || categoryType!.trim().isEmpty) {
      return '';
    }
    if (isGramType) {
      return 'KG';
    }
    if (isQuantityType) {
      return 'Qty';
    }
    return categoryType!.trim();
  }

  String get priceUnitSuffix {
    final unit = displayUnit;
    if (unit.isEmpty) return '';
    return ' / $unit';
  }

  bool get isOutOfStock => stock <= 0;

  int get effectiveStock => stock <= 0 ? 0 : stock;

  String get image => images.isNotEmpty ? images.first : '';

  bool get hasOffer => effectiveOfferPercentage > 0;

  double get effectiveOfferPercentage {
    if (offerPercentage > 0) {
      return offerPercentage;
    }
    if (originalAmount != null &&
        originalAmount! > amount &&
        originalAmount! > 0) {
      return ((originalAmount! - amount) / originalAmount! * 100);
    }
    return 0.0;
  }

  double get unitOriginalPrice {
    if (originalAmount != null &&
        originalAmount! > amount &&
        originalAmount! > 0) {
      return originalAmount!;
    }
    return amount;
  }

  double get unitFinalPrice {
    if (originalAmount != null &&
        originalAmount! > amount &&
        originalAmount! > 0) {
      return amount;
    }
    if (offerPercentage > 0 && offerPercentage < 100) {
      final discount = amount * (offerPercentage / 100.0);
      return amount - discount;
    }
    return amount;
  }

  factory SubCategoryItem.fromJson(Map<String, dynamic> json) {
    double parseAmount(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^\d.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int parseStock(dynamic val) {
      if (val == null) return 50;
      if (val is num) return val.toInt();
      if (val is String) {
        final cleaned = val.replaceAll(RegExp(r'[^\d]'), '');
        return int.tryParse(cleaned) ?? 50;
      }
      return 50;
    }

    List<String> parsedImages = [];
    final rawImages = json['images'];

    if (rawImages is List) {
      for (var item in rawImages) {
        final str = item?.toString().trim() ?? '';
        if (str.isNotEmpty) {
          parsedImages.add(EnvConfig.formatImageUrl(str));
        }
      }
    } else if (rawImages != null) {
      final str = rawImages.toString().trim();
      if (str.isNotEmpty) {
        parsedImages.add(EnvConfig.formatImageUrl(str));
      }
    }

    final rawType = (json['sub_category_type'] ??
            json['subCategoryType'] ??
            json['subcategory_type'] ??
            json['subcategoryType'] ??
            json['category_type'] ??
            json['categoryType'] ??
            json['category_mode'] ??
            json['unit_type'] ??
            json['unitType'] ??
            json['price_type'] ??
            json['type'] ??
            json['unit'] ??
            (json['category'] is Map
                ? json['category']['sub_category_type'] ??
                      json['category']['subCategoryType'] ??
                      json['category']['category_type'] ??
                      json['category']['categoryType'] ??
                      json['category']['type']
                : null))
        ?.toString()
        .trim();

    final double parsedOffer = parseAmount(
      json['offer_percentage'] ??
          json['offerPercentage'] ??
          json['offer'] ??
          json['discount_percentage'] ??
          json['discountPercentage'] ??
          json['discount'] ??
          json['percentage'] ??
          (json['category'] is Map
              ? json['category']['offer_percentage'] ??
                    json['category']['offer']
              : null),
    );

    final dynamic rawOrig = json['original_amount'] ??
        json['originalAmount'] ??
        json['original_price'] ??
        json['originalPrice'] ??
        json['mrp'];
    final double? parsedOriginal =
        rawOrig != null && rawOrig.toString().trim().isNotEmpty
            ? parseAmount(rawOrig)
            : null;

    return SubCategoryItem(
      id:
          json['id'] ??
          json['subcategoryId'] ??
          json['subcategory_id'] ??
          json['_id'] ??
          0,
      subcategoryName:
          (json['subcategoryName'] ??
                  json['subcategory_name'] ??
                  json['name'] ??
                  json['title'] ??
                  'Fresh Item')
              .toString()
              .trim(),
      images: parsedImages,
      amount: parseAmount(json['amount'] ?? json['price']),
      status: (json['status'] ?? 'active').toString().trim(),
      categoryId:
          json['categoryId'] ?? json['category_id'] ?? json['category'],
      description: json['description']?.toString(),
      categoryType: rawType,
      stock: parseStock(
        json['stock'] ??
            json['stock_value'] ??
            json['stockValue'] ??
            json['quantity'],
      ),
      offerPercentage: parsedOffer,
      originalAmount: parsedOriginal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subcategoryName': subcategoryName,
      'images': images,
      'image': image,
      'amount': amount,
      'status': status,
      'categoryId': categoryId,
      'description': description,
      'category_type': categoryType,
      'stock': stock,
      'offer_percentage': offerPercentage,
      'original_amount': originalAmount,
    };
  }

  bool get isActive => status.toLowerCase() == 'active';
}
