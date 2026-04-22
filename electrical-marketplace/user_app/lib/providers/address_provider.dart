import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address.dart';
import '../services/address_service.dart';

final addressServiceProvider =
    Provider<AddressService>((ref) => AddressService());

class AddressNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  final AddressService _service;

  AddressNotifier(this._service) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final addresses = await _service.getAddresses();
      state = AsyncValue.data(addresses);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> add({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state_,
    required String pincode,
    String? label,
  }) async {
    await _service.addAddress(
      addressLine1: addressLine1,
      addressLine2: addressLine2,
      city: city,
      state: state_,
      pincode: pincode,
      label: label,
    );
    await load();
  }

  Future<void> delete(String id) async {
    await _service.deleteAddress(id);
    await load();
  }

  Future<void> setDefault(String id) async {
    await _service.setDefault(id);
    await load();
  }

  Address? get defaultAddress {
    final list = state.valueOrNull ?? [];
    try {
      return list.firstWhere((a) => a.isDefault);
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }
}

final addressProvider =
    StateNotifierProvider<AddressNotifier, AsyncValue<List<Address>>>((ref) {
  return AddressNotifier(ref.read(addressServiceProvider));
});
