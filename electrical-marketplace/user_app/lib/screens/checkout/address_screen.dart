import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/toast_helper.dart';

class AddressScreen extends ConsumerWidget {
  /// If true, tapping an address returns it instead of managing it.
  final bool selectMode;
  const AddressScreen({super.key, this.selectMode = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressAsync = ref.watch(addressProvider);
    return Scaffold(
      appBar: AppBar(title: Text(selectMode ? 'Select Address' : 'My Addresses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Address'),
      ),
      body: addressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No saved addresses'),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: addresses.length,
            itemBuilder: (ctx, i) => _AddressTile(
              address: addresses[i],
              selectMode: selectMode,
            ),
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AddAddressSheet(),
    );
  }
}

class _AddressTile extends ConsumerWidget {
  final Address address;
  final bool selectMode;
  const _AddressTile({required this.address, required this.selectMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: address.isDefault
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(
          address.label ?? '${address.city}, ${address.state}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(address.fullAddress, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: selectMode
            ? const Icon(Icons.arrow_forward_ios, size: 14)
            : PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'default') {
                    await ref.read(addressProvider.notifier).setDefault(address.id);
                    ToastHelper.success('Default address updated');
                  } else if (v == 'delete') {
                    await ref.read(addressProvider.notifier).delete(address.id);
                    ToastHelper.success('Address removed');
                  }
                },
                itemBuilder: (_) => [
                  if (!address.isDefault)
                    const PopupMenuItem(value: 'default', child: Text('Set as default')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
              ),
        onTap: selectMode ? () => Navigator.of(context).pop(address) : null,
      ),
    );
  }
}

class _AddAddressSheet extends ConsumerStatefulWidget {
  const _AddAddressSheet();

  @override
  ConsumerState<_AddAddressSheet> createState() => _AddAddressSheetState();
}

class _AddAddressSheetState extends ConsumerState<_AddAddressSheet> {
  final _formKey = GlobalKey<FormState>();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  final _label = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(addressProvider.notifier).add(
            addressLine1: _line1.text.trim(),
            addressLine2: _line2.text.trim(),
            city: _city.text.trim(),
            state_: _state.text.trim(),
            pincode: _pincode.text.trim(),
            label: _label.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
      ToastHelper.success('Address saved');
    } catch (e) {
      ToastHelper.error(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Add New Address', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _field(_label, 'Label (e.g. Home, Office)', optional: true),
              _field(_line1, 'Address Line 1', validator: (v) => Validators.required(v, 'Address')),
              _field(_line2, 'Address Line 2 (optional)', optional: true),
              _field(_city, 'City', validator: (v) => Validators.required(v, 'City')),
              _field(_state, 'State', validator: (v) => Validators.required(v, 'State')),
              _field(_pincode, 'Pincode', keyboardType: TextInputType.number, validator: Validators.pincode),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool optional = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: optional ? null : validator,
      ),
    );
  }
}
