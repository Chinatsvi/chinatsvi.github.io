import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

class SoilSensorScreen extends StatefulWidget {
  const SoilSensorScreen({super.key});

  @override
  State<SoilSensorScreen> createState() => _SoilSensorScreenState();
}

class _SoilSensorScreenState extends State<SoilSensorScreen> {
  Map<String, dynamic>? sensorData;
  String recommendation = '';
  bool isLoading = false;
  String errorMessage = '';
  String bluetoothStatus = '🔄 Scanning...';
  int? signalStrength;
  BluetoothDevice? lastConnectedDevice;

  @override
  void initState() {
    super.initState();
  }

  /// ✅ REQUEST REQUIRED PERMISSIONS
  Future<bool> requestSoilSensorPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((s) => s.isGranted);
  }

  /// READ SENSOR DATA
  Future<void> fetchSensorData() async {
    final allowed = await requestSoilSensorPermissions();
    if (!allowed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bluetooth & Location permission required to connect soil sensor',
          ),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      bluetoothStatus = '🔄 Scanning...';
      signalStrength = null;
    });

    try {
      // Get GPS position
      final position = await Geolocator.getCurrentPosition();
      final lat = position.latitude;
      final lon = position.longitude;

      // Wi-Fi attempt with timeout
      try {
        final response = await http
            .get(Uri.parse('http://192.168.4.1/data'))
            .timeout(const Duration(seconds: 5));
        final data = json.decode(response.body);
        setState(() => bluetoothStatus = '📡 Using Wi-Fi');
        await handleSensorData(data, lat, lon);
        return;
      } catch (_) {
        // Wi-Fi failed, continue to Bluetooth
      }

      // Bluetooth scanning
      setState(() => bluetoothStatus = '🔄 Scanning Bluetooth...');
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      final scanResults = await FlutterBluePlus.scanResults.first;

      ScanResult? target;
      try {
        target = scanResults.firstWhere(
          (r) => r.device.name.toLowerCase().contains('soil'),
        );
      } catch (_) {
        target = null;
      }

      await FlutterBluePlus.stopScan();

      if (target == null) {
        setState(() {
          errorMessage = '❌ No Device Found.\nCheck sensor power or Bluetooth.';
          bluetoothStatus = 'No Device Found';
          isLoading = false;
        });
        return;
      }

      signalStrength = target.rssi;
      final device = target.device;
      final deviceName = device.name.isNotEmpty ? device.name : "Unknown";

      setState(() {
        bluetoothStatus = '🔗 Connecting to $deviceName';
      });

      try {
        await device.connect(timeout: const Duration(seconds: 6));
        lastConnectedDevice = device;

        final services = await device.discoverServices();
        final characteristic = services
            .expand((s) => s.characteristics)
            .firstWhere(
              (c) => c.properties.read,
              orElse: () => throw Exception('No readable characteristic found'),
            );

        final value = await characteristic.read();
        final jsonString = utf8.decode(value);
        final data = json.decode(jsonString);

        await handleSensorData(data, lat, lon);

        await device.disconnect();
      } catch (e) {
        setState(() {
          errorMessage =
              '❌ Connection Failed to $deviceName.\nTry restarting device or moving closer.\n$e';
          bluetoothStatus = 'Connection Failed';
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      setState(() {
        errorMessage =
            '❌ Failed to connect.\nCheck sensor, Wi-Fi/Bluetooth, or GPS.\n$e';
        bluetoothStatus = 'Connection Failed';
        isLoading = false;
      });
    }
  }

  /// HANDLE DATA & FIRESTORE
  Future<void> handleSensorData(
    Map<String, dynamic> data,
    double lat,
    double lon,
  ) async {
    final rec = getRecommendation(data);
    setState(() {
      sensorData = data;
      recommendation = rec;
      isLoading = false;
      errorMessage = '';
    });

    checkCriticalAlerts(data);

    await FirebaseFirestore.instance.collection('soil_readings').add({
      'timestamp': FieldValue.serverTimestamp(),
      'latitude': lat,
      'longitude': lon,
      'nitrogen': data['nitrogen'],
      'phosphorus': data['phosphorus'],
      'potassium': data['potassium'],
      'ph': data['ph'],
      'moisture': data['moisture'],
      'temperature': data['temperature'],
      'recommendation': rec,
    });
  }

  /// CRITICAL ALERTS
  void checkCriticalAlerts(Map<String, dynamic> data) {
    final alerts = <String>[];
    if ((data['moisture'] ?? 0) < 15) {
      alerts.add('⚠️ Soil moisture critically low');
    }
    if ((data['ph'] ?? 7.0) < 5.5) alerts.add('⚠️ Soil pH dangerously acidic');
    if ((data['temperature'] ?? 0) > 40) {
      alerts.add('⚠️ Soil temperature too high');
    }

    if (alerts.isNotEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Critical Soil Alerts'),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: alerts.map((a) => Text(a)).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  /// RECOMMENDATION LOGIC
  String getRecommendation(Map<String, dynamic> data) {
    final n = data['nitrogen'] ?? 0;
    final p = data['phosphorus'] ?? 0;
    final k = data['potassium'] ?? 0;
    final ph = data['ph'] ?? 7.0;
    final moisture = data['moisture'] ?? 0;

    if (ph < 6.0) return 'Add agricultural lime to raise pH';
    if (n < 30) return 'Apply compost or urea for nitrogen boost';
    if (p < 20) return 'Use bone meal or phosphate fertilizer';
    if (k < 25) return 'Add potash or wood ash';
    if (moisture < 30) return 'Irrigate the soil — moisture is low';
    return 'Soil conditions are optimal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Soil Sensor'),
        backgroundColor: Colors.green.shade700, // ✅ Green AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    bluetoothStatus,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (signalStrength != null)
                    Text(
                      'Signal Strength: $signalStrength dBm',
                      textAlign: TextAlign.center,
                    ),
                  if (errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.sensors),
                    label: Text(
                      sensorData == null ? 'Read Soil Sensor' : 'Read Again',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: fetchSensorData,
                  ),
                ],
              ),
      ),
    );
  }
}
