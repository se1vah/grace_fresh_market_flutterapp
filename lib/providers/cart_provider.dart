import 'package:flutter/foundation.dart';

import '../config/env_config.dart';
import '../models/sub_category_item.dart';
import '../models/cart_item.dart';
import '../models/checkout_details.dart';
import '../services/api_service.dart';
import '../utils/cookie_helper.dart';

class CartProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Empty initial cart per requirement: "Remove all default cart values"
  final List<CartItem> _items = [];
  bool _isLoading = false;
  bool _hasNetworkError = false;
  double _deliveryFee = 0.0;

  CheckoutDetails? _checkoutDetails;
  bool _isLoadingCheckout = false;
  String? _checkoutError;

  CartProvider() {
    fetchDeliveryFee();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  bool get hasNetworkError => _hasNetworkError;
  CheckoutDetails? get checkoutDetails => _checkoutDetails;
  bool get isLoadingCheckout => _isLoadingCheckout;
  String? get checkoutError => _checkoutError;

  int get itemCount => _items.length;

  bool _isNetworkError(dynamic e) {
    final str = e.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('no address associated with hostname') ||
        str.contains('connection refused') ||
        str.contains('clientexception') ||
        str.contains('unable to connect') ||
        str.contains('network') ||
        str.contains('no internet') ||
        str.contains('connection failed') ||
        str.contains('connection reset') ||
        str.contains('errno = 7') ||
        str.contains('errno = 111');
  }

  Future<void> fetchDeliveryFee() async {
    try {
      final fee = await _apiService.getDeliveryFee();
      _deliveryFee = fee;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching delivery fee from API: $e');
    }
  }

  Future<void> fetchCartItems() async {
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    if (token == null || token.isEmpty) {
      _items.clear();
      _checkoutDetails = null;
      _checkoutError = null;
      _isLoading = false;
      _hasNetworkError = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final fetchedItems = await _apiService.getCartItems();
      _items.clear();
      _items.addAll(fetchedItems);
      _hasNetworkError = false;
      await fetchDeliveryFee();
    } catch (e) {
      debugPrint('Error fetching cart items from API: $e');
      _items.clear();
      _checkoutDetails = null;
      if (_isNetworkError(e)) {
        _hasNetworkError = true;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCheckoutDetails() async {
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    if (token == null || token.isEmpty) {
      _checkoutDetails = null;
      _checkoutError = null;
      _isLoadingCheckout = false;
      notifyListeners();
      return;
    }

    _isLoadingCheckout = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final addresses = await _apiService.getUserAddresses();
      final codMethod = PaymentMethodData(
        id: 'cod',
        paymentType: 'COD',
        description: "Pay when your fresh produce arrives at your door. We accept exact cash or card via our driver's terminal.",
      );

      if (addresses.isEmpty) {
        _checkoutDetails = CheckoutDetails(
          deliveryAddress: null,
          paymentMethods: [codMethod],
        );
      } else {
        final activeAddr = addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => addresses.first,
        );
        _checkoutDetails = CheckoutDetails(
          deliveryAddress: DeliveryAddressData(
            id: activeAddr.id,
            fullName: '',
            phoneNumber: activeAddr.phoneNumber,
            addressLine1: activeAddr.buildingName,
            addressLine2: activeAddr.streetName,
            city: activeAddr.city,
            state: activeAddr.state,
            postalCode: activeAddr.pincode,
          ),
          paymentMethods: [codMethod],
        );
      }
    } catch (e) {
      _checkoutError = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error fetching user addresses in CartProvider: $e');
    } finally {
      _isLoadingCheckout = false;
      notifyListeners();
    }
  }

  final Set<String> _processingItemIds = {};

  bool isItemProcessing(dynamic itemId) {
    if (itemId == null) return false;
    return _processingItemIds.contains(itemId.toString());
  }

  bool isItemInCart(dynamic itemId) {
    if (itemId == null) return false;
    return _items.any(
      (cartItem) => cartItem.item.id.toString() == itemId.toString(),
    );
  }

  CartItem? getCartItem(dynamic itemId) {
    if (itemId == null) return null;
    final idStr = itemId.toString();
    for (final cartItem in _items) {
      if (cartItem.item.id.toString() == idStr) {
        return cartItem;
      }
    }
    return null;
  }

  Future<void> addToCart(
    SubCategoryItem item, {
    String? weight,
    num? quantity,
  }) async {
    if (item.isOutOfStock) {
      throw Exception('${item.subcategoryName} is currently out of stock.');
    }

    final String resolvedWeight = (weight != null && weight.trim().isNotEmpty)
        ? weight.trim()
        : (item.isQuantityType
            ? '1 Qty'
            : (item.isGramType
                ? '1kg'
                : (item.displayUnit.isNotEmpty ? '1 ${item.displayUnit}' : '1kg')));

    final itemIdStr = item.id.toString();
    if (_processingItemIds.contains(itemIdStr)) return;
    _processingItemIds.add(itemIdStr);

    final existingIndex = _items.indexWhere(
      (ci) => ci.item.id.toString() == item.id.toString(),
    );
    final isAlreadyInCart = existingIndex >= 0;

    num effectiveQty = quantity ?? parseQuantityFromWeight(resolvedWeight, 1);

    dynamic existingCartId;
    CartItem? previousItem;

    if (isAlreadyInCart) {
      existingCartId = _items[existingIndex].id;
      previousItem = CartItem(
        id: _items[existingIndex].id,
        item: _items[existingIndex].item,
        selectedWeight: _items[existingIndex].selectedWeight,
        quantity: _items[existingIndex].quantity,
      );
      _items[existingIndex].selectedWeight = resolvedWeight;
      _items[existingIndex].quantity = effectiveQty;
    } else {
      _items.add(
        CartItem(
          item: item,
          selectedWeight: resolvedWeight,
          quantity: effectiveQty,
        ),
      );
    }
    notifyListeners();

    try {
      if (isAlreadyInCart) {
        // If item is in cart, update using PUT http://localhost:3000/api/cart with cart entry ID
        await _apiService.updateCartItem(
          cartId: existingCartId,
          item: item,
          weight: resolvedWeight,
          quantity: effectiveQty,
        );
      } else {
        // If item is new, add using POST http://localhost:3000/api/cart/add
        final res = await _apiService.addToCart(
          item: item,
          weight: resolvedWeight,
          quantity: effectiveQty,
        );
        final returnedId =
            res['id'] ??
            res['cartId'] ??
            res['_id'] ??
            (res['data'] is Map ? res['data']['id'] : null);
        if (returnedId != null) {
          final idx = _items.indexWhere(
            (ci) => ci.item.id.toString() == item.id.toString(),
          );
          if (idx >= 0) {
            _items[idx].id = returnedId;
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving/updating item in cart API: $e');
      // Revert local changes on error so item is not stored locally
      if (isAlreadyInCart) {
        final idx = _items.indexWhere(
          (ci) => ci.item.id.toString() == item.id.toString(),
        );
        if (idx >= 0 && previousItem != null) {
          _items[idx] = previousItem;
        }
      } else {
        _items.removeWhere((ci) => ci.item.id.toString() == item.id.toString());
      }
      notifyListeners();
      rethrow;
    } finally {
      _processingItemIds.remove(itemIdStr);
    }
  }

  Future<void> removeFromCart(dynamic itemId) async {
    final itemIdStr = itemId.toString();
    if (_processingItemIds.contains(itemIdStr)) return;
    _processingItemIds.add(itemIdStr);

    final existingIndex = _items.indexWhere(
      (ci) => ci.item.id.toString() == itemId.toString(),
    );
    if (existingIndex < 0) {
      _processingItemIds.remove(itemIdStr);
      return;
    }

    final removedItem = _items[existingIndex];
    _items.removeAt(existingIndex);
    notifyListeners();

    try {
      await _apiService.removeFromCart(itemId);
    } catch (e) {
      debugPrint('Error removing item from cart API: $e');
      if (!_items.any((ci) => ci.item.id.toString() == itemId.toString())) {
        if (existingIndex <= _items.length) {
          _items.insert(existingIndex, removedItem);
        } else {
          _items.add(removedItem);
        }
      }
      notifyListeners();
      rethrow;
    } finally {
      _processingItemIds.remove(itemIdStr);
    }
  }

  Future<void> removeItemAt(int index) async {
    if (index >= 0 && index < _items.length) {
      final itemToRemove = _items[index];
      _items.removeAt(index);
      notifyListeners();

      try {
        await _apiService.removeFromCart(itemToRemove.item.id);
      } catch (e) {
        debugPrint('Error removing item at index from cart API: $e');
        if (index <= _items.length) {
          _items.insert(index, itemToRemove);
        } else {
          _items.add(itemToRemove);
        }
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> updateItemWeight(dynamic itemId, String newWeight) async {
    final index = _items.indexWhere(
      (ci) => ci.item.id.toString() == itemId.toString(),
    );
    if (index >= 0) {
      final cartItem = _items[index];
      final oldWeight = cartItem.selectedWeight;
      final oldQty = cartItem.quantity;

      cartItem.selectedWeight = newWeight;
      num effectiveQty = parseQuantityFromWeight(newWeight, cartItem.quantity);
      cartItem.quantity = effectiveQty;
      notifyListeners();

      try {
        await _apiService.updateCartItem(
          cartId: cartItem.id,
          item: cartItem.item,
          weight: newWeight,
          quantity: effectiveQty,
        );
      } catch (e) {
        debugPrint('Error updating item weight in cart API: $e');
        cartItem.selectedWeight = oldWeight;
        cartItem.quantity = oldQty;
        notifyListeners();
        rethrow;
      }
    }
  }

  Future<void> updateItemQuantity(dynamic itemId, num newQuantity) async {
    final index = _items.indexWhere(
      (ci) => ci.item.id.toString() == itemId.toString(),
    );
    if (index >= 0) {
      if (newQuantity <= 0) {
        await removeFromCart(itemId);
      } else {
        final cartItem = _items[index];
        final oldQty = cartItem.quantity;

        cartItem.quantity = newQuantity;
        notifyListeners();

        try {
          await _apiService.updateCartItem(
            cartId: cartItem.id,
            item: cartItem.item,
            weight: cartItem.selectedWeight,
            quantity: newQuantity,
          );
        } catch (e) {
          debugPrint('Error updating item quantity in cart API: $e');
          cartItem.quantity = oldQty;
          notifyListeners();
          rethrow;
        }
      }
    }
  }

  double get originalSubtotal {
    return _items.fold(
      0.0,
      (sum, cartItem) => sum + cartItem.totalOriginalPrice,
    );
  }

  double get totalSavings {
    final savings = originalSubtotal - subtotal;
    return savings > 0 ? savings : 0.0;
  }

  double get subtotal {
    return _items.fold(0.0, (sum, cartItem) => sum + cartItem.totalPrice);
  }

  double get baseDeliveryFee => _deliveryFee > 0 ? _deliveryFee : 40.0;

  bool get isFreeDelivery => _items.isNotEmpty && subtotal >= 400.0;

  // Dynamic delivery fee retrieved from GET http://localhost/api/shop/app-setting (data.deliveryFee)
  double get deliveryFee {
    if (_items.isEmpty || isFreeDelivery) return 0.0;
    return baseDeliveryFee;
  }

  double get grandTotal {
    return subtotal + deliveryFee;
  }

  void clearCart() {
    _items.clear();
    _checkoutDetails = null;
    _checkoutError = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> placeOrder() async {
    _isLoading = true;
    notifyListeners();

    try {
      final fetchedItems = await _apiService.getCartItems();
      if (fetchedItems.isEmpty) {
        throw Exception('Your cart is empty.');
      }

      final cartIds = fetchedItems
          .map((item) => item.id)
          .where((id) => id != null)
          .toList();

      if (cartIds.isEmpty) {
        throw Exception('No valid cart item IDs found.');
      }

      final response = await _apiService.placeOrder(cartIds);
      clearCart();
      return response;
    } catch (e) {
      debugPrint('Error placing order in CartProvider: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
