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
  double _deliveryFee = 0.0;

  CheckoutDetails? _checkoutDetails;
  bool _isLoadingCheckout = false;
  String? _checkoutError;

  CartProvider() {
    fetchDeliveryFee();
    fetchCheckoutDetails();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
  CheckoutDetails? get checkoutDetails => _checkoutDetails;
  bool get isLoadingCheckout => _isLoadingCheckout;
  String? get checkoutError => _checkoutError;

  int get itemCount => _items.length;

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
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final fetchedItems = await _apiService.getCartItems();
      _items.clear();
      _items.addAll(fetchedItems);
      await fetchDeliveryFee();
      await fetchCheckoutDetails();
    } catch (e) {
      debugPrint('Error fetching cart items from API: $e');
      _items.clear();
      _checkoutDetails = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCheckoutDetails() async {
    _isLoadingCheckout = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final details = await _apiService.getCheckoutDetails();
      _checkoutDetails = details;
    } catch (e) {
      _checkoutError = e.toString().replaceAll('Exception: ', '');
      debugPrint('Error fetching checkout details in CartProvider: $e');
    } finally {
      _isLoadingCheckout = false;
      notifyListeners();
    }
  }

  bool isItemInCart(dynamic itemId) {
    return _items.any(
      (cartItem) => cartItem.item.id.toString() == itemId.toString(),
    );
  }

  Future<void> addToCart(
    SubCategoryItem item, {
    String weight = '1kg',
    num? quantity,
  }) async {
    final existingIndex = _items.indexWhere(
      (ci) => ci.item.id.toString() == item.id.toString(),
    );
    final isAlreadyInCart = existingIndex >= 0;

    num effectiveQty = quantity ?? parseQuantityFromWeight(weight, 1);

    dynamic existingCartId;
    if (isAlreadyInCart) {
      existingCartId = _items[existingIndex].id;
      _items[existingIndex].selectedWeight = weight;
      _items[existingIndex].quantity = effectiveQty;
    } else {
      _items.add(
        CartItem(item: item, selectedWeight: weight, quantity: effectiveQty),
      );
    }
    notifyListeners();

    try {
      if (isAlreadyInCart) {
        // If item is in cart, update using PUT http://localhost:3000/api/cart with cart entry ID
        await _apiService.updateCartItem(
          cartId: existingCartId,
          item: item,
          weight: weight,
          quantity: effectiveQty,
        );
      } else {
        // If item is new, add using POST http://localhost:3000/api/cart/add
        final res = await _apiService.addToCart(
          item: item,
          weight: weight,
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
      rethrow;
    }
  }

  Future<void> removeFromCart(dynamic itemId) async {
    _items.removeWhere((ci) => ci.item.id.toString() == itemId.toString());
    notifyListeners();

    try {
      await _apiService.removeFromCart(itemId);
    } catch (e) {
      debugPrint('Error removing item from cart API: $e');
      rethrow;
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
          rethrow;
        }
      }
    }
  }

  double get subtotal {
    return _items.fold(0.0, (sum, cartItem) => sum + cartItem.totalPrice);
  }

  // Dynamic delivery fee retrieved from GET http://localhost/api/shop/app-setting (data.deliveryFee)
  double get deliveryFee {
    if (_items.isEmpty) return 0.0;
    return subtotal < 400.0 ? _deliveryFee : 0.0;
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
}
