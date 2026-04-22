class CartItem {
  final String id;
  final String userId;
  final String vendorProductId;
  final int quantity;
  final double? price;
  final int? stock;
  final String? productName;
  final String? variantSku;
  final String? watt;
  final String? color;
  final String? imageUrl;
  final double? itemTotal;
  final String? shopName;
  final String? vendorId;

  const CartItem({
    required this.id,
    required this.userId,
    required this.vendorProductId,
    required this.quantity,
    this.price,
    this.stock,
    this.productName,
    this.variantSku,
    this.watt,
    this.color,
    this.imageUrl,
    this.itemTotal,
    this.shopName,
    this.vendorId,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        vendorProductId: json['vendor_product_id']?.toString() ?? '',
        quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
        price: double.tryParse(json['price']?.toString() ?? ''),
        stock: int.tryParse(json['stock']?.toString() ?? ''),
        productName: json['product_name']?.toString(),
        variantSku: json['variant_sku']?.toString(),
        watt: json['watt']?.toString(),
        color: json['color']?.toString(),
        imageUrl: json['image_url']?.toString(),
        itemTotal: double.tryParse(json['item_total']?.toString() ?? ''),
        shopName: json['shop_name']?.toString(),
        vendorId: json['vendor_id']?.toString(),
      );

  String get variantLabel {
    final parts = <String>[];
    if (watt != null) parts.add(watt!);
    if (color != null) parts.add(color!);
    return parts.isNotEmpty ? parts.join(' · ') : (variantSku ?? '');
  }

  double get total => itemTotal ?? ((price ?? 0) * quantity);
}
