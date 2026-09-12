import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  final String weatherInfo;
  const WeatherCard({super.key, required this.weatherInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(weatherInfo, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
