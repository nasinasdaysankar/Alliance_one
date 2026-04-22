import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/address.dart';

class AddressService {
  final _dio = ApiClient.instance;

  Future<List<Address>> getAddresses() async {
    try {
      final res = await _dio.get(ApiEndpoints.addresses);
      final data = ApiClient.extractData(res);
      final list = data is List ? data : <dynamic>[];
      return list
          .map((a) => Address.fromJson(a as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<Address> addAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String pincode,
    String? label,
  }) async {
    try {
      final res = await _dio.post(
        ApiEndpoints.addresses,
        data: {
          'address_line1': addressLine1,
          if (addressLine2 != null && addressLine2.isNotEmpty)
            'address_line2': addressLine2,
          'city': city,
          'state': state,
          'pincode': pincode,
          if (label != null && label.isNotEmpty) 'label': label,
        },
      );
      final data = ApiClient.extractData(res);
      return Address.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<void> deleteAddress(String id) async {
    try {
      await _dio.delete(ApiEndpoints.addressDetail(id));
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<void> setDefault(String id) async {
    try {
      await _dio.put(ApiEndpoints.setDefaultAddress(id));
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
