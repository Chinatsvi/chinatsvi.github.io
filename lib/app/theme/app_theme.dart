import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.white, // Professional white background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      bodyMedium: TextStyle(fontSize: 16),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Colors.brown),
  );
}