import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';

import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'five_day_screen.dart';

import 'package:intl/intl.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool isLoading = true;

  List<Map<String, dynamic>> dailyForecast = [];

  List<Map<String, dynamic>> hourlyForecast = [];

  Map<String, dynamic>? currentWeather;

  String errorMessage = '';

  final Map<String, List<String>> farmingAdvice = {
    'rain': [
      'Avoid spraying pesticides; rain can wash them away.',

      'Check drainage in fields to prevent waterlogging.',

      'Keep harvested crops dry and covered.',
    ],

    'sun': [
      'Irrigate crops early morning or late evening.',

      'Apply mulch to retain soil moisture.',

      'Protect young seedlings from direct sun.',
    ],

    'cloud': [
      'Good time for sowing seeds; cooler weather helps germination.',

      'Monitor humidity-sensitive crops for fungal growth.',
    ],

    'storm': [
      'Secure farm structures and livestock.',

      'Harvest crops that could get damaged by wind.',

      'Avoid fieldwork during storms.',
    ],

    'snow': [
      'Cover sensitive crops.',

      'Protect irrigation systems from freezing.',
    ],

    'clear': [
      'Ideal for harvesting and fieldwork.',

      'Check irrigation schedules; no rain expected.',

      'Monitor pests; dry conditions may increase their activity.',
    ],
  };

  @override
  void initState() {
    super.initState();

    fetchWeather();
  }

  Future<void> fetchWeather() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _setWeatherError('Turn on location services and try again.');
        return;
      }

      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setWeatherError(
          permission == LocationPermission.deniedForever
              ? 'Location permission is blocked. Allow it in app settings and try again.'
              : 'Location permission is needed to load local weather.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );

      final lat = position.latitude;

      final lon = position.longitude;

      final apiKey = dotenv.env['OPENWEATHER_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          errorMessage = 'API key missing in .env';

          isLoading = false;
        });

        return;
      }

      // Current weather

      final currentUrl =
          'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

      final currentResponse = await http.get(Uri.parse(currentUrl));
      if (currentResponse.statusCode != 200) {
        _setWeatherError(_weatherApiError(currentResponse));
        return;
      }
      final currentData =
          json.decode(currentResponse.body) as Map<String, dynamic>;

      final currentTemp = currentData['main']['temp'].round();

      final currentHumidity = currentData['main']['humidity'];

      final currentWind = currentData['wind']['speed'];

      final currentCondition = currentData['weather'][0]['main'];

      final sunrise = DateTime.fromMillisecondsSinceEpoch(
        currentData['sys']['sunrise'] * 1000,
      );

      final sunset = DateTime.fromMillisecondsSinceEpoch(
        currentData['sys']['sunset'] * 1000,
      );

      final sunriseTime = DateFormat('HH:mm').format(sunrise);

      final sunsetTime = DateFormat('HH:mm').format(sunset);

      // Forecast

      final forecastUrl =
          'https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

      final forecastResponse = await http.get(Uri.parse(forecastUrl));
      if (forecastResponse.statusCode != 200) {
        _setWeatherError(_weatherApiError(forecastResponse));
        return;
      }
      final forecastData =
          json.decode(forecastResponse.body) as Map<String, dynamic>;

      final List list = forecastData['list'];

      // Hourly forecast (next 24h ~8 entries)
      hourlyForecast = list.take(8).map((entry) {
        final dt = DateTime.parse(entry['dt_txt']);

        // Check for rain data
        var rainAmount = 0.0;
        final rain = entry['rain'];
        if (rain is Map && rain['3h'] is num) {
          rainAmount = (rain['3h'] as num).toDouble();
        } else if (rain is num) {
          rainAmount = rain.toDouble();
        }

        return {
          'time': DateFormat('HH:mm').format(dt),
          'temp': entry['main']['temp'].round(),
          'condition': entry['weather'][0]['main'],
          'humidity': entry['main']['humidity'],
          'windSpeed': entry['wind']['speed'],
          'rain': rainAmount,
        };
      }).toList();

      // Daily forecast

      final Map<String, Map<String, dynamic>> grouped = {};

      for (var entry in list) {
        final date = entry['dt_txt'].split(' ')[0];

        final temp = entry['main']['temp'];

        final weather = entry['weather'][0]['main'];

        final rain = entry['pop'];

        final wind = entry['wind']['speed'];

        if (!grouped.containsKey(date)) {
          grouped[date] = {
            'date': date,

            'temps': [temp],

            'weather': weather,

            'rain': rain,

            'wind': [wind],
          };
        } else {
          grouped[date]!['temps'].add(temp);

          grouped[date]!['wind'].add(wind);
        }
      }

      final forecast = grouped.values.take(5).map((day) {
        final temps = day['temps'] as List;

        final winds = day['wind'] as List;

        final high = temps.reduce((a, b) => a > b ? a : b).round();

        final low = temps.reduce((a, b) => a < b ? a : b).round();

        final avgWind = (winds.reduce((a, b) => a + b) / winds.length)
            .toStringAsFixed(1);

        return {
          'date': day['date'],

          'weather': day['weather'],

          'high': high,

          'low': low,

          'rain': '${(day['rain'] * 100).round()}%',

          'wind': '$avgWind m/s',
        };
      }).toList();

      setState(() {
        currentWeather = {
          'temp': currentTemp,

          'humidity': currentHumidity,

          'wind': currentWind,

          'condition': currentCondition,

          'sunrise': sunriseTime,

          'sunset': sunsetTime,
        };

        dailyForecast = forecast;

        isLoading = false;
      });
    } on LocationServiceDisabledException {
      _setWeatherError('Turn on location services and try again.');
    } on PermissionDeniedException {
      _setWeatherError('Location permission is needed to load local weather.');
    } on TimeoutException {
      _setWeatherError(
        'Weather request timed out. Check your connection and retry.',
      );
    } catch (e) {
      debugPrint('Weather load failed: $e');
      _setWeatherError(
        'Failed to load weather data. Check your connection and retry.',
      );
    }
  }

  void _setWeatherError(String message) {
    if (!mounted) return;
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
  }

  String _weatherApiError(http.Response response) {
    try {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) {
        return 'Weather service error: $message';
      }
    } catch (_) {
      // Use the status code when the service response is not JSON.
    }
    return 'Weather service unavailable (${response.statusCode}). Try again later.';
  }

  Widget _getWeatherIcon(String condition, {double size = 32}) {
    final c = condition.toLowerCase();

    // Direct emoji icons for immediate display
    if (c.contains('rain') || c.contains('drizzle')) {
      return Text('🌧️', style: TextStyle(fontSize: size));
    } else if (c.contains('cloud')) {
      if (c.contains('few')) {
        return Text('⛅', style: TextStyle(fontSize: size));
      } else if (c.contains('scattered') || c.contains('broken')) {
        return Text('☁️', style: TextStyle(fontSize: size));
      } else {
        return Text('☁️', style: TextStyle(fontSize: size));
      }
    } else if (c.contains('sun') || c.contains('clear')) {
      return Text('☀️', style: TextStyle(fontSize: size));
    } else if (c.contains('storm') || c.contains('thunder')) {
      return Text('⛈️', style: TextStyle(fontSize: size));
    } else if (c.contains('snow')) {
      return Text('❄️', style: TextStyle(fontSize: size));
    } else if (c.contains('mist') || c.contains('fog') || c.contains('haze')) {
      return Text('🌫️', style: TextStyle(fontSize: size));
    } else {
      return Text('🌤️', style: TextStyle(fontSize: size)); // Default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast & Advice'),

        backgroundColor: Colors.green.shade700,
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(errorMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          errorMessage = '';
                          isLoading = true;
                        });
                        fetchWeather();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  if (currentWeather != null)
                    Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),

                      child: ListTile(
                        leading: _getWeatherIcon(
                          currentWeather!['condition'],
                          size: 40,
                        ),

                        title: const Text('Current Conditions'),

                        subtitle: Text(
                          '${currentWeather!['temp']}°C • ${currentWeather!['condition']}\n'
                          'Humidity: ${currentWeather!['humidity']}% • Wind: ${currentWeather!['wind']} m/s\n'
                          'Sunrise: ${currentWeather!['sunrise']} • Sunset: ${currentWeather!['sunset']}',

                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  const Text(
                    'Next 24h Forecast (3h intervals)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    height: 180,

                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,

                      itemCount: hourlyForecast.length,

                      itemBuilder: (context, index) {
                        final hour = hourlyForecast[index];

                        return Card(
                          margin: const EdgeInsets.all(8),
                          elevation: 2,
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Column(
                                  children: [
                                    Text(
                                      hour['time'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${hour['temp']}°C',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                _getWeatherIcon(hour['condition'], size: 24),
                                Column(
                                  children: [
                                    // Rain display
                                    if (hour['rain'] > 0) ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.water_drop,
                                            size: 12,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${hour['rain'].toStringAsFixed(1)}mm',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ] else ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            size: 12,
                                            color: Colors.grey[300],
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '0mm',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // Wind speed display
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.air,
                                          size: 12,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${hour['windSpeed'].toStringAsFixed(1)} m/s',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,

                          MaterialPageRoute(
                            builder: (context) =>
                                FiveDayScreen(forecast: dailyForecast),
                          ),
                        );
                      },

                      child: const Text('View 5-Day Forecast'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
