class ProductVariant {
  final String id;
  final String productId;
  final String skuCode;
  final String? watt;
  final String? color;
  final String? dimension;
  final String? voltage;
  final String? material;
  final double basePrice;
  final String? imageUrl;
  final bool isActive;
  final int? vendorCount;
  final double? minPrice;
  final double? maxPrice;

  const ProductVariant({
    required this.id,
    required this.productId,
    required this.skuCode,
    this.watt,
    this.color,
    this.dimension,
    this.voltage,
    this.material,
    required this.basePrice,
    this.imageUrl,
    required this.isActive,
    this.vendorCount,
    this.minPrice,
    this.maxPrice,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        id: json['id']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        skuCode: json['sku_code']?.toString() ?? '',
        watt: json['watt']?.toString(),
        color: json['color']?.toString(),
        dimension: json['dimension']?.toString(),
        voltage: json['voltage']?.toString(),
        material: json['material']?.toString(),
        basePrice: double.tryParse(json['base_price']?.toString() ?? '0') ?? 0,
        imageUrl: json['image_url']?.toString(),
        isActive: json['is_active'] != false,
        vendorCount: int.tryParse(json['vendor_count']?.toString() ?? ''),
        minPrice: double.tryParse(json['min_price']?.toString() ?? ''),
        maxPrice: double.tryParse(json['max_price']?.toString() ?? ''),
      );

  String get displayLabel {
    final parts = <String>[];
    if (watt != null) parts.add(watt!);
    if (color != null) parts.add(color!);
    return parts.isNotEmpty ? parts.join(' · ') : skuCode;
  }
}

class Product {
  final String id;
  final String name;
  final String? brandId;
  final String? categoryId;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final String? brandName;
  final String? categoryName;
  final List<ProductVariant> variants;

  const Product({
    required this.id,
    required this.name,
    this.brandId,
    this.categoryId,
    this.description,
    this.imageUrl,
    required this.isActive,
    this.brandName,
    this.categoryName,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        brandId: json['brand_id']?.toString(),
        categoryId: json['category_id']?.toString(),
        description: json['description']?.toString(),
        imageUrl: json['image_url']?.toString(),
        isActive: json['is_active'] != false,
        brandName: json['brand_name']?.toString(),
        categoryName: json['category_name']?.toString(),
        variants: (json['variants'] as List<dynamic>?)
                ?.map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
                .toList() ??
            [],
      );

  double? get minPrice {
    if (variants.isEmpty) return null;
    final prices = variants.map((v) => v.minPrice ?? v.basePrice).toList();
    return prices.reduce((a, b) => a < b ? a : b);
  }

  double? get maxPrice {
    if (variants.isEmpty) return null;
    final prices = variants.map((v) => v.maxPrice ?? v.basePrice).toList();
    return prices.reduce((a, b) => a > b ? a : b);
  }
}
