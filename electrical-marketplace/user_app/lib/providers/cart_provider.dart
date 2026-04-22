import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

final cartServiceProvider = Provider<CartService>((ref) => CartService());

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  final CartService _service;

  CartNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await _service.getCart();
      state = AsyncValue.data(items);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addItem(String vendorProductId, int quantity) async {
    await _service.addToCart(vendorProductId, quantity);
    await load();
  }

  Future<void> updateQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(cartItemId);
      return;
    }
    await _service.updateQuantity(cartItemId, quantity);
    await load();
  }

  Future<void> removeItem(String cartItemId) async {
    await _service.removeFromCart(cartItemId);
    await load();
  }

  Future<void> clear() async {
    await _service.clearCart();
    state = const AsyncValue.data([]);
  }

  int get itemCount {
    return state.valueOrNull?.fold<int>(0, (sum, i) => sum + i.quantity) ?? 0;
  }

  double get total {
    return state.valueOrNull?.fold<double>(0, (sum, i) => sum + i.total) ?? 0;
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  return CartNotifier(ref.read(cartServiceProvider));
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider.notifier).itemCount;
});
