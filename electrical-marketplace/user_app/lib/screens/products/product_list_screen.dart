import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../providers/category_provider.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? search;
  final String? title;

  const ProductListScreen({
    super.key,
    this.categoryId,
    this.search,
    this.title,
  });

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  late ProductListParams _params;

  String? _selectedBrandId;
  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _priceFilterActive = false;

  @override
  void initState() {
    super.initState();
    _params = ProductListParams(
      categoryId: widget.categoryId,
      search: widget.search,
    );
    _searchController.text = widget.search ?? '';
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(productListProvider(_params).notifier).fetch();
    }
  }

  void _applySearch(String query) {
    setState(() {
      _params = ProductListParams(
        categoryId: widget.categoryId,
        search: query.isEmpty ? null : query,
        brandId: _selectedBrandId,
        minPrice: _priceFilterActive ? _minPrice : null,
        maxPrice: _priceFilterActive ? _maxPrice : null,
      );
    });
  }

  void _applyFilters({
    required String? brandId,
    required double minPrice,
    required double maxPrice,
    required bool priceActive,
  }) {
    setState(() {
      _selectedBrandId = brandId;
      _minPrice = minPrice;
      _maxPrice = maxPrice;
      _priceFilterActive = priceActive;
      _params = ProductListParams(
        categoryId: widget.categoryId,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        brandId: brandId,
        minPrice: priceActive ? minPrice : null,
        maxPrice: priceActive ? maxPrice : null,
      );
    });
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FilterSheet(
        selectedBrandId: _selectedBrandId,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        priceFilterActive: _priceFilterActive,
        onApply: (brandId, minPrice, maxPrice, priceActive) {
          _applyFilters(
            brandId: brandId,
            minPrice: minPrice,
            maxPrice: maxPrice,
            priceActive: priceActive,
          );
        },
        onClear: () {
          _applyFilters(
            brandId: null,
            minPrice: 0,
            maxPrice: 10000,
            priceActive: false,
          );
        },
      ),
    );
  }

  bool get _hasActiveFilters => _selectedBrandId != null || _priceFilterActive;

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider(_params));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Products'),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: _showFilterSheet,
                tooltip: 'Filter',
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: _applySearch,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _applySearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productListProvider(_params).notifier).refresh(),
        child: state.products.isEmpty && state.isLoading
            ? _buildShimmer()
            : state.products.isEmpty && !state.isLoading
                ? _buildEmpty()
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: state.products.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= state.products.length) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _ProductCard(product: state.products[i]);
                    },
                  ),
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No products found'),
        ],
      ),
    );
  }
}

// ── Filter Bottom Sheet ────────────────────────────────────────────────────

class _FilterSheet extends ConsumerStatefulWidget {
  final String? selectedBrandId;
  final double minPrice;
  final double maxPrice;
  final bool priceFilterActive;
  final void Function(String? brandId, double min, double max, bool priceActive) onApply;
  final VoidCallback onClear;

  const _FilterSheet({
    this.selectedBrandId,
    required this.minPrice,
    required this.maxPrice,
    required this.priceFilterActive,
    required this.onApply,
    required this.onClear,
  });

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  String? _brandId;
  late RangeValues _priceRange;
  late bool _priceActive;

  @override
  void initState() {
    super.initState();
    _brandId = widget.selectedBrandId;
    _priceRange = RangeValues(widget.minPrice, widget.maxPrice);
    _priceActive = widget.priceFilterActive;
  }

  @override
  Widget build(BuildContext context) {
    final brandsAsync = ref.watch(brandsProvider);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Products',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  widget.onClear();
                  Navigator.pop(context);
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Brand filter
          const Text('Brand', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          brandsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Failed to load brands'),
            data: (brands) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String?>(
                value: _brandId,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('All Brands'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Brands'),
                  ),
                  ...brands.map(
                    (b) => DropdownMenuItem<String?>(
                      value: b['id'] as String,
                      child: Text(b['name'] as String),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _brandId = val),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Price range filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Range', style: TextStyle(fontWeight: FontWeight.w600)),
              Switch(
                value: _priceActive,
                onChanged: (v) => setState(() => _priceActive = v),
              ),
            ],
          ),
          if (_priceActive) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${_priceRange.start.toInt()}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '₹${_priceRange.end.toInt()}',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            RangeSlider(
              values: _priceRange,
              min: 0,
              max: 10000,
              divisions: 100,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
          ],
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _brandId,
                  _priceActive ? _priceRange.start : 0,
                  _priceActive ? _priceRange.end : 10000,
                  _priceActive,
                );
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ───────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final min = product.minPrice;
    final max = product.maxPrice;
    String priceText = '';
    if (min != null && max != null) {
      priceText = min == max
          ? '₹${min.toStringAsFixed(0)}'
          : '₹${min.toStringAsFixed(0)} – ₹${max.toStringAsFixed(0)}';
    }

    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: Colors.grey.shade100),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            Padding(
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
                    ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (priceText.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      priceText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Center(
          child: Icon(Icons.electrical_services, size: 40, color: Colors.grey),
        ),
      );
}
