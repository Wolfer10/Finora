class AppSettings {
  const AppSettings({
    required this.currencyCode,
    required this.currencySymbol,
    required this.updatedAt,
  });

  final String currencyCode;
  final String currencySymbol;
  final DateTime updatedAt;

  AppSettings copyWith({
    String? currencyCode,
    String? currencySymbol,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
