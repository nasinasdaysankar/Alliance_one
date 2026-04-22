import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        actions: [
          cartAsync.valueOrNull?.isNotEmpty == true
              ? TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Clear Cart'),
                        content: const Text('Remove all items from cart?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await ref.read(cartProvider.notifier).clear();
                    }
                  },
                  child: const Text('Clear'),
                )
              : const SizedBox.shrink(),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          if (items.isEmpty) return _EmptyCart();
          final grouped = _groupByVendor(items);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.store, size: 16),
                              const SizedBox(width: 6),
                              Text(entry.key, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        ...entry.value.map((item) => _CartItemTile(item: item)),
                        const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              ),
              _CheckoutBar(items: items),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<CartItem>> _groupByVendor(List<CartItem> items) {
    final map = <String, List<CartItem>>{};
    for (final item in items) {
      final key = item.shopName ?? 'Unknown Shop';
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 64,
              height: 64,
              child: item.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.variantLabel.isNotEmpty)
                  Text(item.variantLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${item.price?.toStringAsFixed(0) ?? '0'}',
                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    _QuantityStepper(item: item),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Icon(Icons.electrical_services, color: Colors.grey),
      );
}

class _QuantityStepper extends ConsumerWidget {
  final CartItem item;
  const _QuantityStepper({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepBtn(Icons.remove, () {
          ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1);
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        _stepBtn(Icons.add, () {
          ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
        }),
      ],
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  final List<CartItem> items;
  const _CheckoutBar({required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (s, i) => s + i.total);
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -2))],
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Total', style: TextStyle(color: Colors.grey)),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton(
                onPressed: () => context.push('/checkout'),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
                child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Your cart is empty', style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Browse Products'),
          ),
        ],
      ),
    );
  }
}
