import '../config/env_config.dart';

class OrderStatusModel {
  final dynamic id;
  final dynamic orderId;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  OrderStatusModel({
    this.id,
    this.orderId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderStatusModel.fromJson(Map<String, dynamic> json) {
    return OrderStatusModel(
      id: json['id'],
      orderId: json['orderId'] ?? json['order_id'],
      status: (json['status'] ?? '').toString(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class StatusHistoryItemModel {
  final dynamic id;
  final dynamic orderId;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  StatusHistoryItemModel({
    this.id,
    this.orderId,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory StatusHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return StatusHistoryItemModel(
      id: json['id'],
      orderId: json['orderId'] ?? json['order_id'],
      status: (json['status'] ?? '').toString(),
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }
}

class CartSummaryModel {
  final int totalItems;
  final int itemCount;
  final double totalAmount;
  final double deliveryFee;

  CartSummaryModel({
    required this.totalItems,
    required this.itemCount,
    required this.totalAmount,
    required this.deliveryFee,
  });

  factory CartSummaryModel.fromJson(Map<String, dynamic> json) {
    return CartSummaryModel(
      totalItems: int.tryParse(json['totalItems']?.toString() ?? '0') ?? 0,
      itemCount: int.tryParse(json['itemCount']?.toString() ?? '0') ?? 0,
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      deliveryFee:
          double.tryParse(json['deliveryFee']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class OrderItemModel {
  final dynamic id;
  final dynamic categoryId;
  final dynamic subcategoryId;
  final num quantity;
  final double itemTotal;
  final String? subcategoryName;
  final double? subcategoryAmount;
  final List<String> images;
  final String? subCategoryType;

  final double? originalAmount;
  final double? offerAmount;

  OrderItemModel({
    this.id,
    this.categoryId,
    this.subcategoryId,
    required this.quantity,
    required this.itemTotal,
    this.subcategoryName,
    this.subcategoryAmount,
    this.images = const [],
    this.subCategoryType,
    this.originalAmount,
    this.offerAmount,
  });

  double get totalOriginalAmount {
    if (originalAmount != null && originalAmount! > 0) {
      return originalAmount! * quantity;
    }
    final unitPrice = subcategoryAmount ?? 0.0;
    if (unitPrice > 0) {
      return unitPrice * quantity;
    }
    return itemTotal;
  }

  double get totalOfferAmount {
    if (offerAmount != null && offerAmount! > 0) {
      return offerAmount!;
    }
    final orig = totalOriginalAmount;
    if (orig > itemTotal) {
      return orig - itemTotal;
    }
    return 0.0;
  }

  bool get hasOffer => totalOfferAmount > 0;

  bool get isGramType {
    if (subCategoryType == null) return false;
    final lower = subCategoryType!.trim().toLowerCase();
    return lower == 'gram' || lower == 'g';
  }

  bool get isQuantityType {
    if (subCategoryType == null) return false;
    final lower = subCategoryType!.trim().toLowerCase();
    return lower == 'quantity' || lower == 'qty';
  }

  String get displayUnit {
    if (subCategoryType == null || subCategoryType!.trim().isEmpty) {
      return '';
    }
    if (isGramType) return 'KG';
    if (isQuantityType) return 'Qty';
    return subCategoryType!.trim();
  }

  String get formattedQuantityDisplay {
    final unit = displayUnit;
    if (isGramType) {
      if (quantity < 1.0) {
        final grams = (quantity * 1000).round();
        return '$grams G';
      }
      final kgStr = quantity % 1 == 0
          ? quantity.toInt().toString()
          : quantity.toString();
      return '$kgStr KG';
    }
    if (unit.isNotEmpty) {
      final qtyStr = quantity % 1 == 0
          ? quantity.toInt().toString()
          : quantity.toString();
      return '$qtyStr $unit';
    }
    final qtyStr = quantity % 1 == 0
        ? quantity.toInt().toString()
        : quantity.toString();
    return qtyStr;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String? name =
        json['subcategoryName'] ??
        json['name'] ??
        json['title'] ??
        json['productName'];
    double? amount = double.tryParse(
      (json['subcategoryAmount'] ?? json['amount'] ?? json['price'] ?? '0')
          .toString(),
    );

    List<String> parseImagesFromAny(Map<String, dynamic> map) {
      final List<String> result = [];

      void addRaw(dynamic val) {
        if (val == null) return;
        if (val is List) {
          for (var e in val) {
            addRaw(e);
          }
          return;
        }
        var str = val.toString().trim();
        if (str.isEmpty || str == 'null' || str == 'undefined') return;

        if (str.startsWith('[') && str.endsWith(']')) {
          str = str.substring(1, str.length - 1).trim();
        }
        if (str.contains(',')) {
          final parts = str.split(',');
          for (var p in parts) {
            addRaw(p);
          }
          return;
        }

        if ((str.startsWith('"') && str.endsWith('"')) ||
            (str.startsWith("'") && str.endsWith("'"))) {
          str = str.substring(1, str.length - 1).trim();
        }
        if (str.isEmpty || str == 'null' || str == 'undefined') return;

        final formatted = EnvConfig.formatImageUrl(str);
        if (formatted.isNotEmpty && !result.contains(formatted)) {
          result.add(formatted);
        }
      }

      final keysToTry = [
        'images',
        'image',
        'subcategoryImage',
        'subcategory_image',
        'subcategoryImages',
        'subcategory_images',
        'imageUrl',
        'image_url',
        'img',
        'imgUrl',
        'img_url',
        'imagePath',
        'image_path',
        'photo',
        'picture',
      ];

      for (final key in keysToTry) {
        if (map[key] != null) {
          addRaw(map[key]);
        }
      }

      return result;
    }

    List<String> imgList = parseImagesFromAny(json);

    if (imgList.isEmpty && json['subcategory'] is Map<String, dynamic>) {
      imgList = parseImagesFromAny(json['subcategory'] as Map<String, dynamic>);
    }
    if (imgList.isEmpty && json['subCategory'] is Map<String, dynamic>) {
      imgList = parseImagesFromAny(json['subCategory'] as Map<String, dynamic>);
    }
    if (imgList.isEmpty && json['product'] is Map<String, dynamic>) {
      imgList = parseImagesFromAny(json['product'] as Map<String, dynamic>);
    }
    if (imgList.isEmpty && json['item'] is Map<String, dynamic>) {
      imgList = parseImagesFromAny(json['item'] as Map<String, dynamic>);
    }

    final rawType =
        (json['sub_category_type'] ??
                json['subCategoryType'] ??
                json['subcategory_type'] ??
                json['subcategoryType'] ??
                json['category_type'] ??
                json['categoryType'] ??
                json['unit_type'] ??
                json['unitType'] ??
                json['type'] ??
                json['unit'] ??
                (json['subcategory'] is Map<String, dynamic>
                    ? (json['subcategory']
                              as Map<String, dynamic>)['sub_category_type'] ??
                          (json['subcategory']
                              as Map<String, dynamic>)['subCategoryType'] ??
                          (json['subcategory']
                              as Map<String, dynamic>)['category_type'] ??
                          (json['subcategory']
                              as Map<String, dynamic>)['categoryType']
                    : null))
            ?.toString()
            .trim();

    if (json['subcategory'] is Map<String, dynamic>) {
      final sub = json['subcategory'] as Map<String, dynamic>;
      name ??= sub['subcategoryName'] ?? sub['name'] ?? sub['title'];
      if (sub['amount'] != null && (amount == null || amount == 0.0)) {
        amount = double.tryParse(sub['amount'].toString());
      }
    }

    final parsedQty = num.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
    final itemTot =
        double.tryParse(
          json['itemTotal']?.toString() ?? json['total']?.toString() ?? '0',
        ) ??
        0.0;
    final total = itemTot > 0 ? itemTot : ((amount ?? 0.0) * parsedQty);

    final rawOrig =
        json['original_amount'] ??
        json['originalAmount'] ??
        json['mrp'] ??
        json['totalOriginalAmount'] ??
        (json['subcategory'] is Map<String, dynamic>
            ? (json['subcategory']
                      as Map<String, dynamic>)['original_amount'] ??
                  (json['subcategory']
                      as Map<String, dynamic>)['originalAmount']
            : null);
    final origAmt = rawOrig != null
        ? double.tryParse(rawOrig.toString())
        : null;

    final rawOff =
        json['totalOfferAmount'] ??
        json['total_offer_amount'] ??
        json['offerAmount'] ??
        json['offer_amount'];
    final offAmt = rawOff != null ? double.tryParse(rawOff.toString()) : null;

    return OrderItemModel(
      id: json['id'],
      categoryId: json['categoryId'],
      subcategoryId: json['subcategoryId'],
      quantity: parsedQty,
      itemTotal: total,
      subcategoryName: name,
      subcategoryAmount: amount,
      images: imgList,
      subCategoryType: rawType,
      originalAmount: origAmt,
      offerAmount: offAmt,
    );
  }
}

class OrderModel {
  final dynamic id;
  final dynamic userId;
  final double subTotal;
  final int totalItems;
  final double deliveryFee;
  final double total;
  final OrderStatusModel? orderStatus;
  final List<StatusHistoryItemModel> statusHistory;
  final CartSummaryModel? cartSummary;
  final List<OrderItemModel> items;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? paymentMethod;
  final String? createdAt;
  final String? updatedAt;

  OrderModel({
    required this.id,
    this.userId,
    required this.subTotal,
    required this.totalItems,
    required this.deliveryFee,
    required this.total,
    this.orderStatus,
    this.statusHistory = const [],
    this.cartSummary,
    this.items = const [],
    this.address,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> raw) {
    // 1. Data root map
    final dataMap = (raw['data'] is Map<String, dynamic>)
        ? raw['data'] as Map<String, dynamic>
        : raw;

    // 2. Order map
    final orderMap = (dataMap['order'] is Map<String, dynamic>)
        ? dataMap['order'] as Map<String, dynamic>
        : (raw['order'] is Map<String, dynamic>
              ? raw['order'] as Map<String, dynamic>
              : null);

    final json =
        orderMap ??
        (dataMap.containsKey('orderId') || dataMap.containsKey('id')
            ? dataMap
            : raw);

    OrderStatusModel? statusObj;
    if (json['orderStatus'] is Map<String, dynamic>) {
      statusObj = OrderStatusModel.fromJson(json['orderStatus']);
    } else if (dataMap['orderStatus'] is Map<String, dynamic>) {
      statusObj = OrderStatusModel.fromJson(dataMap['orderStatus']);
    }

    List<StatusHistoryItemModel> historyList = [];
    final rawHistory = json['statusHistory'] ?? dataMap['statusHistory'];
    if (rawHistory is List) {
      historyList = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((item) => StatusHistoryItemModel.fromJson(item))
          .toList();
    }

    CartSummaryModel? summary;
    if (json['cartSummary'] is Map<String, dynamic>) {
      summary = CartSummaryModel.fromJson(json['cartSummary']);
    } else if (dataMap['cartSummary'] is Map<String, dynamic>) {
      summary = CartSummaryModel.fromJson(dataMap['cartSummary']);
    }

    List<OrderItemModel> itemList = [];
    final rawItems = json['items'] ?? dataMap['items'] ?? raw['items'];
    if (rawItems is List) {
      itemList = rawItems
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }

    Map<String, dynamic>? addressMap;
    if (json['address'] is Map<String, dynamic>) {
      addressMap = Map<String, dynamic>.from(json['address']);
    } else if (dataMap['address'] is Map<String, dynamic>) {
      addressMap = Map<String, dynamic>.from(dataMap['address']);
    } else if (raw['address'] is Map<String, dynamic>) {
      addressMap = Map<String, dynamic>.from(raw['address']);
    } else if (json['deliveryAddress'] is Map<String, dynamic>) {
      addressMap = Map<String, dynamic>.from(json['deliveryAddress']);
    } else {
      addressMap = {};
    }

    Map<String, dynamic>? paymentMap;
    if (json['paymentMethod'] is Map<String, dynamic>) {
      paymentMap = Map<String, dynamic>.from(json['paymentMethod']);
    } else if (dataMap['paymentMethod'] is Map<String, dynamic>) {
      paymentMap = Map<String, dynamic>.from(dataMap['paymentMethod']);
    } else if (raw['paymentMethod'] is Map<String, dynamic>) {
      paymentMap = Map<String, dynamic>.from(raw['paymentMethod']);
    } else if (json['paymentMethod'] is String &&
        (json['paymentMethod'] as String).isNotEmpty) {
      paymentMap = {'paymentType': json['paymentMethod']};
    } else if (dataMap['paymentMethod'] is String &&
        (dataMap['paymentMethod'] as String).isNotEmpty) {
      paymentMap = {'paymentType': dataMap['paymentMethod']};
    }

    String getVal(List<dynamic> options) {
      for (var opt in options) {
        if (opt != null && opt.toString().trim().isNotEmpty) {
          return opt.toString().trim();
        }
      }
      return '';
    }

    // Extract fullName if missing or empty in addressMap
    final existingName =
        addressMap['fullName'] ??
        addressMap['full_name'] ??
        addressMap['name'] ??
        addressMap['receiverName'] ??
        addressMap['userName'];
    if (existingName == null || existingName.toString().trim().isEmpty) {
      final userObj = json['user'] is Map<String, dynamic>
          ? json['user']
          : (dataMap['user'] is Map<String, dynamic> ? dataMap['user'] : null);
      final resolvedName = getVal([
        userObj?['fullName'],
        userObj?['full_name'],
        userObj?['name'],
        json['fullName'],
        json['full_name'],
        json['name'],
        dataMap['fullName'],
        dataMap['full_name'],
      ]);
      if (resolvedName.isNotEmpty) {
        addressMap['fullName'] = resolvedName;
      }
    }

    // Extract phoneNumber if missing or empty in addressMap
    final existingPhone =
        addressMap['phoneNumber'] ??
        addressMap['phone_number'] ??
        addressMap['phone'] ??
        addressMap['mobile'];
    if (existingPhone == null || existingPhone.toString().trim().isEmpty) {
      final userObj = json['user'] is Map<String, dynamic>
          ? json['user']
          : (dataMap['user'] is Map<String, dynamic> ? dataMap['user'] : null);
      final resolvedPhone = getVal([
        userObj?['phoneNumber'],
        userObj?['phone_number'],
        userObj?['phone'],
        userObj?['mobile'],
        json['phoneNumber'],
        json['phone_number'],
        dataMap['phoneNumber'],
        dataMap['phone_number'],
      ]);
      if (resolvedPhone.isNotEmpty) {
        addressMap['phoneNumber'] = resolvedPhone;
      }
    }

    final idVal =
        json['id'] ??
        json['orderId'] ??
        json['order_id'] ??
        dataMap['id'] ??
        dataMap['orderId'] ??
        0;
    final subTotalVal =
        double.tryParse(
          (json['subTotal'] ??
                  json['sub_total'] ??
                  dataMap['subTotal'] ??
                  dataMap['sub_total'] ??
                  '0')
              .toString(),
        ) ??
        0.0;
    final deliveryFeeVal =
        double.tryParse(
          (json['deliveryFee'] ??
                  json['delivery_fee'] ??
                  dataMap['deliveryFee'] ??
                  dataMap['delivery_fee'] ??
                  '0')
              .toString(),
        ) ??
        0.0;
    final totalVal =
        double.tryParse(
          (json['total'] ??
                  json['grandTotal'] ??
                  dataMap['total'] ??
                  dataMap['grandTotal'] ??
                  '0')
              .toString(),
        ) ??
        0.0;

    return OrderModel(
      id: idVal,
      userId: json['userId'] ?? json['user_id'] ?? dataMap['userId'],
      subTotal: subTotalVal,
      totalItems:
          int.tryParse(
            (json['totalItems'] ?? dataMap['totalItems'] ?? itemList.length)
                .toString(),
          ) ??
          itemList.length,
      deliveryFee: deliveryFeeVal,
      total: totalVal,
      orderStatus: statusObj,
      statusHistory: historyList,
      cartSummary: summary,
      items: itemList,
      address: addressMap,
      paymentMethod: paymentMap,
      createdAt:
          (json['createdAt'] ?? json['created_at'] ?? dataMap['createdAt'])
              ?.toString(),
      updatedAt:
          (json['updatedAt'] ?? json['updated_at'] ?? dataMap['updatedAt'])
              ?.toString(),
    );
  }

  /// Amount helper: Returns the sum of cartSummary.totalAmount + cartSummary.deliveryFee
  double get effectiveAmount {
    if (cartSummary != null) {
      return cartSummary!.totalAmount + cartSummary!.deliveryFee;
    }
    if (total > 0) return total;
    if (subTotal > 0) return subTotal + deliveryFee;
    return 0.0;
  }

  /// Order Date & Time helper: Uses orderStatus.createdAt as instructed, fallback to order createdAt
  String? get effectiveCreatedAt {
    if (orderStatus?.createdAt != null && orderStatus!.createdAt!.isNotEmpty) {
      return orderStatus!.createdAt;
    }
    return createdAt;
  }

  /// Current order status helper
  String get currentStatus {
    if (orderStatus?.status != null && orderStatus!.status.isNotEmpty) {
      return orderStatus!.status;
    }
    if (statusHistory.isNotEmpty) {
      return statusHistory.last.status;
    }
    return 'ordered';
  }

  double get calculatedSubTotal {
    if (subTotal > 0) return subTotal;
    if (items.isNotEmpty) {
      return items.fold<double>(0.0, (sum, item) => sum + item.itemTotal);
    }
    return 0.0;
  }

  double get calculatedOriginalSubTotal {
    if (items.isNotEmpty) {
      final sumOrig = items.fold<double>(
        0.0,
        (sum, item) => sum + item.totalOriginalAmount,
      );
      if (sumOrig > calculatedSubTotal) return sumOrig;
    }
    return calculatedSubTotal;
  }

  double get calculatedTotalSavings {
    final savings = calculatedOriginalSubTotal - calculatedSubTotal;
    return savings > 0 ? savings : 0.0;
  }

  bool get isFreeDelivery {
    return deliveryFee == 0 || calculatedSubTotal >= 400.0;
  }

  double get baseDeliveryFee {
    return deliveryFee > 0 ? deliveryFee : 40.0;
  }
}
