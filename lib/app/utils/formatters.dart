import 'package:shared_preferences/shared_preferences.dart';

class Formatter {
  // Configurable currency symbol used across the app. Default: 'R' (ZAR)
  static String currencySymbol = 'R';
  static const _prefKey = 'currency_symbol';

  static const Map<String, String> _currencyCodeToSymbol = {
    'ZAR': 'R',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'KES': 'KSh',
    'NGN': '₦',
    'GHS': 'GH₵',
    'TZS': 'TSh',
    'UGX': 'USh',
    'BWP': 'P',
    'R': 'R',
    '\$': '\$',
    '€': '€',
    '£': '£',
  };

  /// Initialize formatter by loading persisted currency symbol (if any).
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved != null && saved.isNotEmpty) currencySymbol = saved;
    } catch (e) {
      // ignore and keep default
    }
  }

  /// Set currency symbol and persist it for future app launches.
  static Future<void> setCurrencySymbol(String symbol) async {
    currencySymbol = symbol;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, symbol);
    } catch (e) {
      // ignore persistence errors
    }
  }

  static String formatPhone(String raw) {
    return raw
        .replaceAll(RegExp(r'\D'), '')
        .replaceFirstMapped(
          RegExp(r'^(\d{3})(\d{3})(\d+)'),
          (m) => '${m[1]}-${m[2]}-${m[3]}',
        );
  }

  // Formats a numeric value into a currency string using the configured symbol.
  static String normalizeCurrencyCode(String? value) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return 'ZAR';

    final cleaned = trimmed.toUpperCase();
    switch (cleaned) {
      case 'R':
      case 'ZAR':
        return 'ZAR';
      case '\$':
      case 'USD':
        return 'USD';
      case '€':
      case 'EUR':
        return 'EUR';
      case '£':
      case 'GBP':
        return 'GBP';
      case 'KSH':
      case 'KSHI':
      case 'KES':
        return 'KES';
      case 'NGN':
        return 'NGN';
      case 'GHS':
        return 'GHS';
      case 'TZS':
        return 'TZS';
      case 'UGX':
        return 'UGX';
      case 'BWP':
        return 'BWP';
      default:
        return cleaned;
    }
  }

  static String resolveCurrencySymbol(String? value) {
    final normalized = normalizeCurrencyCode(value);
    return _currencyCodeToSymbol[normalized] ?? normalized;
  }

  static String formatCurrency(
    double value, {
    String? symbol,
    bool includeSymbol = true,
    int decimalPlaces = 2,
  }) {
    final resolvedSymbol = includeSymbol
        ? resolveCurrencySymbol(symbol ?? currencySymbol)
        : '';
    return '$resolvedSymbol${value.toStringAsFixed(decimalPlaces)}';
  }

  static bool _parseNegotiableValue(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  static String formatMarketplacePrice(
    double value, {
    dynamic negotiable,
    String? symbol,
    bool includeSymbol = true,
    int decimalPlaces = 2,
  }) {
    if (_parseNegotiableValue(negotiable)) {
      return 'Negotiable';
    }

    return formatCurrency(
      value,
      symbol: symbol,
      includeSymbol: includeSymbol,
      decimalPlaces: decimalPlaces,
    );
  }

  // Parses user-entered currency input into a double.
  // Accepts values like 'R1500', 'R 1,500.00', '$1500', '1500.00'
  static double? parseCurrencyInput(String input) {
    final cleaned = input
        .replaceAll(',', '') // remove thousands separators
        .replaceAll(RegExp(r'[^0-9\.\-]'), '') // strip currency symbols/spaces
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Format date to readable string
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Get time ago string from date
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        if (diff.inMinutes < 1) {
          return 'Just now';
        }
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else if (diff.inDays < 30) {
      final weeks = (diff.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Formats farmer location data for UI display.
  ///
  /// - Returns an empty string for null input.
  /// - Returns the string as-is if it's already a clean String.
  /// - If it's a Map, extracts only non-empty values from village, district,
  ///   province, country (in that order) and joins them with ', '.
  /// - Never includes updatedAt, gps, landmark, or any raw Timestamp object.
  /// - Never calls .toString() on the raw map.
  static String formatLocation(dynamic location) {
    if (location == null) return '';

    if (location is String) {
      final trimmed = location.trim();
      if (trimmed.isEmpty) return '';

      // Clean up legacy raw Map strings if stored as a string
      if (trimmed.startsWith('{') &&
          trimmed.endsWith('}') &&
          (trimmed.contains(':') || trimmed.contains('Timestamp('))) {
        final Map<String, String> extracted = {};
        final reg = RegExp(r'(\w+):\s*([^,}]+|\w+\([^)]+\))?');
        for (final match in reg.allMatches(trimmed)) {
          final key = match.group(1);
          final val = match.group(2)?.trim() ?? '';
          if (key != null && val.isNotEmpty && !val.startsWith('Timestamp(')) {
            extracted[key] = val;
          }
        }
        if (extracted.isNotEmpty) {
          final parts = <String>[];
          for (final key in ['village', 'district', 'province', 'country']) {
            final val = extracted[key];
            if (val != null && val.isNotEmpty) {
              parts.add(val);
            }
          }
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
        return '';
      }

      return trimmed;
    }

    if (location is Map) {
      final parts = <String>[];
      for (final key in ['village', 'district', 'province', 'country']) {
        final val = location[key];
        if (val != null) {
          final s = val.toString().trim();
          if (s.isNotEmpty && !s.startsWith('Timestamp(')) {
            parts.add(s);
          }
        }
      }
      return parts.join(', ');
    }

    return '';
  }
}

