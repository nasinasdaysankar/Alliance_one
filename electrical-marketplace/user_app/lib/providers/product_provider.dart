import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/vendor_product.dart';
import '../services/product_service.dart';
import 'category_provider.dart';

// Params for product list
class ProductListParams {
  final String? categoryId;
  final String? search;
  final String? brandId;
  final String? vendorId;
  final double? minPrice;
  final double? maxPrice;

  const ProductListParams({
    this.categoryId,
    this.search,
    this.brandId,
    this.vendorId,
    this.minPrice,
    this.maxPrice,
  });

  @override
  bool operator ==(Object other) =>
      other is ProductListParams &&
      other.categoryId == categoryId &&
      other.search == search &&
      other.brandId == brandId &&
      other.vendorId == vendorId &&
      other.minPrice == minPrice &&
      other.maxPrice == maxPrice;

  @override
  int get hashCode => Object.hash(categoryId, search, brandId, vendorId, minPrice, maxPrice);
}

class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      ProductListState(
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final ProductService _service;
  final ProductListParams params;

  ProductListNotifier(this._service, this.params)
      : super(const ProductListState()) {
    fetch();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;
    if (!state.hasMore && !refresh) return;

    final nextPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    debugPrint('📦 [ProductProvider] Fetching products (page: $nextPage, vendorId: ${params.vendorId}, catId: ${params.categoryId})');

    try {
      final result = await _service.getProducts(
        categoryId: params.categoryId,
        search: params.search,
        brandId: params.brandId,
        vendorId: params.vendorId,
        minPrice: params.minPrice,
        maxPrice: params.maxPrice,
        page: nextPage,
      );
      final newProducts = result['products'] as List<Product>;
      final totalPages = result['total_pages'] as int;
      state = state.copyWith(
        products: refresh ? newProducts : [...state.products, ...newProducts],
        isLoading: false,
        hasMore: nextPage < totalPages,
        page: nextPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> refresh() => fetch(refresh: true);
}

final productListProvider = StateNotifierProvider.family<ProductListNotifier,
    ProductListState, ProductListParams>((ref, params) {
  return ProductListNotifier(ref.read(productServiceProvider), params);
});

final productDetailProvider =
    FutureProvider.family<Product, String>((ref, id) async {
  final service = ref.read(productServiceProvider);
  return service.getProductDetail(id);
});

final vendorsByVariantProvider =
    FutureProvider.family<List<VendorProduct>, String>((ref, variantId) async {
  final service = ref.read(productServiceProvider);
  return service.getVendorsByVariant(variantId);
});
