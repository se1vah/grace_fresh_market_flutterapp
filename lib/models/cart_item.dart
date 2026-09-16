import 'sub_category_item.dart';

num parseQuantityFromWeight(String weight, [num defaultQty = 1]) {
  final str = weight.toLowerCase().trim();
  if (str == '250g' || str == '250 g') return 0.25;
  if (str == '500g' || str == '500 g') return 0.5;
  if (str == '750g' || str == '750 g') return 0.75;
  if (str.endsWith('g') && !str.endsWith('kg')) {
    final valStr = str.replaceAll('g', '').trim();
    final grams = double.tryParse(valStr);
    if (grams != null && grams > 0) {
      return grams / 1000;
    }
  }
  if (str.endsWith('kg')) {
    final valStr = str.replaceAll('kg', '').trim();
    final kg = double.tryParse(valStr);
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

String formatQuantityToDisplayUnit(num qty, bool isQuantityType) {
  if (isQuantityType) {
    return '${qty % 1 == 0 ? qty.toInt() : qty} Qty';
  }
  if ((qty - 0.25).abs() < 0.0001) return '250g';
  if ((qty - 0.5).abs() < 0.0001) return '500g';
  if ((qty - 0.75).abs() < 0.0001) return '750g';
  if (qty < 1.0) {
    final grams = (qty * 1000).round();
    return '${grams}g';
  }
  final kgStr = qty % 1 == 0 ? qty.toInt().toString() : qty.toString();
  return '${kgStr}kg';
}

String formatQuantityToOption(
  num qty,
  bool isQuantityType,
  List<String> availableOptions,
) {
  if (availableOptions.isEmpty) {
    return formatQuantityToDisplayUnit(qty, isQuantityType);
  }

  for (final opt in availableOptions) {
    final optQty = parseQuantityFromWeight(opt, -1);
    if ((optQty - qty).abs() < 0.0001) {
      return opt;
    }
  }

  return formatQuantityToDisplayUnit(qty, isQuantityType);
}

String getOptionForCartItem(CartItem cartItem, List<String> availableOptions) {
  final rawWeight = cartItem.selectedWeight.trim();
  if (availableOptions.contains(rawWeight)) {
    return rawWeight;
  }

  for (final opt in availableOptions) {
    if (opt.toLowerCase().trim() == rawWeight.toLowerCase().trim()) {
      return opt;
    }
  }

  return formatQuantityToOption(
    cartItem.quantity,
    cartItem.item.isQuantityType,
    availableOptions,
  );
}

class CartItem {
  dynamic id;
  final SubCategoryItem item;
  String selectedWeight;
  num quantity;

  CartItem({
    this.id,
    required this.item,
    String? selectedWeight,
    num? quantity,
  })  : quantity =
            quantity ?? parseQuantityFromWeight(selectedWeight ?? '1kg', 1),
        selectedWeight = (selectedWeight != null &&
                (selectedWeight.contains('g') ||
                    selectedWeight.contains('kg') ||
                    selectedWeight.contains('Qty')))
            ? selectedWeight
            : formatQuantityToDisplayUnit(
                quantity ?? parseQuantityFromWeight(selectedWeight ?? '1kg', 1),
                item.isQuantityType,
              );

  double get weightMultiplier => quantity.toDouble();

  double get totalPrice {
    return item.unitFinalPrice * quantity;
  }
}
