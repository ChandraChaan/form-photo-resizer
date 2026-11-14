import 'package:flutter/material.dart';

/// Exam-hall paper: off-white sheet, graphite ink, marigold for the action,
/// green when the file fits the form.
class Look {
  const Look._({
    required this.paper,
    required this.sheet,
    required this.ink,
    required this.muted,
    required this.rule,
    required this.marigold,
    required this.ok,
    required this.bad,
  });

  final Color paper, sheet, ink, muted, rule, marigold, ok, bad;

  static const light = Look._(
    paper: Color(0xFFEDEAE3),
    sheet: Color(0xFFFBFAF7),
    ink: Color(0xFF23262B),
    muted: Color(0xFF6E6C66),
    rule: Color(0xFFD6D1C6),
    marigold: Color(0xFFD9822B),
    ok: Color(0xFF2E7D4F),
    bad: Color(0xFFB3402A),
  );

  static const dark = Look._(
    paper: Color(0xFF131416),
    sheet: Color(0xFF1C1D20),
    ink: Color(0xFFE9E6DF),
    muted: Color(0xFFA19E97),
    rule: Color(0xFF34353A),
    marigold: Color(0xFFF0A04B),
    ok: Color(0xFF5CC48A),
    bad: Color(0xFFEE7B62),
  );

  static Look of(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? dark : light;

  static const figures = [FontFeature.tabularFigures()];

  TextStyle label() => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.4,
    color: muted,
  );

  ThemeData theme(Brightness b) {
    final line = UnderlineInputBorder(
      borderSide: BorderSide(color: rule, width: 1.2),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: b,
        primary: ink,
        onPrimary: sheet,
        secondary: marigold,
        onSecondary: ink,
        error: bad,
        onError: Colors.white,
        surface: sheet,
        onSurface: ink,
      ),
      scaffoldBackgroundColor: paper,
      dividerColor: rule,
      inputDecorationTheme: InputDecorationTheme(
        border: line,
        enabledBorder: line,
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: ink, width: 1.8),
        ),
        labelStyle: TextStyle(color: muted),
        floatingLabelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
        isDense: true,
        contentPadding: const EdgeInsets.only(top: 6, bottom: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: marigold,
          foregroundColor: ink,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15.5,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        side: BorderSide(color: rule),
        backgroundColor: sheet,
        selectedColor: ink,
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
