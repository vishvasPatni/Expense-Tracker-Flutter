String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  const pattern = r'^[^@]+@[^@]+\.[^@]+$';
  if (!RegExp(pattern).hasMatch(v.trim())) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 8) return 'At least 8 characters';
  return null;
}

String? validateRequiredAmount(String? v) {
  if (v == null || v.trim().isEmpty) return 'Amount is required';
  final n = double.tryParse(v.replaceAll(',', ''));
  if (n == null || n <= 0) return 'Enter a positive amount';
  return null;
}

double? parseAmount(String v) {
  final n = double.tryParse(v.replaceAll(',', ''));
  return n;
}

bool isFutureDateTime(DateTime dt) => dt.isAfter(DateTime.now());
