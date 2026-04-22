import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar + name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (user?.name?.isNotEmpty == true ? user!.name![0] : user?.phone[0] ?? 'U').toUpperCase(),
                    style: TextStyle(fontSize: 32, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.name ?? 'User', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text('+91 ${user?.phone ?? ''}', style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _tile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            onTap: () => context.push('/profile/edit'),
          ),
          _tile(
            icon: Icons.location_on_outlined,
            title: 'Saved Addresses',
            onTap: () => context.push('/addresses'),
          ),
          _tile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            onTap: () => context.go('/orders'),
          ),
          const Divider(height: 32),
          _tile(
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('Logout', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}
