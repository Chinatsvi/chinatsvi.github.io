import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class WeatherService {
  static WeatherService? _instance;
  static WeatherService get instance => _instance ??= WeatherService._();

  WeatherService._();

  /// Fetch current weather summary as string
  Future<String?> fetchWeather(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final temp = data['main']['temp'];
      final description = data['weather'][0]['description'];
      final humidity = data['main']['humidity'];
      final windSpeed = data['wind']['speed'];
      final pressure = data['main']['pressure'];

      return '$description, $temp°C, Humidity: $humidity%, Wind: ${windSpeed}m/s, Pressure: ${pressure}hPa';
    } catch (_) {
      return null;
    }
  }

  /// Fetch detailed current weather as structured map
  Future<Map<String, dynamic>?> getDetailedWeather(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final url =
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);

      return {
        'temperature': data['main']['temp'],
        'feelsLike': data['main']['feels_like'],
        'description': data['weather'][0]['description'],
        'humidity': data['main']['humidity'],
        'windSpeed': data['wind']['speed'],
        'windDirection': data['wind']['deg'],
        'pressure': data['main']['pressure'],
        'visibility': data['visibility'],
        'clouds': data['clouds']['all'],
        'sunrise': DateTime.fromMillisecondsSinceEpoch(data['sys']['sunrise'] * 1000),
        'sunset': DateTime.fromMillisecondsSinceEpoch(data['sys']['sunset'] * 1000),
      };
    } catch (e) {
      debugPrint('Error fetching detailed weather: $e');
      return null;
    }
  }

  /// Fetch 5-day forecast (3-hour intervals)
  Future<List<Map<String, dynamic>>?> getForecast(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHER_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) return null;

    final url =
        'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final data = json.decode(response.body);
      final List<Map<String, dynamic>> forecast = [];

      for (var item in data['list']) {
        forecast.add({
          'dateTime': DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000),
          'temperature': item['main']['temp'],
          'description': item['weather'][0]['description'],
          'humidity': item['main']['humidity'],
          'windSpeed': item['wind']['speed'],
          'precipitation': (item['pop'] * 100).round(), // Probability of precipitation
          'farmerTip': _generateFarmerTip(item['weather'][0]['description']),
        });
      }

      return forecast;
    } catch (e) {
      debugPrint('Error fetching forecast: $e');
      return null;
    }
  }

  /// Generate structured agricultural advice for current weather
  Future<Map<String, dynamic>?> getAgriculturalAdvice(double lat, double lon) async {
    final weather = await getDetailedWeather(lat, lon);
    if (weather == null) return null;

    final temp = weather['temperature'] as double;
    final humidity = weather['humidity'] as int;
    final windSpeed = weather['windSpeed'] as double;
    final description = weather['description'] as String;

    final tips = <String>[];
    String severity = 'Normal';

    // Temperature-based advice
    if (temp > 30) {
      tips.add('High temperature: Ensure irrigation and shade for sensitive crops.');
      severity = 'Caution';
    } else if (temp < 10) {
      tips.add('Low temperature: Protect seedlings and delay planting if possible.');
      severity = 'Caution';
    } else if (temp >= 20 && temp <= 28) {
      tips.add('Optimal temperature: Good conditions for planting and growth.');
    }

    // Humidity-based advice
    if (humidity > 80) {
      tips.add('High humidity: Risk of fungal diseases. Improve ventilation and monitor crops.');
      severity = 'Caution';
    } else if (humidity < 40) {
      tips.add('Low humidity: Increase irrigation and use mulching to retain soil moisture.');
    }

    // Wind-based advice
    if (windSpeed > 5) {
      tips.add('Strong winds: Secure young plants and consider windbreaks.');
      severity = 'Urgent';
    }

    // Weather condition advice
    if (description.contains('rain')) {
      tips.add('Rain expected: Delay pesticide spraying, but soil moisture will improve.');
    } else if (description.contains('clear')) {
      tips.add('Clear skies: Good for field operations and spraying.');
    } else if (description.contains('cloud')) {
      tips.add('Cloudy: Reduced evaporation, adjust irrigation accordingly.');
    }

    return {
      'summary': 'Agricultural advice based on current weather',
      'severity': severity,
      'tips': tips,
    };
  }

  /// Check if today is good for pesticide spraying
  Future<bool> isGoodForSpraying(double lat, double lon) async {
    final weather = await getDetailedWeather(lat, lon);
    if (weather == null) return false;

    final windSpeed = weather['windSpeed'] as double;
    final humidity = weather['humidity'] as int;
    final description = weather['description'] as String;

    // Safe conditions: wind < 3 m/s, humidity 40–80%, no rain/storm
    if (windSpeed > 3) return false;
    if (humidity < 40 || humidity > 80) return false;
    if (description.contains('rain') || description.contains('storm')) return false;

    return true;
  }

  /// Irrigation recommendation based on current weather
  Future<String?> getIrrigationRecommendation(double lat, double lon) async {
    final weather = await getDetailedWeather(lat, lon);
    if (weather == null) return null;

    final temp = weather['temperature'] as double;
    final humidity = weather['humidity'] as int;
    final description = weather['description'] as String;

    if (description.contains('rain')) {
      return 'Rain expected. Reduce or skip irrigation today.';
    } else if (temp > 28 && humidity < 50) {
      return 'Hot and dry conditions. Increase irrigation frequency.';
    } else if (humidity > 80) {
      return 'High humidity. Reduce irrigation to prevent fungal issues.';
    } else {
      return 'Normal conditions. Regular irrigation schedule recommended.';
    }
  }

  /// Farmer advice helper
  static String _generateFarmerTip(String description) {
    final c = description.toLowerCase();
    if (c.contains('rain')) {
      return '💡 Rain expected: Prepare drainage, store feed safely, and avoid overwatering crops.';
    }
    if (c.contains('cloud')) {
      return '💡 Cloudy skies: Watch for crop diseases, ensure livestock shelter is ventilated.';
    }
    if (c.contains('sun') || c.contains('clear')) {
      return '💡 Sunny weather: Irrigate early morning/evening, provide shade and water for animals.';
    }
    if (c.contains('storm')) {
      return '💡 Storm warning: Secure structures, move animals to shelter, protect equipment.';
    }
    if (c.contains('snow')) {
      return '💡 Cold conditions: Keep livestock warm, protect seedlings, ensure water doesn’t freeze.';
    }
    return '💡 Monitor soil moisture, adjust feeding schedules, and plan field work wisely.';
  }
}
