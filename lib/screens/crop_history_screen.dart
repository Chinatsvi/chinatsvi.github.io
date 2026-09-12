import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CropHistoryScreen extends StatefulWidget {
  const CropHistoryScreen({super.key});

  @override
  State<CropHistoryScreen> createState() => _CropHistoryScreenState();
}

class _CropHistoryScreenState extends State<CropHistoryScreen> {
  Future<List<QueryDocumentSnapshot>> fetchCombinedEntries() async {
    final cropEntries = await FirebaseFirestore.instance
        .collection('crop_entries')
        .orderBy('timestamp', descending: true)
        .get();

    final planBookEntries = await FirebaseFirestore.instance
        .collection('plan_book')
        .orderBy('timestamp', descending: true)
        .get();

    final combined = [...cropEntries.docs, ...planBookEntries.docs];

    combined.sort((a, b) {
      final aTime = a['timestamp'] is Timestamp ? a['timestamp'] as Timestamp : Timestamp(0, 0);
      final bTime = b['timestamp'] is Timestamp ? b['timestamp'] as Timestamp : Timestamp(0, 0);
      return bTime.compareTo(aTime);
    });

    return combined;
  }

  Future<void> deleteEntry(BuildContext context, String docId, String collection) async {
    await FirebaseFirestore.instance.collection(collection).doc(docId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Entry deleted')),
    );
    setState(() {}); // Refresh after deletion
  }

  Icon _getSourceIcon(String source) {
    switch (source) {
      case 'crop_entries':
        return const Icon(Icons.photo_camera, color: Colors.green);
      case 'plan_book':
        return const Icon(Icons.menu_book, color: Colors.blue);
      default:
        return const Icon(Icons.folder, color: Colors.grey);
    }
  }

  String _getCropEmoji(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains('maize') || name.contains('corn')) return '🌽';
    if (name.contains('tomato')) return '🍅';
    if (name.contains('wheat')) return '🌾';
    if (name.contains('banana')) return '🍌';
    if (name.contains('carrot')) return '🥕';
    if (name.contains('cabbage')) return '🥬';
    if (name.contains('pepper')) return '🌶️';
    if (name.contains('onion')) return '🧅';
    if (name.contains('potato')) return '🥔';
    return '🪴';
  }

  String _getSeasonEmoji(String plantingDate) {
    try {
      final date = DateTime.parse(plantingDate);
      final month = date.month;
      if (month >= 12 || month <= 2) return '☀️'; // Summer
      if (month >= 3 && month <= 5) return '🍂';   // Autumn
      if (month >= 6 && month <= 8) return '❄️';   // Winter
      return '🌸'; // Spring
    } catch (_) {
      return '🌦️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop History')),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: fetchCombinedEntries(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!;
          if (docs.isEmpty) return const Center(child: Text('No crop entries found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final crop = data['crop'] ?? data['crop_type'] ?? '';
              final plantingDate = (data['planting_date'] ?? data['date'] ?? '').toString();
              final harvestDate = (data['harvest_date'] ?? '').toString();
              final lat = data['latitude']?.toStringAsFixed(4) ?? '';
              final lon = data['longitude']?.toStringAsFixed(4) ?? '';
              final source = docs[index].reference.parent.id;

              final planting = plantingDate.split('T').first;
              final harvest = harvestDate.split('T').first;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: _getSourceIcon(source),
                  title: Row(
                    children: [
                      Text('${_getCropEmoji(crop)} ', style: const TextStyle(fontSize: 20)),
                      Expanded(child: Text(crop, style: const TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  subtitle: Text(
                    'Planted: $planting ${_getSeasonEmoji(plantingDate)}\n'
                    'Harvest: $harvest\nGPS: $lat, $lon',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => deleteEntry(context, docs[index].id, source),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}