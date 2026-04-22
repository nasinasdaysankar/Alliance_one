import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../models/vendor_product.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';
import '../../core/utils/toast_helper.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  ProductVariant? _selectedVariant;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    return productAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (product) {
        if (_selectedVariant == null && product.variants.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedVariant = product.variants.first);
          });
        }
        return _buildScaffold(context, product);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Product product) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: product.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.brandName != null)
                    Chip(
                      label: Text(product.brandName!),
                      backgroundColor: theme.colorScheme.primaryContainer,
                      labelStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 8),
                  Text(product.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_selectedVariant != null)
                    Text(
                      '₹${double.tryParse(_selectedVariant!.basePrice.toString())?.toStringAsFixed(0) ?? _selectedVariant!.basePrice}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (product.description != null) ...[
                    const SizedBox(height: 12),
                    Text(product.description!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                  ],
                  if (product.variants.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text('Select Variant', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.variants.map((v) {
                        final selected = _selectedVariant?.id == v.id;
                        return ChoiceChip(
                          label: Text(v.displayLabel),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedVariant = v),
                        );
                      }).toList(),
                    ),
                  ],
                  if (_selectedVariant != null) ...[
                    const Divider(height: 32),
                    Row(
                      children: [
                        const Icon(Icons.verified_user_outlined, size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text('Verified Shop Availability', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _VendorList(
                      variantId: _selectedVariant!.id,
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        color: Colors.grey.shade100,
        child: const Center(child: Icon(Icons.electrical_services, size: 64, color: Colors.grey)),
      );
}

class _VendorList extends ConsumerWidget {
  final String variantId;
  const _VendorList({required this.variantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(vendorsByVariantProvider(variantId));
    return vendorsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text(e.toString()),
      data: (vendors) {
        if (vendors.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text('No vendors available for this variant')),
          );
        }
        // Sort by price ascending
        final sorted = [...vendors]..sort((a, b) => a.price.compareTo(b.price));
        return Column(
          children: sorted.map((v) => _VendorTile(vendor: v)).toList(),
        );
      },
    );
  }
}

class _VendorTile extends ConsumerWidget {
  final VendorProduct vendor;
  const _VendorTile({required this.vendor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final inStock = vendor.isAvailable && vendor.stock > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.shopName ?? 'Shop', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  inStock ? 'In Stock (${vendor.stock})' : 'Out of Stock',
                  style: TextStyle(
                    fontSize: 12,
                    color: inStock ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${vendor.price.toStringAsFixed(0)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 34,
                child: FilledButton(
                  onPressed: inStock
                      ? () async {
                          try {
                            await ref.read(cartProvider.notifier).addItem(vendor.id, 1);
                            ToastHelper.success('Added to cart');
                          } catch (e) {
                            ToastHelper.error(e.toString());
                          }
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Add to Cart', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
