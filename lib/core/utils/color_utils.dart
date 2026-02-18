import 'package:flutter/material.dart';

Color parseHexColor(String? hex, Color fallback) {
  if (hex == null) {
    return fallback;
  }
  final normalized = hex.trim().replaceFirst('#', '');
  if (normalized.length == 3) {
    final expanded = normalized.split('').map((char) => '$char$char').join();
    final value = int.tryParse(expanded, radix: 16);
    if (value != null) {
      return Color(0xFF000000 | value);
    }
  }
  if (normalized.length == 6) {
    final value = int.tryParse(normalized, radix: 16);
    if (value != null) {
      return Color(0xFF000000 | value);
    }
  }
  if (normalized.length == 8) {
    final value = int.tryParse(normalized, radix: 16);
    if (value != null) {
      return Color(value);
    }
  }
  return fallback;
}
