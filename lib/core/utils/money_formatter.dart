import 'package:intl/intl.dart';

class MoneyFormatter {
  const MoneyFormatter._();

  static String format(
    num amount, {
    String locale = 'hu_HU',
    String currencySymbol = 'Ft',
    int decimalDigits = 0,
    bool showPlus = false,
  }) {
    final pattern = NumberFormat.currency(
      locale: locale,
      symbol: currencySymbol,
      decimalDigits: decimalDigits,
    );
    final value = pattern.format(amount);
    if (showPlus && amount > 0) {
      return '+$value';
    }
    return value;
  }
}
