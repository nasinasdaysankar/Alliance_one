import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(orderListProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(orderListProvider.notifier).refresh(),
        child: state.isLoading && state.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.orders.isEmpty
                ? _empty()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.orders.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= state.orders.length) {
                        ref.read(orderListProvider.notifier).fetch();
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }
                      return _OrderCard(order: state.orders[i]);
                    },
                  ),
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('No orders yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(order.createdAt);
    final dateStr = date != null ? DateFormat('d MMM y').format(date) : '';

    return GestureDetector(
      onTap: () => context.push('/orders/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (status) {
      'delivered' => (Colors.green.shade700, Colors.green.shade50),
      'shipped' => (Colors.blue.shade700, Colors.blue.shade50),
      'packed' => (Colors.orange.shade700, Colors.orange.shade50),
      'confirmed' => (Colors.teal.shade700, Colors.teal.shade50),
      'cancelled' => (Colors.red.shade700, Colors.red.shade50),
      _ => (Colors.grey.shade700, Colors.grey.shade100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
