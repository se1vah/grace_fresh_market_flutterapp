class DeliveryAddressData {
  final dynamic id;
  final String fullName;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;

  DeliveryAddressData({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
  });

  factory DeliveryAddressData.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressData(
      id: json['id'] ?? json['_id'] ?? 0,
      fullName: (json['fullName'] ?? json['full_name'] ?? json['name'] ?? '')
          .toString(),
      phoneNumber:
          (json['phoneNumber'] ?? json['phone_number'] ?? json['phone'] ?? '')
              .toString(),
      addressLine1:
          (json['addressLine1'] ??
                  json['address_line1'] ??
                  json['buildingName'] ??
                  '')
              .toString(),
      addressLine2:
          (json['addressLine2'] ??
                  json['address_line2'] ??
                  json['streetName'] ??
                  '')
              .toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      postalCode:
          (json['postalCode'] ??
                  json['postal_code'] ??
                  json['pincode'] ??
                  json['zip'] ??
                  '')
              .toString(),
    );
  }

  String get formattedAddressLines {
    final List<String> parts = [];
    if (addressLine1.isNotEmpty) parts.add(addressLine1);
    if (addressLine2.isNotEmpty && addressLine2 != addressLine1) {
      parts.add(addressLine2);
    }
    final cityStateZip = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (postalCode.isNotEmpty) postalCode,
    ].join(', ');
    if (cityStateZip.isNotEmpty) parts.add(cityStateZip);
    return parts.join('\n');
  }
}

class PaymentMethodData {
  final dynamic id;
  final String paymentType;
  final String description;

  PaymentMethodData({
    required this.id,
    required this.paymentType,
    required this.description,
  });

  factory PaymentMethodData.fromJson(Map<String, dynamic> json) {
    return PaymentMethodData(
      id: json['id'] ?? json['_id'] ?? 0,
      paymentType: (json['paymentType'] ?? json['payment_type'] ?? 'COD')
          .toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  String get displayTitle {
    final upper = paymentType.toUpperCase();
    if (upper == 'COD' || upper.contains('CASH')) {
      return 'Cash on Delivery (COD)';
    }
    return paymentType;
  }
}

class CheckoutDetails {
  final DeliveryAddressData? deliveryAddress;
  final List<PaymentMethodData> paymentMethods;

  CheckoutDetails({this.deliveryAddress, this.paymentMethods = const []});

  factory CheckoutDetails.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> dataMap = json;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      dataMap = json['data'] as Map<String, dynamic>;
    }

    DeliveryAddressData? addr;
    if (dataMap.containsKey('deliveryAddress') &&
        dataMap['deliveryAddress'] is Map<String, dynamic>) {
      addr = DeliveryAddressData.fromJson(
        dataMap['deliveryAddress'] as Map<String, dynamic>,
      );
    } else if (dataMap.containsKey('address') &&
        dataMap['address'] is Map<String, dynamic>) {
      addr = DeliveryAddressData.fromJson(
        dataMap['address'] as Map<String, dynamic>,
      );
    }

    List<PaymentMethodData> methods = [];
    if (dataMap.containsKey('paymentMethods') &&
        dataMap['paymentMethods'] is List) {
      methods = (dataMap['paymentMethods'] as List)
          .whereType<Map<String, dynamic>>()
          .map((m) => PaymentMethodData.fromJson(m))
          .toList();
    }

    return CheckoutDetails(deliveryAddress: addr, paymentMethods: methods);
  }
}
