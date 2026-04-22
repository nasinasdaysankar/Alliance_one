import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/constants/api_endpoints.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/vendor_product.dart';
import '../models/vendor.dart';

class ProductService {
  final _dio = ApiClient.instance;

  Future<List<Vendor>> getVendors() async {
    try {
      final res = await _dio.get(ApiEndpoints.vendorsAll);
      final data = ApiClient.extractData(res);
      final list = data is List ? data : <dynamic>[];
      return list.map((v) => Vendor.fromJson(v as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      final res = await _dio.get(ApiEndpoints.categories);
      final data = ApiClient.extractData(res);
      final list = data is List ? data : ((data as Map)['categories'] ?? <dynamic>[]) as List;
      return list
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>> getProducts({
    String? categoryId,
    String? search,
    int page = 1,
    int limit = 20,
    String? brandId,
    String? vendorId,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.products,
        queryParameters: {
          if (categoryId != null) 'category_id': categoryId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (vendorId != null) 'vendor_id': vendorId,
          'page': page,
          'limit': limit,
          if (brandId != null) 'brand_id': brandId,
          if (minPrice != null) 'min_price': minPrice,
          if (maxPrice != null) 'max_price': maxPrice,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final productList = (body['data'] as List?) ?? [];
      final products = productList
          .map((p) => Product.fromJson(p as Map<String, dynamic>))
          .toList();
      return {
        'products': products,
        'total': body['total'] ?? 0,
        'page': body['page'] ?? page,
        'total_pages': body['total_pages'] ?? 1,
      };
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<Product> getProductDetail(String id) async {
    try {
      final res = await _dio.get(ApiEndpoints.productDetail(id));
      final data = ApiClient.extractData(res);
      return Product.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<List<Map<String, dynamic>>> getBrands() async {
    try {
      final res = await _dio.get(ApiEndpoints.brands);
      final data = ApiClient.extractData(res);
      final list = data is List ? data : <dynamic>[];
      return list.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }

  Future<List<VendorProduct>> getVendorsByVariant(String variantId) async {
    try {
      final res = await _dio.get(
        ApiEndpoints.vendors,
        queryParameters: {'variant_id': variantId},
      );
      final data = ApiClient.extractData(res);
      final list = data is List ? data : <dynamic>[];
      return list
          .map((v) => VendorProduct.fromJson(v as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiClient.extractErrorMessage(e);
    }
  }
}
