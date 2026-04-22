import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/address.dart';
import '../../providers/cart_provider.dart';
import '../../providers/address_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';
import '../../core/utils/toast_helper.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  Address? _selectedAddress;
  bool _isPlacing = false;
  late Razorpay _razorpay;
  String? _pendingOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final addresses = ref.read(addressProvider).valueOrNull ?? [];
      if (addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = addresses.firstWhere(
            (a) => a.isDefault,
            orElse: () => addresses.first,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      ToastHelper.error('Please select a delivery address');
      return;
    }
    setState(() => _isPlacing = true);
    try {
      final order = await ref
          .read(orderServiceProvider)
          .createOrder(addressId: _selectedAddress!.id);
      _pendingOrderId = order.id;

      final paymentData = await PaymentService().createPayment(order.id);
      final options = {
        'key': paymentData['key_id'] ?? '',
        'amount': paymentData['amount'],
        'currency': paymentData['currency'] ?? 'INR',
        'order_id': paymentData['razorpay_order_id'] ?? paymentData['id'],
        'name': 'ElectroMart',
        'description': 'Order #${order.id.substring(0, 8)}',
        'prefill': {'contact': ''},
      };
      _razorpay.open(options);
    } catch (e) {
      ToastHelper.error(e.toString());
      setState(() => _isPlacing = false);
    }
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await PaymentService().verifyPayment(
        razorpayOrderId: response.orderId ?? '',
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature ?? '',
      );
      await ref.read(cartProvider.notifier).clear();
      ref.read(orderListProvider.notifier).refresh();
      if (!mounted) return;
      ToastHelper.success('Payment successful!');
      context.go('/orders/$_pendingOrderId');
    } catch (e) {
      ToastHelper.error('Payment verification failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    ToastHelper.error('Payment failed: ${response.message ?? 'Unknown error'}');
    setState(() => _isPlacing = false);
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    ToastHelper.info('External wallet: ${response.walletName}');
    setState(() => _isPlacing = false);
  }

  @override
  Widget build(BuildContext context) {
    final cartAsync = ref.watch(cartProvider);
    final addressAsync = ref.watch(addressProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (items) {
          final total = items.fold<double>(0, (s, i) => s + i.total);
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Address section
                    Text('Delivery Address', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    addressAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (addresses) => Column(
                        children: [
                          if (_selectedAddress != null)
                            _AddressTile(address: _selectedAddress!, onTap: () => _pickAddress(context))
                          else
                            OutlinedButton.icon(
                              onPressed: () => _pickAddress(context),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Address'),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Order summary
                    Text('Order Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ...items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName ?? 'Product'} × ${item.quantity}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text('₹${item.total.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('₹${total.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: theme.colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isPlacing ? null : _placeOrder,
                      child: _isPlacing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text('Place Order & Pay ₹${total.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickAddress(BuildContext context) async {
    final result = await context.push<Address>('/addresses?select=true');
    if (result != null) setState(() => _selectedAddress = result);
  }
}

class _AddressTile extends StatelessWidget {
  final Address address;
  final VoidCallback onTap;
  const _AddressTile({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (address.label != null)
                    Text(address.label!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(address.fullAddress, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
