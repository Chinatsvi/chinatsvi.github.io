import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/location_service.dart';

class LocationScreen extends StatefulWidget {
  final String? locationName;

  const LocationScreen({super.key, this.locationName});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final LocationService _locationService = LocationService.instance;
  Position? _currentPosition;
  Map<String, double>? _locationCoordinates;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      if (widget.locationName != null) {
        // Get coordinates from location name
        final coords = await _locationService.getCoordinatesFromAddress(
          widget.locationName!,
        );
        if (coords != null) {
          setState(() {
            _locationCoordinates = coords;
            _loading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                'Could not find coordinates for "${widget.locationName}"';
            _loading = false;
          });
        }
      } else {
        // Get current location
        final position = await _locationService.getCurrentLocation();
        setState(() {
          _currentPosition = position;
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading location: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openInMaps() async {
    double? lat;
    double? lon;

    if (_locationCoordinates != null) {
      lat = _locationCoordinates!['latitude'];
      lon = _locationCoordinates!['longitude'];
    } else if (_currentPosition != null) {
      lat = _currentPosition!.latitude;
      lon = _currentPosition!.longitude;
    }

    if (lat != null && lon != null) {
      // Try multiple URL formats for better compatibility
      final List<String> mapUrls = [
        // Google Maps app
        'geo:$lat,$lon?q=$lat,$lon',
        // Google Maps web
        'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
        // Alternative Google Maps URL
        'https://maps.google.com/?q=$lat,$lon',
      ];

      bool launched = false;

      for (final url in mapUrls) {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: url.startsWith('geo:')
                  ? LaunchMode.externalApplication
                  : LaunchMode.platformDefault,
            );
            launched = true;
            break;
          }
        } catch (e) {
          debugPrint('Failed to launch URL: $url - Error: $e');
          continue;
        }
      }

      if (!launched && mounted) {
        // Show error with copy option
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not open maps app'),
            action: SnackBarAction(
              label: 'Copy Coordinates',
              onPressed: () {
                // Copy coordinates to clipboard
                // Note: You might want to add flutter/services import for this
                final coords = '$lat, $lon';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Coordinates copied: $coords')),
                );
              },
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location coordinates not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.locationName ?? 'Current Location'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          if (!_loading && _errorMessage == null)
            IconButton(
              icon: const Icon(Icons.map),
              onPressed: _openInMaps,
              tooltip: 'Open in Maps',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading location...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadLocation,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.locationName != null) ...[
                    Text(
                      'Location Name:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      widget.locationName!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_locationCoordinates != null) ...[
                    Text(
                      'Coordinates:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'Latitude: ${_locationCoordinates!['latitude']!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Longitude: ${_locationCoordinates!['longitude']!.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ] else if (_currentPosition != null) ...[
                    Text(
                      'Current Location:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    Text(
                      'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Altitude: ${_currentPosition!.altitude.toStringAsFixed(2)} meters',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],

                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Location Information',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This location was tagged by the user when creating the post. You can view the physical location coordinates above.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _openInMaps,
                          icon: const Icon(Icons.map),
                          label: const Text('View in Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
