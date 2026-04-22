class OrderItem {
  final String id;
  final String orderId;
  final String vendorId;
  final String variantId;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String itemStatus;
  final String? productName;
  final String? variantSku;
  final String? shopName;
  final String? imageUrl;
  final String? watt;
  final String? color;

  const OrderItem({
    required this.id,
    required this.orderId,
    required this.vendorId,
    required this.variantId,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.itemStatus,
    this.productName,
    this.variantSku,
    this.shopName,
    this.imageUrl,
    this.watt,
    this.color,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        vendorId: json['vendor_id']?.toString() ?? '',
        variantId: json['variant_id']?.toString() ?? '',
        quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
        unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0,
        totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0,
        itemStatus: json['item_status']?.toString() ?? 'pending',
        productName: json['product_name']?.toString(),
        variantSku: json['variant_sku']?.toString(),
        shopName: json['shop_name']?.toString(),
        imageUrl: json['image_url']?.toString(),
        watt: json['watt']?.toString(),
        color: json['color']?.toString(),
      );
}

class Order {
  final String id;
  final String userId;
  final String? addressId;
  final double totalAmount;
  final String status;
  final String paymentStatus;
  final String? razorpayOrderId;
  final String? razorpayPaymentId;
  final String? notes;
  final String createdAt;
  final String updatedAt;
  final List<OrderItem> items;

  const Order({
    required this.id,
    required this.userId,
    this.addressId,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.razorpayOrderId,
    this.razorpayPaymentId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        addressId: json['address_id']?.toString(),
        totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0,
        status: json['status']?.toString() ?? 'pending',
        paymentStatus: json['payment_status']?.toString() ?? 'pending',
        razorpayOrderId: json['razorpay_order_id']?.toString(),
        razorpayPaymentId: json['razorpay_payment_id']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
                .toList() ??
            [],
      );

  static const List<String> statusSteps = [
    'pending',
    'confirmed',
    'packed',
    'shipped',
    'delivered',
  ];

  int get statusIndex => statusSteps.indexOf(status);
}
