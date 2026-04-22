import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/vendor.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/product.dart';
import '../home/home_screen.dart'; // To reuse _ProductCard if possible, but better to extract it

class VendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String shopName;

  const VendorDetailScreen({
    super.key,
    required this.vendorId,
    required this.shopName,
  });

  @override
  ConsumerState<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends ConsumerState<VendorDetailScreen> {
  String? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    debugPrint('🏪 [VendorDetail] Building for ID: ${widget.vendorId}');
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final productsAsync = ref.watch(
      productListProvider(ProductListParams(
        vendorId: widget.vendorId,
        categoryId: _selectedCategoryId,
      )),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shopName),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(productListProvider(ProductListParams(vendorId: widget.vendorId, categoryId: _selectedCategoryId)).notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Shop Header
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primary.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.shopName,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Text('Authorized Dealer', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Category Filter
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Browse by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),
            SliverToBoxAdapter(
              child: categoriesAsync.when(
                data: (cats) {
                  final parents = cats.where((c) => c.isParent).toList();
                  return SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: parents.length + 1,
                      itemBuilder: (ctx, i) {
                        if (i == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('All'),
                              selected: _selectedCategoryId == null,
                              onSelected: (_) => setState(() => _selectedCategoryId = null),
                            ),
                          );
                        }
                        final cat = parents[i - 1];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(cat.name),
                            selected: _selectedCategoryId == cat.id,
                            onSelected: (selected) {
                              setState(() => _selectedCategoryId = selected ? cat.id : null);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error:   (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Product Grid
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Text('Products', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),

            if (productsAsync.isLoading && productsAsync.products.isEmpty)
               const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())))
            else if (productsAsync.error != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${productsAsync.error}', 
                             textAlign: TextAlign.center,
                             style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.read(productListProvider(ProductListParams(vendorId: widget.vendorId, categoryId: _selectedCategoryId)).notifier).refresh(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (productsAsync.products.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No products found in this shop', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final product = productsAsync.products[i];
                      return ProductCard(product: product);
                    },
                    childCount: productsAsync.products.length,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }
}

// Re-implementing a simple ProductCard to avoid circular dependencies for now
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final min = product.minPrice;
    final max = product.maxPrice;
    String priceText = '';
    if (min != null && max != null) {
      priceText = min == max ? '₹${min.toStringAsFixed(0)}' : '₹${min.toStringAsFixed(0)} – ₹${max.toStringAsFixed(0)}';
    }

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey.shade100),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.brandName != null)
                      Text(
                        product.brandName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Text(
                        product.name,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (priceText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        priceText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(child: Icon(Icons.electrical_services, size: 40, color: Colors.grey)),
    );
  }
}
