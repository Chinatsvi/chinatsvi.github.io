import 'package:flutter/material.dart';

class LanguageService {
  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('af'),
    Locale('zu'),
  ];

  static Locale getLocaleFromCode(String code) {
    return supportedLocales.firstWhere((l) => l.languageCode == code, orElse: () => const Locale('en'));
  }
}