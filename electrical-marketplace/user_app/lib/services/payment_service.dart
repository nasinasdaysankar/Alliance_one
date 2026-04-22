import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';

class PaymentService {
  final _dio = ApiClient.instance;

  Future<Map<String, dynamic>> createPayment(String orderId) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.createPayment,
        data: {'order_id': orderId},
      );
      final data = ApiClient.extractData(res);
      return data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.verifyPayment,
        data: {
          'razorpay_order_id': razorpayOrderId,
          'razorpay_payment_id': razorpayPaymentId,
          'razorpay_signature': razorpaySignature,
        },
      );
      final body = res.data as Map<String, dynamic>;
      return body['success'] == true;
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
