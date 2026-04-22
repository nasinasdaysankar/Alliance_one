class Vendor {
  final String id;
  final String shopName;
  final String? ownerName;
  final String phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final double? latitude;
  final double? longitude;
  final String status;
  final String createdAt;

  const Vendor({
    required this.id,
    required this.shopName,
    this.ownerName,
    required this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) => Vendor(
        id: json['id']?.toString() ?? '',
        shopName: json['shop_name']?.toString() ?? '',
        ownerName: json['owner_name']?.toString(),
        phone: json['phone']?.toString() ?? '',
        email: json['email']?.toString(),
        address: json['address']?.toString(),
        city: json['city']?.toString(),
        state: json['state']?.toString(),
        pincode: json['pincode']?.toString(),
        latitude: double.tryParse(json['latitude']?.toString() ?? ''),
        longitude: double.tryParse(json['longitude']?.toString() ?? ''),
        status: json['status']?.toString() ?? 'pending',
        createdAt: json['created_at']?.toString() ?? '',
      );
}
