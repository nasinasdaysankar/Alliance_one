class Address {
  final String id;
  final String userId;
  final String? label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;

  const Address({
    required this.id,
    required this.userId,
    this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        label: json['label']?.toString(),
        addressLine1: json['address_line1']?.toString() ?? '',
        addressLine2: json['address_line2']?.toString(),
        city: json['city']?.toString() ?? '',
        state: json['state']?.toString() ?? '',
        pincode: json['pincode']?.toString() ?? '',
        isDefault: json['is_default'] == true,
      );

  String get fullAddress {
    final parts = [
      addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) addressLine2!,
      city,
      state,
      pincode,
    ];
    return parts.join(', ');
  }
}
