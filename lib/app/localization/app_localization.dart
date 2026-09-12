import 'package:flutter/material.dart';

class AppLocalization {
  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'follow': 'Follow',
      'message': 'Message',
    },
    'af': {
      'follow': 'Volg',
      'message': 'Boodskap',
    },
    'zu': {
      'follow': 'Landela',
      'message': 'Umlayezo',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}