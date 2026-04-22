class Validators {
  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Enter a valid 10-digit Indian phone number (starts with 6-9)';
    }
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? pincode(String? value) {
    if (value == null || value.isEmpty) return 'Pincode is required';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'Enter a valid 6-digit pincode';
    return null;
  }
}
