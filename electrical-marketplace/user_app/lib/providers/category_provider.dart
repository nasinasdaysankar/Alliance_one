import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.getCategories();
});

final brandsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.getBrands();
});
