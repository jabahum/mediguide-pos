import 'package:flutter/material.dart';

/// MediGuide's clinical visual palette.
///
/// The palette intentionally uses blue for navigation and informational
/// actions, red only for urgent/outbreak content, and quiet neutral surfaces
/// for dense clinical reading screens.
abstract final class AppColors {
  static const MaterialColor kPrimaryColor =
      MaterialColor(0xFF075FBD, <int, Color>{
        50: Color(0xFFEAF4FF),
        100: Color(0xFFD5E9FF),
        200: Color(0xFFA9D3FF),
        300: Color(0xFF75B7FA),
        400: Color(0xFF3693EA),
        500: Color(0xFF0B72D1),
        600: Color(0xFF075FBD),
        700: Color(0xFF084D96),
        800: Color(0xFF0B427B),
        900: Color(0xFF0D3766),
      });

  static const Color primary = Color(0xFF075FBD);
  static const Color primaryDark = Color(0xFF56A8F5);
  static const Color primaryContainer = Color(0xFFEAF4FF);
  static const Color onPrimaryContainer = Color(0xFF073763);
  static const Color ink = Color(0xFF111827);
  static const Color mutedInk = Color(0xFF667085);
  static const Color canvas = Color(0xFFFCFCFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color softSurface = Color(0xFFF5F7FA);
  static const Color border = Color(0xFFE4E7EC);
  static const Color borderStrong = Color(0xFFD0D5DD);

  static const Color outbreak = Color(0xFFD92D20);
  static const Color outbreakContainer = Color(0xFFFFEBE9);
  static const Color success = Color(0xFF168A59);
  static const Color successContainer = Color(0xFFE8F7F0);
  static const Color warning = Color(0xFFB54708);
  static const Color warningContainer = Color(0xFFFFF4E5);

  // Backwards-compatible names used by older widgets.
  static const Color white = surface;
  static const Color black = ink;
  static const Color transparent = Color(0x00000000);
  static const Color green = success;
  static const Color red = outbreak;
  static const Color gray = Color(0xFF98A2B3);
  static const Color lightGray = mutedInk;
  static const Color colorDivider = border;
  static const Color neutral6 = softSurface;
  static const Color neutral3 = mutedInk;
}
