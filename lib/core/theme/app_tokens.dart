import 'package:flutter/material.dart';

class AppColors {
  static const Color seed = Color(0xFF0F766E);
  static const Color primary = Color(0xFF0F766E);
  static const Color secondary = Color(0xFF155E75);

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  static const Color textPrimaryDark = Color(0xFFF9FAFB);
  static const Color textSecondaryDark = Color(0xFFD1D5DB);

  static const Color borderLight = Color(0xFFD1D5DB);
  static const Color borderDark = Color(0xFF374151);

  static const Color income = Color(0xFF1D7A45);
  static const Color expense = Color(0xFFB42318);
  static const Color transfer = Color(0xFF5B7083);

  static const Color success = Color(0xFF1D7A45);
  static const Color warning = Color(0xFFB45309);
  static const Color error = Color(0xFFB42318);

  static const Color surfaceAccent = Color(0xFFD9E8E6);
  static const Color backgroundTop = Color(0xFFF4F8F7);
  static const Color backgroundBottom = Color(0xFFE7EFEC);
  static const Color darkBackgroundTop = Color(0xFF0F1720);
  static const Color darkBackgroundBottom = Color(0xFF111827);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppSizes {
  static const double minTapTarget = 44;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double iconLg = 24;
}

class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
}

class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);

  static const Curve standard = Curves.easeInOutCubic;
  static const Curve emphasized = Curves.easeOutCubic;
}

class AppElevation {
  static const double level0 = 0;
  static const double level1 = 1;
  static const double level2 = 3;
}

class AppTypography {
  static const String fontFamily = 'Georgia';

  static const TextStyle headlineLarge = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}
