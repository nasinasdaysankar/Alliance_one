import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/order.dart';

class OrderService {
  final _dio = ApiClient.instance;

  Future<Map<String, dynamic>> getOrders({int page = 1, int limit = 20}) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.orders,
        queryParameters: {'page': page, 'limit': limit},
      );
      final data = ApiClient.extractData(res) as Map<String, dynamic>;
      final list = data['data'] as List? ?? data['orders'] as List? ?? [];
      return {
        'orders': list.map((o) => Order.fromJson(o as Map<String, dynamic>)).toList(),
        'total': data['total'] ?? 0,
        'total_pages': data['total_pages'] ?? 1,
      };
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<Order> getOrderDetail(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.orderDetail(id));
      final data = ApiClient.extractData(res);
      return Order.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<Order> createOrder({
    required String addressId,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.orders,
        data: {
          'address_id': addressId,
          if (notes != null) 'notes': notes,
        },
      );
      final data = ApiClient.extractData(res);
      return Order.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
