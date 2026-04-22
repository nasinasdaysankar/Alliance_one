import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 45),
        receiveTimeout: const Duration(seconds: 45),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await SecureStorage.clearAll();
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }

  static dynamic extractData(Response response) {
    final body = response.data;
    if (body is Map && body.containsKey('data')) {
      return body['data'];
    }
    return body;
  }

  static String extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      // Backend returns errors under 'error' key, sometimes 'message'
      if (data.containsKey('error')) return data['error'].toString();
      if (data.containsKey('message')) return data['message'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return 'Cannot connect to server. Make sure the backend is running.';
    }
    return e.message ?? 'Something went wrong';
  }
}
