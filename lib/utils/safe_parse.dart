import 'package:flutter/material.dart';

double parseDoubleOrDefault(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim()) ?? fallback;
  return fallback;
}

DateTime parseDateTimeOrDefault(
  dynamic value, {
  DateTime? fallback,
}) {
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

Color parseColorOrFallback(
  String? hex, {
  Color fallback = const Color(0xFF6366F1),
}) {
  if (hex == null || hex.trim().isEmpty) return fallback;
  final normalized = hex.trim().replaceFirst('#', '');
  final raw = normalized.length == 6 ? 'FF$normalized' : normalized;
  final value = int.tryParse(raw, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}
