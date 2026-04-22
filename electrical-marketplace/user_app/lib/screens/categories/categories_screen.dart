import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/category.dart';
import '../../providers/category_provider.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (categories) {
          final parents = categories.where((c) => c.isParent).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: parents.length,
            itemBuilder: (ctx, i) => _ParentCategoryTile(category: parents[i]),
          );
        },
      ),
    );
  }
}

class _ParentCategoryTile extends StatelessWidget {
  final Category category;
  const _ParentCategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasChildren = category.children.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.category, color: theme.colorScheme.primary, size: 20),
        ),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: hasChildren ? null : const Icon(Icons.arrow_forward_ios, size: 14),
        onExpansionChanged: hasChildren ? null : (_) {
          context.push('/products?category_id=${category.id}');
        },
        children: category.children.map((child) {
          return ListTile(
            contentPadding: const EdgeInsets.only(left: 56, right: 16),
            title: Text(child.name),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () => context.push('/products?category_id=${child.id}&title=${child.name}'),
          );
        }).toList(),
      ),
    );
  }
}

// Sub-categories screen for deep-link /categories/:id
class SubCategoryScreen extends ConsumerWidget {
  final String categoryId;
  const SubCategoryScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      data: (categories) {
        final parent = categories.cast<Category?>().firstWhere(
              (c) => c?.id == categoryId,
              orElse: () => null,
            );
        if (parent == null) {
          context.push('/products?category_id=$categoryId');
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (parent.children.isEmpty) {
          context.push('/products?category_id=$categoryId');
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return Scaffold(
          appBar: AppBar(title: Text(parent.name)),
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: parent.children.length,
            itemBuilder: (ctx, i) {
              final child = parent.children[i];
              return GestureDetector(
                onTap: () => context.push('/products?category_id=${child.id}&title=${child.name}'),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.electrical_services,
                          size: 32, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        child.name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
