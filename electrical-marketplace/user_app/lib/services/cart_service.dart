import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/cart_item.dart';

class CartService {
  final _dio = ApiClient.instance;

  Future<List<CartItem>> getCart() async {
    try {
      final res = await _dio.get(ApiEndpoints.cart);
      final data = ApiClient.extractData(res);
      final list = data is List ? data : <dynamic>[];
      return list
          .map((c) => CartItem.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<CartItem> addToCart(String vendorProductId, int quantity) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.cart,
        data: {'vendor_product_id': vendorProductId, 'quantity': quantity},
      );
      final data = ApiClient.extractData(res);
      return CartItem.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<CartItem> updateQuantity(String cartItemId, int quantity) async {
    try {
      final res = await _dio.put(
        ApiEndpoints.cartItem(cartItemId),
        data: {'quantity': quantity},
      );
      final data = ApiClient.extractData(res);
      return CartItem.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<void> removeFromCart(String cartItemId) async {
    try {
      await _dio.delete(ApiEndpoints.cartItem(cartItemId));
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiEndpoints.cart);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
