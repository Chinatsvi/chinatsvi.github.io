import 'package:flutter/material.dart';

class FiveDayScreen extends StatelessWidget {
  final List<Map<String, dynamic>> forecast;
  const FiveDayScreen({super.key, required this.forecast});

  String _getWeatherEmoji(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain')) return '🌧️';
    if (c.contains('cloud')) return '☁️';
    if (c.contains('sun')) return '☀️';
    if (c.contains('clear')) return '🌤️';
    if (c.contains('storm')) return '⛈️';
    if (c.contains('snow')) return '❄️';
    return '🌦️';
  }

  String _getFarmerTip(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain')) {
      return '💡 Rain expected: Prepare drainage, store animal feed safely, and avoid overwatering crops.';
    }
    if (c.contains('cloud')) {
      return '💡 Cloudy skies: Monitor crop diseases, ensure livestock shelter is ventilated.';
    }
    if (c.contains('sun') || c.contains('clear')) {
      return '💡 Sunny weather: Irrigate crops early morning/evening, provide shade and water for animals.';
    }
    if (c.contains('storm')) {
      return '💡 Storm warning: Secure farm structures, move animals to safe shelter, and protect equipment.';
    }
    if (c.contains('snow')) {
      return '💡 Cold conditions: Keep livestock warm, ensure water supply doesn’t freeze, and protect seedlings.';
    }
    return '💡 General tip: Monitor soil moisture, adjust feeding schedules, and plan field work wisely.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('5-Day Forecast'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        itemCount: forecast.length,
        itemBuilder: (context, index) {
          final day = forecast[index];
          return Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: Text(
                      _getWeatherEmoji(day['weather']),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      day['date'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'High: ${day['high']}°C • Low: ${day['low']}°C\n'
                      'Rain: ${day['rain']} • Wind: ${day['wind']}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFarmerTip(day['weather']),
                    style: const TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}