import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../providers/order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (order) => _buildBody(context, order),
      ),
    );
  }

  Widget _buildBody(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final date = DateTime.tryParse(order.createdAt);
    final dateStr = date != null ? DateFormat('d MMM y, h:mm a').format(date) : '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(16),
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
                    Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    _badge(order.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Payment: ', style: TextStyle(fontSize: 13)),
                    _paymentBadge(order.paymentStatus),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('Order Status', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _StatusTimeline(order: order),

          const SizedBox(height: 20),
          Text('Items', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...order.items.map((item) => _ItemTile(item: item)),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  '₹${order.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String status) {
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

  Widget _paymentBadge(String status) {
    final color = status == 'paid' ? Colors.green : status == 'failed' ? Colors.red : Colors.orange;
    return Text(
      status[0].toUpperCase() + status.substring(1),
      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  final Order order;
  const _StatusTimeline({required this.order});

  @override
  Widget build(BuildContext context) {
    const steps = Order.statusSteps;
    final currentIdx = order.statusIndex;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: List.generate(steps.length, (i) {
        final done = i <= currentIdx;
        final isCurrent = i == currentIdx;
        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (i > 0) Expanded(child: Container(height: 2, color: i <= currentIdx ? primary : Colors.grey.shade200)),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? primary : Colors.grey.shade200,
                      border: isCurrent ? Border.all(color: primary, width: 2) : null,
                    ),
                    child: done
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Expanded(child: Container(height: 2, color: i < currentIdx ? primary : Colors.grey.shade200)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                steps[i][0].toUpperCase() + steps[i].substring(1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  color: done ? primary : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final OrderItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? 'Product', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (item.shopName != null)
                  Text(item.shopName!, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('× ${item.quantity}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              Text('₹${item.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
