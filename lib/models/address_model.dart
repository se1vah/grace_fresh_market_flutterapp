class AddressModel {
  final dynamic id;
  final dynamic userId;
  final String buildingName;
  final String streetName;
  final String city;
  final String state;
  final String pincode;
  final String addressType;
  final bool isDefault;
  final String? createdAt;
  final String? updatedAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.buildingName,
    required this.streetName,
    required this.city,
    required this.state,
    required this.pincode,
    required this.addressType,
    required this.isDefault,
    this.createdAt,
    this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) {
        return val.toLowerCase() == 'true' || val == '1';
      }
      return false;
    }

    return AddressModel(
      id: json['id'] ?? json['_id'] ?? 0,
      userId: json['userId'] ?? json['user_id'] ?? 0,
      buildingName: (json['buildingName'] ?? json['building_name'] ?? '').toString(),
      streetName: (json['streetName'] ?? json['street_name'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? json['pinCode'] ?? json['zip'] ?? '').toString(),
      addressType: (json['addressType'] ?? json['address_type'] ?? 'home').toString(),
      isDefault: parseBool(json['isDefault'] ?? json['is_default']),
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      updatedAt: json['updatedAt']?.toString() ?? json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'buildingName': buildingName,
      'streetName': streetName,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': addressType,
      'isDefault': isDefault,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get formattedAddress {
    final parts = <String>[];
    if (buildingName.isNotEmpty) parts.add(buildingName);
    if (streetName.isNotEmpty) parts.add(streetName);
    
    final cityStatePin = [
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
      if (pincode.isNotEmpty) pincode,
    ].join(', ');
    
    if (cityStatePin.isNotEmpty) parts.add(cityStatePin);
    return parts.join('\n');
  }
}
