import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/ads/farm_banner_ad.dart';
import '../widgets/ads/farm_native_ad.dart';

class SeasonCalendarScreen extends StatefulWidget {
  const SeasonCalendarScreen({super.key});

  @override
  State<SeasonCalendarScreen> createState() => _SeasonCalendarScreenState();
}

class _SeasonCalendarScreenState extends State<SeasonCalendarScreen> {
  final TextEditingController cropController = TextEditingController();
  DateTime? activityDate;
  Position? currentPosition;
  bool isSubmitting = false;

  Future<void> getLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;
    final position = await Geolocator.getCurrentPosition();
    setState(() => currentPosition = position);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => activityDate = picked);
    }
  }

  Future<void> submitCalendar() async {
    final crop = cropController.text.trim();
    if (crop.isEmpty || activityDate == null || currentPosition == null) return;

    setState(() => isSubmitting = true);

    await FirebaseFirestore.instance.collection('plan_book').add({
      'activity_type': crop,
      'activity_date': activityDate!.toIso8601String(),
      'latitude': currentPosition!.latitude,
      'longitude': currentPosition!.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });

    setState(() => isSubmitting = false);
    cropController.clear();
    activityDate = null;

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Season calendar saved')));
    }
  }

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = activityDate == null
        ? 'Activity Date: not set'
        : 'Activity Date: ${activityDate!.toLocal().toString().split(' ')[0]}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Season Calendar'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const FarmBannerAd(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: cropController,
              decoration: const InputDecoration(labelText: 'Activity Type'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(dateText),
                const Spacer(),
                TextButton(onPressed: pickDate, child: const Text('Pick Date')),
              ],
            ),
            const SizedBox(height: 12),
            currentPosition == null
                ? const Text('Getting GPS...')
                : Text(
                    'GPS: ${currentPosition!.latitude}, ${currentPosition!.longitude}',
                  ),
            const SizedBox(height: 16),
            const FarmNativeAd(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isSubmitting ? null : submitCalendar,
              icon: const Icon(Icons.save),
              label: const Text('Save Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}
