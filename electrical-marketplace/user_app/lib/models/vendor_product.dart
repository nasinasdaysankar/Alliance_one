class VendorProduct {
  final String id;
  final String vendorId;
  final String variantId;
  final double price;
  final int stock;
  final bool isAvailable;
  final String? shopName;
  final String? variantSku;
  final String? productName;
  final double? distanceKm;

  const VendorProduct({
    required this.id,
    required this.vendorId,
    required this.variantId,
    required this.price,
    required this.stock,
    required this.isAvailable,
    this.shopName,
    this.variantSku,
    this.productName,
    this.distanceKm,
  });

  factory VendorProduct.fromJson(Map<String, dynamic> json) => VendorProduct(
        id: json['id']?.toString() ?? '',
        vendorId: json['vendor_id']?.toString() ?? '',
        variantId: json['variant_id']?.toString() ?? '',
        price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
        stock: int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
        isAvailable: json['is_available'] != false,
        shopName: json['shop_name']?.toString(),
        variantSku: json['variant_sku']?.toString(),
        productName: json['product_name']?.toString(),
        distanceKm: double.tryParse(json['distance_km']?.toString() ?? ''),
      );
}
