import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order.dart';
import '../services/order_service.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

class OrderListState {
  final List<Order> orders;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const OrderListState({
    this.orders = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  OrderListState copyWith({
    List<Order>? orders,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      OrderListState(
        orders: orders ?? this.orders,
        isLoading: isLoading ?? this.isLoading,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );
}

class OrderListNotifier extends StateNotifier<OrderListState> {
  final OrderService _service;

  OrderListNotifier(this._service) : super(const OrderListState()) {
    fetch();
  }

  Future<void> fetch({bool refresh = false}) async {
    if (state.isLoading) return;
    final nextPage = refresh ? 1 : state.page;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getOrders(page: nextPage);
      final newOrders = result['orders'] as List<Order>;
      final totalPages = result['total_pages'] as int;
      state = state.copyWith(
        orders: refresh ? newOrders : [...state.orders, ...newOrders],
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

final orderListProvider =
    StateNotifierProvider<OrderListNotifier, OrderListState>((ref) {
  return OrderListNotifier(ref.read(orderServiceProvider));
});

final orderDetailProvider =
    FutureProvider.family<Order, String>((ref, id) async {
  return ref.read(orderServiceProvider).getOrderDetail(id);
});
