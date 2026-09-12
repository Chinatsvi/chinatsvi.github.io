class WeatherModel {
  final double temperature;
  final String description;
  final String farmerTip;
  final DateTime? dateTime; // optional: for hourly/daily forecast
  final double? windSpeed;  // optional
  final int? humidity;       // optional

  WeatherModel({
    required this.temperature,
    required this.description,
    required this.farmerTip,
    this.dateTime,
    this.windSpeed,
    this.humidity,
  });

  /// Factory for current weather JSON
  factory WeatherModel.fromCurrentJson(Map<String, dynamic> json) {
    final temp = (json['main']['temp']?.toDouble() ?? 0.0);
    final desc = json['weather'][0]['description'] ?? 'Unknown';
    final wind = (json['wind']?['speed']?.toDouble() ?? 0.0);
    final hum = json['main']?['humidity'] ?? 0;
    final dt = DateTime.now();

    return WeatherModel(
      temperature: temp,
      description: desc,
      windSpeed: wind,
      humidity: hum,
      dateTime: dt,
      farmerTip: _generateFarmerTip(desc),
    );
  }

  /// Factory for forecast JSON (hourly or daily)
  factory WeatherModel.fromForecastJson(Map<String, dynamic> json) {
    final temp = (json['main']['temp']?.toDouble() ?? 0.0);
    final desc = json['weather'][0]['description'] ?? 'Unknown';
    final wind = (json['wind']?['speed']?.toDouble() ?? 0.0);
    final hum = json['main']?['humidity'] ?? 0;
    final dt = DateTime.tryParse(json['dt_txt'] ?? '');

    return WeatherModel(
      temperature: temp,
      description: desc,
      windSpeed: wind,
      humidity: hum,
      dateTime: dt,
      farmerTip: _generateFarmerTip(desc),
    );
  }

  /// Farmer advice generator
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
    return '💡 General tip: Monitor soil moisture, adjust feeding schedules, and plan field work wisely.';
  }
}
