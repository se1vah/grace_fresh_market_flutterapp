import 'sub_category_item.dart';

num parseQuantityFromWeight(String weight, [num defaultQty = 1]) {
  final str = weight.toLowerCase().trim();
  if (str.isEmpty) return defaultQty;
  if (str == '250g' || str == '250 g') return 0.25;
  if (str == '500g' || str == '500 g') return 0.5;
  if (str == '750g' || str == '750 g') return 0.75;
  if ((str.contains('g') || str.contains('gm') || str.contains('gram')) &&
      !str.contains('kg')) {
    final cleanGramsStr = str.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final grams = double.tryParse(cleanGramsStr);
    if (grams != null && grams > 0) {
      return grams >= 50 ? grams / 1000 : grams;
    }
  }
  if (str.contains('kg')) {
    final cleanKgStr = str.replaceAll(RegExp(r'[^\d.]'), '').trim();
    final kg = double.tryParse(cleanKgStr);
    if (kg != null && kg > 0) {
      return kg;
    }
  }
  final match = RegExp(r'^(\d+(?:\.\d+)?)').firstMatch(str);
  if (match != null) {
    final parsed = num.tryParse(match.group(1)!);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
  }
  return defaultQty;
}

String formatQuantityToDisplayUnit(
  num qty,
  bool isQuantityType, [
  String? subCategoryType,
]) {
  if (isQuantityType) {
    return '${qty % 1 == 0 ? qty.toInt() : qty} Qty';
  }
  if (subCategoryType != null && subCategoryType.trim().isNotEmpty) {
    final lower = subCategoryType.trim().toLowerCase();
    if (lower != 'gram' &&
        lower != 'g' &&
        lower != 'quantity' &&
        lower != 'qty' &&
        lower != 'kg' &&
        lower != 'kilogram') {
      final qtyStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
      return '$qtyStr ${subCategoryType.trim()}';
    }
  }
  if ((qty - 0.25).abs() < 0.0001) return '250 G';
  if ((qty - 0.5).abs() < 0.0001) return '500 G';
  if ((qty - 0.75).abs() < 0.0001) return '750 G';
  if (qty < 1.0) {
    final grams = (qty * 1000).round();
    return '$grams G';
  }
  final kgStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
  return '$kgStr KG';
}

String formatQuantityToOption(
  num qty,
  bool isQuantityType,
  List<String> availableOptions, [
  String? subCategoryType,
]) {
  if (availableOptions.isEmpty) {
    return formatQuantityToDisplayUnit(qty, isQuantityType, subCategoryType);
  }

  for (final opt in availableOptions) {
    final optQty = parseQuantityFromWeight(opt, -1);
    if ((optQty - qty).abs() < 0.0001) {
      return opt;
    }
  }

  return formatQuantityToDisplayUnit(qty, isQuantityType, subCategoryType);
}

String getOptionForCartItem(CartItem cartItem, List<String> availableOptions) {
  final rawWeight = cartItem.selectedWeight.trim();

  // 1. Direct exact match
  if (availableOptions.contains(rawWeight)) {
    return rawWeight;
  }

  // 2. Case-insensitive & whitespace-insensitive match (e.g. '500g' matches '500 G')
  final normRaw = rawWeight.toLowerCase().replaceAll(' ', '');
  for (final opt in availableOptions) {
    if (opt.toLowerCase().replaceAll(' ', '') == normRaw) {
      return opt;
    }
  }

  // 3. Match by parsed weight from rawWeight string
  final weightQty = parseQuantityFromWeight(rawWeight, -1);
  if (weightQty > 0) {
    for (final opt in availableOptions) {
      final optQty = parseQuantityFromWeight(opt, -1);
      if ((optQty - weightQty).abs() < 0.0001) {
        return opt;
      }
    }
  }

  // 4. Match by cartItem.quantity
  if (cartItem.quantity > 0) {
    for (final opt in availableOptions) {
      final optQty = parseQuantityFromWeight(opt, -1);
      if ((optQty - cartItem.quantity).abs() < 0.0001) {
        return opt;
      }
    }
  }

  // 5. Fallback formatting
  return formatQuantityToOption(
    cartItem.quantity,
    cartItem.item.isQuantityType,
    availableOptions,
    cartItem.item.subCategoryType,
  );
}

class CartItem {
  dynamic id;
  final SubCategoryItem item;
  String selectedWeight;
  num quantity;

  CartItem({this.id, required this.item, String? selectedWeight, num? quantity})
    : quantity =
          (item.isGramType &&
              selectedWeight != null &&
              selectedWeight.trim().isNotEmpty &&
              parseQuantityFromWeight(selectedWeight, -1) > 0)
          ? parseQuantityFromWeight(selectedWeight, -1)
          : (quantity ?? parseQuantityFromWeight(selectedWeight ?? '1KG', 1)),
      selectedWeight =
          (selectedWeight != null &&
              selectedWeight.trim().isNotEmpty &&
              (selectedWeight.contains('g') ||
                  selectedWeight.contains('G') ||
                  selectedWeight.contains('kg') ||
                  selectedWeight.contains('KG') ||
                  selectedWeight.contains('Qty')))
          ? selectedWeight.trim()
          : formatQuantityToDisplayUnit(
              (item.isGramType &&
                      selectedWeight != null &&
                      selectedWeight.trim().isNotEmpty &&
                      parseQuantityFromWeight(selectedWeight, -1) > 0)
                  ? parseQuantityFromWeight(selectedWeight, -1)
                  : (quantity ??
                      parseQuantityFromWeight(selectedWeight ?? '1KG', 1)),
              item.isQuantityType,
              item.subCategoryType,
            );

  double get weightMultiplier => quantity.toDouble();

  bool get hasOffer => item.hasOffer;

  double get unitOriginalPrice => item.unitOriginalPrice;

  double get unitFinalPrice => item.unitFinalPrice;

  double get totalOriginalPrice => item.unitOriginalPrice * quantity;

  double get totalSavings =>
      (item.unitOriginalPrice - item.unitFinalPrice) * quantity;

  double get totalPrice {
    return item.unitFinalPrice * quantity;
  }
}
