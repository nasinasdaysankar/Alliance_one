import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendor.dart';
import 'category_provider.dart';

final vendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final service = ref.read(productServiceProvider);
  return service.getVendors();
});
