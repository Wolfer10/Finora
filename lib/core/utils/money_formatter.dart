import 'package:intl/intl.dart';

class MoneyFormatter {
  const MoneyFormatter._();

  static String _defaultLocale = 'hu_HU';
  static String _defaultCurrencySymbol = 'Ft';
  static int _defaultDecimalDigits = 0;

  static void configureDefaults({
    required String currencyCode,
    required String currencySymbol,
  }) {
    _defaultLocale = _localeFromCurrencyCode(currencyCode);
    _defaultCurrencySymbol = currencySymbol;
  }

  static String format(
    num amount, {
    String? locale,
    String? currencySymbol,
    int? decimalDigits,
    bool showPlus = false,
  }) {
    final pattern = NumberFormat.currency(
      locale: locale ?? _defaultLocale,
      symbol: currencySymbol ?? _defaultCurrencySymbol,
      decimalDigits: decimalDigits ?? _defaultDecimalDigits,
    );
    final value = pattern.format(amount);
    if (showPlus && amount > 0) {
      return '+$value';
    }
    return value;
  }

  static String _localeFromCurrencyCode(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return 'en_US';
      case 'EUR':
        return 'de_DE';
      case 'GBP':
        return 'en_GB';
      case 'HUF':
      default:
        return 'hu_HU';
    }
  }
}
