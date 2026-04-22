import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;

import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/categories/categories_screen.dart';
import 'screens/products/product_list_screen.dart';
import 'screens/products/product_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/checkout/address_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/vendors/vendor_detail_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: _AuthChangeNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      if (authState.isLoading) return null;
      final isLoggedIn = authState.valueOrNull != null;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/otp' ||
          state.matchedLocation == '/splash';
      if (!isLoggedIn && !onAuthPage) return '/login';
      if (isLoggedIn &&
          (state.matchedLocation == '/login' || state.matchedLocation == '/otp')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final phone = extra['phone'] as String? ?? '';
          final devOtp = extra['devOtp'] as String?;
          return OtpScreen(phone: phone, devOtp: devOtp);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => _AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
          GoRoute(
            path: '/categories/:id',
            builder: (_, state) =>
                SubCategoryScreen(categoryId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/products',
            builder: (_, state) {
              final catId = state.uri.queryParameters['category_id'];
              final search = state.uri.queryParameters['search'];
              final title = state.uri.queryParameters['title'];
              return ProductListScreen(categoryId: catId, search: search, title: title);
            },
          ),
          GoRoute(
            path: '/products/:id',
            builder: (_, state) =>
                ProductDetailScreen(productId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(
            path: '/addresses',
            builder: (_, state) {
              final select = state.uri.queryParameters['select'] == 'true';
              return AddressScreen(selectMode: select);
            },
          ),
          GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
          GoRoute(
            path: '/orders/:id',
            builder: (_, state) =>
                OrderDetailScreen(orderId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/vendors/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>? ?? {};
              final shopName = extra['shop_name'] as String? ?? 'Shop Details';
              return VendorDetailScreen(vendorId: id, shopName: shopName);
            },
          ),
        ],
      ),
      // These routes use the root navigator (no bottom nav bar / full-screen overlay)
      GoRoute(
        path: '/checkout',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
});

// Notifier that triggers GoRouter refresh when auth state changes
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ElectroMart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B5E20),
          brightness: Brightness.light,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
      ),
      routerConfig: router,
    );
  }
}

// Shell with bottom navigation bar
class _AppShell extends ConsumerWidget {
  final Widget child;
  final String location;
  const _AppShell({required this.child, required this.location});

  int _selectedIndex(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/categories')) return 1;
    if (loc.startsWith('/cart')) return 2;
    if (loc.startsWith('/orders')) return 3;
    if (loc.startsWith('/profile')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx = _selectedIndex(location);
    final cartCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/home');
            case 1:
              context.go('/categories');
            case 2:
              context.go('/cart');
            case 3:
              context.go('/orders');
            case 4:
              context.go('/profile');
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text(
                '$cartCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            selectedIcon: badges.Badge(
              showBadge: cartCount > 0,
              badgeContent: Text(
                '$cartCount',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
