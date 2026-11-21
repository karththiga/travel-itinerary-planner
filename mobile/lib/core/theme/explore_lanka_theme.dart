import 'package:flutter/material.dart';

const exploreLankaName = 'ExploreLanka';
const exploreOrange = Color(0xFFFF6B35);
const exploreCream = Color(0xFFFFF5EB);
const exploreTeal = Color(0xFF176862);

ThemeData buildExploreLankaTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: exploreOrange).copyWith(
    primary: exploreOrange,
    onPrimary: const Color(0xFF301407),
    secondary: exploreTeal,
    secondaryContainer: const Color(0xFFD8EEEA),
    onSecondaryContainer: const Color(0xFF104741),
    surface: Colors.white,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: exploreCream,
    appBarTheme: const AppBarTheme(
      backgroundColor: exploreCream,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Color(0xFFFFE4D7),
      height: 68,
    ),
  );
}

ThemeData buildTripPlanningTheme() {
  const background = Color(0xFF101010);
  final colors =
      ColorScheme.fromSeed(
        seedColor: exploreOrange,
        brightness: Brightness.dark,
      ).copyWith(
        primary: exploreOrange,
        onPrimary: const Color(0xFF301407),
        surface: background,
        onSurface: const Color(0xFFECECEC),
        onSurfaceVariant: const Color(0xFFCCCCCC),
      );
  return ThemeData(
    colorScheme: colors,
    scaffoldBackgroundColor: background,
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
    ),
  );
}
