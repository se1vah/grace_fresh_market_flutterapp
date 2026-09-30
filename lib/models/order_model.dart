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
  });

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
      final kgStr = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
      return '$kgStr KG';
    }
    if (unit.isNotEmpty) {
      final qtyStr = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
      return '$qtyStr $unit';
    }
    final qtyStr = quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toString();
    return qtyStr;
  }

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    String? name = json['subcategoryName'] ?? json['name'] ?? json['title'] ?? json['productName'];
    double? amount = double.tryParse(
      (json['subcategoryAmount'] ?? json['amount'] ?? json['price'] ?? '0')
          .toString(),
    );
    List<String> imgList = [];

    if (json['images'] is List) {
      imgList = (json['images'] as List)
          .map((e) => EnvConfig.formatImageUrl(e.toString()))
          .toList();
    } else if (json['image'] != null) {
      imgList = [EnvConfig.formatImageUrl(json['image'].toString())];
    }

    final rawType = (json['sub_category_type'] ??
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
                ? (json['subcategory'] as Map<String, dynamic>)['sub_category_type'] ??
                    (json['subcategory'] as Map<String, dynamic>)['subCategoryType'] ??
                    (json['subcategory'] as Map<String, dynamic>)['category_type'] ??
                    (json['subcategory'] as Map<String, dynamic>)['categoryType']
                : null))
        ?.toString()
        .trim();

    if (json['subcategory'] is Map<String, dynamic>) {
      final sub = json['subcategory'] as Map<String, dynamic>;
      name ??= sub['subcategoryName'] ?? sub['name'] ?? sub['title'];
      if (sub['amount'] != null && (amount == null || amount == 0.0)) {
        amount = double.tryParse(sub['amount'].toString());
      }
      if (imgList.isEmpty && sub['images'] is List) {
        imgList = (sub['images'] as List)
            .map((e) => EnvConfig.formatImageUrl(e.toString()))
            .toList();
      } else if (imgList.isEmpty && sub['image'] != null) {
        imgList = [EnvConfig.formatImageUrl(sub['image'].toString())];
      }
    }

    final parsedQty = num.tryParse(json['quantity']?.toString() ?? '1') ?? 1;
    final itemTot = double.tryParse(
          json['itemTotal']?.toString() ?? json['total']?.toString() ?? '0',
        ) ??
        0.0;
    final total = itemTot > 0 ? itemTot : ((amount ?? 0.0) * parsedQty);

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

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    OrderStatusModel? statusObj;
    if (json['orderStatus'] is Map<String, dynamic>) {
      statusObj = OrderStatusModel.fromJson(json['orderStatus']);
    }

    List<StatusHistoryItemModel> historyList = [];
    if (json['statusHistory'] is List) {
      historyList = (json['statusHistory'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => StatusHistoryItemModel.fromJson(item))
          .toList();
    }

    CartSummaryModel? summary;
    if (json['cartSummary'] is Map<String, dynamic>) {
      summary = CartSummaryModel.fromJson(json['cartSummary']);
    }

    List<OrderItemModel> itemList = [];
    if (json['items'] is List) {
      itemList = (json['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((item) => OrderItemModel.fromJson(item))
          .toList();
    }

    Map<String, dynamic>? addressMap;
    if (json['address'] is Map<String, dynamic>) {
      addressMap = Map<String, dynamic>.from(json['address']);
    } else if (json['deliveryAddress'] is Map<String, dynamic>) {
      addressMap = Map<String, dynamic>.from(json['deliveryAddress']);
    } else {
      addressMap = {};
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
    final existingName = addressMap['fullName'] ??
        addressMap['full_name'] ??
        addressMap['name'] ??
        addressMap['receiverName'] ??
        addressMap['userName'];
    if (existingName == null || existingName.toString().trim().isEmpty) {
      final userObj = json['user'] is Map<String, dynamic> ? json['user'] : null;
      final resolvedName = getVal([
        userObj?['fullName'],
        userObj?['full_name'],
        userObj?['name'],
        json['fullName'],
        json['full_name'],
        json['name'],
        json['userName'],
        json['user_name'],
      ]);
      if (resolvedName.isNotEmpty) {
        addressMap['fullName'] = resolvedName;
      }
    }

    // Extract phoneNumber if missing or empty in addressMap
    final existingPhone = addressMap['phoneNumber'] ??
        addressMap['phone_number'] ??
        addressMap['phone'] ??
        addressMap['mobile'];
    if (existingPhone == null || existingPhone.toString().trim().isEmpty) {
      final userObj = json['user'] is Map<String, dynamic> ? json['user'] : null;
      final resolvedPhone = getVal([
        userObj?['phoneNumber'],
        userObj?['phone_number'],
        userObj?['phone'],
        userObj?['mobile'],
        json['phoneNumber'],
        json['phone_number'],
        json['phone'],
        json['mobile'],
        json['userPhone'],
      ]);
      if (resolvedPhone.isNotEmpty) {
        addressMap['phoneNumber'] = resolvedPhone;
      }
    }

    return OrderModel(
      id: json['id'] ?? json['orderId'] ?? json['order_id'] ?? 0,
      userId: json['userId'] ?? json['user_id'],
      subTotal: double.tryParse(json['subTotal']?.toString() ?? '0') ?? 0.0,
      totalItems: int.tryParse(json['totalItems']?.toString() ?? '0') ?? 0,
      deliveryFee:
          double.tryParse(json['deliveryFee']?.toString() ?? '0') ?? 0.0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      orderStatus: statusObj,
      statusHistory: historyList,
      cartSummary: summary,
      items: itemList,
      address: addressMap,
      paymentMethod: json['paymentMethod'] is Map<String, dynamic>
          ? json['paymentMethod']
          : null,
      createdAt:
          json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt:
          json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
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
}
