import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../config/env_config.dart';
import '../models/category.dart';
import '../models/sub_category_item.dart';
import '../models/cart_item.dart';
import '../models/address_model.dart';
import '../models/checkout_details.dart';
import '../utils/cookie_helper.dart';

class ApiService {
  static String get baseUrl => EnvConfig.baseUrl;
  static String get userBaseUrl => EnvConfig.userBaseUrl;

  /// Create a new user (Signup)
  Future<Map<String, dynamic>> createUser({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$userBaseUrl/create');
    final payload = {
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'email': email,
      'password': password,
    };

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        } else {
          throw Exception('Invalid response format from server.');
        }
      } else {
        String msg = 'Signup failed (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Signup failed')) {
        rethrow;
      }
      debugPrint('Signup API Error: $e');
      throw Exception(
        'Unable to connect to signup server (${EnvConfig.serverHost}). Please verify network and backend connection.',
      );
    }
  }

  /// Login user with credentials
  Future<Map<String, dynamic>> loginUser({
    required String emailOrPhone,
    required String password,
  }) async {
    final uri = Uri.parse('$userBaseUrl/login');
    final payload = {'email': emailOrPhone, 'password': password};

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        } else {
          throw Exception('Invalid response format from server.');
        }
      } else {
        String msg = 'Invalid email/phone number or password.';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception &&
          (e.toString().contains('Invalid email') ||
              e.toString().contains('Login failed') ||
              !e.toString().contains('Unable to connect'))) {
        rethrow;
      }
      debugPrint('Login API Error: $e');
      throw Exception(
        'Unable to connect to server (${EnvConfig.serverHost}). Please verify network and backend connection.',
      );
    }
  }

  /// Fetch Categories from Backend API
  Future<List<CategoryModel>> getCategories() async {
    final uri = Uri.parse('$baseUrl/categories');
    try {
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: EnvConfig.shortTimeoutSeconds));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          list = decoded;
        }
        return list.map((item) => CategoryModel.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to fetch categories (Server error ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('Categories API fetch error: $e');
      rethrow;
    }
  }

  /// Fetch Sub-Categories from Backend API
  Future<List<SubCategoryItem>> getSubCategories({
    dynamic categoryId,
    String? search,
    int? limit,
  }) async {
    String url = '$baseUrl/sub-categories';
    List<String> queryParams = [];

    if (categoryId != null &&
        categoryId.toString() != 'all' &&
        categoryId != 0) {
      queryParams.add('categoryId=$categoryId');
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams.add('search=${Uri.encodeComponent(search.trim())}');
    }

    final int effectiveLimit = limit ?? 1000;
    queryParams.add('limit=$effectiveLimit');
    queryParams.add('pageSize=$effectiveLimit');
    queryParams.add('per_page=$effectiveLimit');
    queryParams.add('all=true');

    if (queryParams.isNotEmpty) {
      url += '?${queryParams.join('&')}';
    }

    final uri = Uri.parse(url);
    try {
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: EnvConfig.shortTimeoutSeconds));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> list = [];
        if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
          list = decoded['data'] as List<dynamic>;
        } else if (decoded is List) {
          list = decoded;
        }
        return list.map((item) => SubCategoryItem.fromJson(item)).toList();
      } else {
        throw Exception(
          'Failed to fetch sub-categories (Server error ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('SubCategories API fetch error: $e');
      rethrow;
    }
  }

  /// Fetch CMS Content by ID (1: Terms of Service, 2: Privacy Policy)
  Future<Map<String, dynamic>> getCmsContent(int id) async {
    final uri = Uri.parse('$baseUrl/cms/$id');
    try {
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          Map<String, dynamic> cmsData = {};
          if (decoded.containsKey('data') &&
              decoded['data'] is Map<String, dynamic>) {
            cmsData = decoded['data'] as Map<String, dynamic>;
          } else if (decoded.containsKey('data') && decoded['data'] is String) {
            cmsData = {'content': decoded['data']};
          } else {
            cmsData = decoded;
          }

          String content =
              (cmsData['content'] ??
                      cmsData['html'] ??
                      cmsData['body'] ??
                      cmsData['text'] ??
                      cmsData['description'] ??
                      '')
                  .toString();

          if (content.isEmpty) {
            content = response.body;
          }

          return {
            'id': id,
            'title':
                cmsData['title'] ??
                cmsData['name'] ??
                (id == 1 ? 'Terms of Service' : 'Privacy Policy'),
            'content': content,
            'updatedAt':
                cmsData['updated_at'] ??
                cmsData['updatedAt'] ??
                cmsData['last_updated'],
          };
        } else if (decoded is String) {
          return {
            'id': id,
            'title': id == 1 ? 'Terms of Service' : 'Privacy Policy',
            'content': decoded,
          };
        }
        throw Exception('Invalid CMS response format.');
      } else {
        throw Exception(
          'Server error ${response.statusCode} while loading CMS content.',
        );
      }
    } catch (e) {
      debugPrint('CMS API fetch error (ID $id): $e');
      rethrow;
    }
  }

  /// Fetch App Setting from Backend API: GET http://localhost/api/shop/app-setting
  Future<Map<String, dynamic>> getAppSetting() async {
    final uri = Uri.parse(EnvConfig.appSettingUrl);
    try {
      final response = await http
          .get(uri)
          .timeout(Duration(seconds: EnvConfig.shortTimeoutSeconds));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        throw Exception('Invalid app-setting response format.');
      } else {
        throw Exception(
          'Failed to fetch app settings (Server error ${response.statusCode})',
        );
      }
    } catch (e) {
      if (!uri.toString().startsWith('http://localhost/api/shop')) {
        try {
          final fallbackUri = Uri.parse(
            'http://localhost/api/shop/app-setting',
          );
          final response = await http
              .get(fallbackUri)
              .timeout(Duration(seconds: EnvConfig.shortTimeoutSeconds));
          if (response.statusCode == 200) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              return decoded;
            }
          }
        } catch (_) {}
      }
      debugPrint('App setting API fetch error: $e');
      rethrow;
    }
  }

  /// Retrieve deliveryFee from GET http://localhost/api/shop/app-setting (data.deliveryFee)
  Future<double> getDeliveryFee() async {
    try {
      final setting = await getAppSetting();
      if (setting.containsKey('data') &&
          setting['data'] is Map<String, dynamic>) {
        final data = setting['data'] as Map<String, dynamic>;
        if (data.containsKey('deliveryFee')) {
          final fee = data['deliveryFee'];
          if (fee is num) return fee.toDouble();
          if (fee is String) return double.tryParse(fee) ?? 0.0;
        }
      } else if (setting.containsKey('deliveryFee')) {
        final fee = setting['deliveryFee'];
        if (fee is num) return fee.toDouble();
        if (fee is String) return double.tryParse(fee) ?? 0.0;
      }
    } catch (e) {
      debugPrint('Error getting delivery fee: $e');
    }
    return 0.0;
  }

  /// Add item to cart API endpoint: POST http://localhost:3000/api/cart/add
  Future<Map<String, dynamic>> addToCart({
    required SubCategoryItem item,
    String weight = '1kg',
    num quantity = 1,
  }) async {
    final uri = Uri.parse(EnvConfig.cartAddUrl);

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    Map<String, dynamic>? userData;
    if (userCookie != null && userCookie.isNotEmpty) {
      try {
        userData = jsonDecode(userCookie);
      } catch (_) {}
    }

    final headers = <String, String>{'Content-Type': 'application/json'};

    // Attach Cookies and Authorization header if available
    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    final payload = {
      'id': item.id,
      'itemId': item.id,
      'subcategoryId': item.id,
      'subcategoryName': item.subcategoryName,
      'name': item.subcategoryName,
      'amount': item.amount,
      'price': item.amount,
      'selectedWeight': weight,
      'weight': weight,
      'quantity': quantity,
      'categoryId': item.categoryId,
      'image': item.image,
      if (token != null && token.isNotEmpty) 'token': token,
      if (userData != null) ...{
        'userId': userData['id'] ?? userData['userId'] ?? userData['_id'],
        'user': userData,
      },
    };

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Item added to cart'};
      } else {
        String msg = 'Failed to save item in cart (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Cart Add API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Cart Add API Error (POST ${EnvConfig.cartAddUrl}): $e');
      throw Exception(
        'Unable to connect to cart service (${EnvConfig.serverHost}).',
      );
    }
  }

  /// Fetch all cart items from API endpoint: GET http://localhost:3000/api/cart/get-all
  Future<List<CartItem>> getCartItems() async {
    final uri = Uri.parse(EnvConfig.cartGetAllUrl);

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: EnvConfig.shortTimeoutSeconds));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            rawList = decoded['data'] as List<dynamic>;
          } else if (decoded.containsKey('cart') && decoded['cart'] is List) {
            rawList = decoded['cart'] as List<dynamic>;
          } else if (decoded.containsKey('items') && decoded['items'] is List) {
            rawList = decoded['items'] as List<dynamic>;
          }
        } else if (decoded is List) {
          rawList = decoded;
        }

        final List<CartItem> result = [];
        for (var rawJson in rawList) {
          if (rawJson is Map<String, dynamic>) {
            final Map<String, dynamic> itemMap =
                (rawJson['item'] is Map<String, dynamic>)
                ? (rawJson['item'] as Map<String, dynamic>)
                : (rawJson['subcategory'] is Map<String, dynamic>)
                ? (rawJson['subcategory'] as Map<String, dynamic>)
                : rawJson;

            final subCategoryItem = SubCategoryItem.fromJson(itemMap);
            num qty =
                num.tryParse(
                  (rawJson['quantity'] ?? rawJson['qty'] ?? 1).toString(),
                ) ??
                1;
            String weight =
                (rawJson['selectedWeight'] ??
                        rawJson['selected_weight'] ??
                        rawJson['weight'] ??
                        '')
                    .toString();

            if (weight.isEmpty ||
                (!weight.contains('g') &&
                    !weight.contains('kg') &&
                    !weight.contains('Qty'))) {
              weight = formatQuantityToDisplayUnit(
                qty,
                subCategoryItem.isQuantityType,
              );
            }

            final cartEntryId =
                rawJson['id'] ?? rawJson['cartId'] ?? rawJson['_id'];
            result.add(
              CartItem(
                id: cartEntryId,
                item: subCategoryItem,
                selectedWeight: weight,
                quantity: qty,
              ),
            );
          }
        }
        return result;
      } else {
        String msg = 'Failed to fetch cart items (${response.statusCode}).';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            } else if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            }
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Cart Get All API error (GET ${EnvConfig.cartGetAllUrl}): $e');
      throw Exception('Unable to fetch cart items.');
    }
  }

  /// Remove item from cart API endpoint: `DELETE http://localhost:3000/api/cart?subcategoryId={subcategoryId}`
  Future<Map<String, dynamic>> removeFromCart(dynamic subcategoryId) async {
    final uri = Uri.parse(EnvConfig.cartDeleteUrl(subcategoryId));

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Item removed from cart'};
      } else {
        String msg =
            'Failed to remove item from cart (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Cart Delete API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Cart Delete API Error (DELETE ${EnvConfig.cartDeleteUrl(subcategoryId)}): $e',
      );
      throw Exception('Unable to remove item from cart.');
    }
  }

  /// Update item in cart API endpoint: `PUT http://localhost:3000/api/cart`
  Future<Map<String, dynamic>> updateCartItem({
    dynamic cartId,
    required SubCategoryItem item,
    String weight = '1kg',
    num quantity = 1,
  }) async {
    final uri = Uri.parse(EnvConfig.cartUpdateUrl);

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    final payload = {
      'id': cartId ?? item.id,
      'subcategory_id': item.id,
      'quantity': quantity,
    };

    try {
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Cart item updated'};
      } else {
        String msg = 'Failed to update item in cart (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Cart Update API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint('Cart Update API Error (PUT ${EnvConfig.cartUpdateUrl}): $e');
      throw Exception('Unable to update cart item.');
    }
  }

  /// Fetch checkout details (delivery address and payment method)
  /// API endpoint: `GET http://localhost:3000/api/cart/get-check-out-details`
  Future<CheckoutDetails?> getCheckoutDetails() async {
    final uri = Uri.parse(EnvConfig.cartCheckoutDetailsUrl);

    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          return CheckoutDetails.fromJson(body);
        }
        return null;
      } else {
        String msg =
            'Failed to fetch checkout details (${response.statusCode}).';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            } else if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            }
          }
        } catch (_) {}
        debugPrint('Checkout Details API info: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Checkout Details API Error (GET ${EnvConfig.cartCheckoutDetailsUrl}): $e',
      );
      throw Exception('Unable to fetch checkout details.');
    }
  }

  /// Fetch all user addresses from API endpoint: GET http://localhost:3000/api/user/address/get-all
  Future<List<AddressModel>> getUserAddresses() async {
    final uri = Uri.parse(EnvConfig.addressGetAllUrl);

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];

        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is List) {
            rawList = decoded['data'] as List<dynamic>;
          } else if (decoded.containsKey('addresses') &&
              decoded['addresses'] is List) {
            rawList = decoded['addresses'] as List<dynamic>;
          }
        } else if (decoded is List) {
          rawList = decoded;
        }

        return rawList
            .whereType<Map<String, dynamic>>()
            .map((item) => AddressModel.fromJson(item))
            .toList();
      } else {
        String msg = 'Failed to fetch addresses (${response.statusCode}).';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            } else if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            }
          }
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Address Get All API error (GET ${EnvConfig.addressGetAllUrl}): $e',
      );
      throw Exception('Unable to fetch delivery addresses.');
    }
  }

  /// Create a new address via API endpoint: POST http://localhost:3000/api/user/address/create
  Future<Map<String, dynamic>> createAddress({
    required String buildingName,
    required String streetName,
    required String city,
    required String state,
    required String pincode,
    required String addressType,
    required bool isDefault,
  }) async {
    final uri = Uri.parse(EnvConfig.addressCreateUrl);

    // Normalize addressType for API: Home -> home, Work -> work, Other -> other
    String normalizedAddressType;
    final lower = addressType.trim().toLowerCase();
    if (lower == 'home') {
      normalizedAddressType = 'home';
    } else if (lower == 'work' || lower == 'office') {
      normalizedAddressType = 'work';
    } else {
      normalizedAddressType = 'other';
    }

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    final payload = {
      'buildingName': buildingName,
      'streetName': streetName,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': normalizedAddressType,
      'isDefault': isDefault,
    };

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Address created successfully'};
      } else {
        String msg = 'Failed to create address (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Create Address API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Create Address API Error (POST ${EnvConfig.addressCreateUrl}): $e',
      );
      throw Exception('Unable to create address.');
    }
  }

  /// Set address as default via API endpoint: PUT http://localhost:3000/api/user/address
  Future<Map<String, dynamic>> setDefaultAddress(dynamic addressId) async {
    final uri = Uri.parse(EnvConfig.addressSetDefaultUrl);

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    final payload = {'id': addressId, 'isDefault': true};

    try {
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Address set as default'};
      } else {
        String msg = 'Failed to set default address (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Set Default Address API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Set Default Address API Error (PUT ${EnvConfig.addressSetDefaultUrl}): $e',
      );
      throw Exception('Unable to set default address.');
    }
  }

  /// Delete user address via API endpoint: DELETE http://localhost:3000/api/user/address
  Future<Map<String, dynamic>> deleteAddress(dynamic addressId) async {
    final uri = Uri.parse(EnvConfig.addressDeleteUrl);

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    final payload = {'id': addressId};

    try {
      final response = await http
          .delete(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Address deleted successfully'};
      } else {
        String msg = 'Failed to delete address (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Delete Address API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Delete Address API Error (DELETE ${EnvConfig.addressDeleteUrl}): $e',
      );
      throw Exception('Unable to delete address.');
    }
  }

  /// Update user address via API endpoint: PUT http://localhost:3000/api/user/address
  Future<Map<String, dynamic>> updateAddress({
    required dynamic id,
    required String buildingName,
    required String streetName,
    required String city,
    required String state,
    required String pincode,
    required String addressType,
  }) async {
    final uri = Uri.parse(EnvConfig.addressUpdateUrl);

    // Normalize addressType for API: Home -> home, Work -> work, Other -> other
    String normalizedAddressType;
    final lower = addressType.trim().toLowerCase();
    if (lower == 'home') {
      normalizedAddressType = 'home';
    } else if (lower == 'work' || lower == 'office') {
      normalizedAddressType = 'work';
    } else {
      normalizedAddressType = 'other';
    }

    // Retrieve local cookies (user_token and user_data)
    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};

    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    final payload = {
      'id': id,
      'buildingName': buildingName,
      'streetName': streetName,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': normalizedAddressType,
    };

    try {
      final response = await http
          .put(uri, headers: headers, body: jsonEncode(payload))
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Address updated successfully'};
      } else {
        String msg = 'Failed to update address (${response.statusCode}).';
        if (body is Map<String, dynamic>) {
          if (body['message'] != null) {
            msg = body['message'].toString();
          } else if (body['error'] != null) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            msg = body['errors'].toString();
          }
        }
        debugPrint('Update Address API Error: $msg');
        throw Exception(msg);
      }
    } catch (e) {
      if (e is Exception) rethrow;
      debugPrint(
        'Update Address API Error (PUT ${EnvConfig.addressUpdateUrl}): $e',
      );
      throw Exception('Unable to update address.');
    }
  }

  /// Fetch user profile from API: GET http://localhost:3000/api/user/profile
  Future<Map<String, dynamic>> getUserProfile([String? explicitToken]) async {
    final primaryUri = Uri.parse(EnvConfig.userProfileUrl);
    final fallbackUri = Uri.parse('http://localhost/api/user/profile');

    // Retrieve local cookies (user_token and user_data)
    final token = (explicitToken != null && explicitToken.isNotEmpty)
        ? explicitToken
        : CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{'Content-Type': 'application/json'};
    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    try {
      var response = await http
          .get(primaryUri, headers: headers)
          .timeout(Duration(seconds: EnvConfig.apiTimeoutSeconds));

      if (response.statusCode != 200 &&
          primaryUri.toString() != fallbackUri.toString()) {
        try {
          response = await http
              .get(fallbackUri, headers: headers)
              .timeout(Duration(seconds: EnvConfig.shortTimeoutSeconds));
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          Map<String, dynamic> resultMap = {};
          if (decoded.containsKey('data') &&
              decoded['data'] is Map<String, dynamic>) {
            resultMap = Map<String, dynamic>.from(decoded['data'] as Map);
          } else if (decoded.containsKey('user') &&
              decoded['user'] is Map<String, dynamic>) {
            resultMap = Map<String, dynamic>.from(decoded['user'] as Map);
          } else if (decoded.containsKey('profile') &&
              decoded['profile'] is Map<String, dynamic>) {
            resultMap = Map<String, dynamic>.from(decoded['profile'] as Map);
          } else {
            resultMap = Map<String, dynamic>.from(decoded);
          }

          if (!resultMap.containsKey('profileImage') &&
              decoded.containsKey('profileImage')) {
            resultMap['profileImage'] = decoded['profileImage'];
          }
          if (!resultMap.containsKey('profile_image') &&
              decoded.containsKey('profile_image')) {
            resultMap['profile_image'] = decoded['profile_image'];
          }
          return resultMap;
        }
      }
    } catch (e) {
      debugPrint('User profile GET API error ($primaryUri): $e');
    }

    // Fallback to local user cookie if API endpoint fails or offline
    if (userCookie != null && userCookie.isNotEmpty) {
      try {
        final Map<String, dynamic> userData = jsonDecode(userCookie);
        return userData;
      } catch (_) {}
    }

    return {};
  }

  /// Update user profile API: POST http://localhost/api/user/profile (multipart/form-data)
  Future<Map<String, dynamic>> updateUserProfile({
    required String fullName,
    required String phoneNumber,
    required String email,
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
    String? profileImage,
    Uint8List? imageBytes,
    String? imageFileName,
  }) async {
    final primaryUri = Uri.parse(EnvConfig.userProfileUrl);
    final fallbackUri = Uri.parse('http://localhost/api/user/profile');

    final token = CookieHelper.getCookie(EnvConfig.authCookieName);
    final userCookie = CookieHelper.getCookie(EnvConfig.userCookieName);

    final headers = <String, String>{};
    final List<String> cookiesList = [];
    if (token != null && token.isNotEmpty) {
      cookiesList.add('${EnvConfig.authCookieName}=$token');
      headers['Authorization'] = 'Bearer $token';
    }
    if (userCookie != null && userCookie.isNotEmpty) {
      cookiesList.add('${EnvConfig.userCookieName}=$userCookie');
    }
    if (cookiesList.isNotEmpty) {
      headers['Cookie'] = cookiesList.join('; ');
    }

    try {
      final request = http.MultipartRequest('POST', primaryUri);
      request.headers.addAll(headers);

      // Add text form fields
      request.fields['fullName'] = fullName;
      request.fields['full_name'] = fullName;
      request.fields['phoneNumber'] = phoneNumber;
      request.fields['phone_number'] = phoneNumber;
      request.fields['email'] = email;
      if (currentPassword != null && currentPassword.isNotEmpty) {
        request.fields['currentPassword'] = currentPassword;
      }
      if (newPassword != null && newPassword.isNotEmpty) {
        request.fields['newPassword'] = newPassword;
      }
      if (confirmPassword != null && confirmPassword.isNotEmpty) {
        request.fields['confirmPassword'] = confirmPassword;
        request.fields['confirm_password'] = confirmPassword;
        request.fields['confirmNewPassword'] = confirmPassword;
      }

      // Add profile image file if bytes provided
      if (imageBytes != null && imageBytes.isNotEmpty) {
        final filename = imageFileName ?? 'profile.jpg';
        final mediaType = _getMediaTypeForFileName(filename);
        final multipartFile = http.MultipartFile.fromBytes(
          'profileImage',
          imageBytes,
          filename: filename,
          contentType: mediaType,
        );
        request.files.add(multipartFile);
      } else if (profileImage != null && profileImage.isNotEmpty) {
        request.fields['profileImage'] = profileImage;
        request.fields['image'] = profileImage;
      }

      http.StreamedResponse streamedResponse;
      try {
        streamedResponse = await request.send().timeout(
          Duration(seconds: EnvConfig.apiTimeoutSeconds),
        );
      } catch (netErr) {
        if (primaryUri.toString() != fallbackUri.toString()) {
          final fallbackRequest = http.MultipartRequest('POST', fallbackUri);
          fallbackRequest.headers.addAll(headers);
          fallbackRequest.fields.addAll(request.fields);
          for (var file in request.files) {
            fallbackRequest.files.add(file);
          }
          streamedResponse = await fallbackRequest.send().timeout(
            Duration(seconds: EnvConfig.shortTimeoutSeconds),
          );
        } else {
          rethrow;
        }
      }

      final response = await http.Response.fromStream(streamedResponse);
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (body is Map<String, dynamic>) {
          return body;
        }
        return {'success': true, 'message': 'Profile updated successfully!'};
      } else {
        String msg;
        if (response.statusCode >= 500) {
          msg =
              'Server error (${response.statusCode}). Please try again later.';
        } else {
          msg = 'Failed to update profile (${response.statusCode}).';
        }

        if (body is Map<String, dynamic>) {
          if (body['message'] != null &&
              body['message'].toString().isNotEmpty) {
            msg = body['message'].toString();
          } else if (body['error'] != null &&
              body['error'].toString().isNotEmpty) {
            msg = body['error'].toString();
          } else if (body['errors'] != null) {
            if (body['errors'] is List) {
              msg = (body['errors'] as List).join(', ');
            } else if (body['errors'] is Map) {
              msg = (body['errors'] as Map).values
                  .map((v) => v is List ? v.join(', ') : v.toString())
                  .join('; ');
            } else {
              msg = body['errors'].toString();
            }
          } else if (body['detail'] != null) {
            msg = body['detail'].toString();
          }
        }
        debugPrint(
          'Update Profile Multipart API Error (${response.statusCode}): $msg',
        );
        return {
          'success': false,
          'message': msg,
          'statusCode': response.statusCode,
          if (body is Map<String, dynamic>) 'data': body,
        };
      }
    } catch (e) {
      debugPrint('User Profile multipart update connection error: $e');
      return {
        'success': false,
        'message':
            'Unable to connect to server (${EnvConfig.serverHost}). Please check your network connection or server status.',
      };
    }
  }

  static MediaType _getMediaTypeForFileName(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      case 'gif':
        return MediaType('image', 'gif');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}
