// lib/screens/animal/growth_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class GrowthTrackerScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;
  final double targetWeight;

  const GrowthTrackerScreen({
    super.key,
    required this.animal,
    required this.repository,
    this.targetWeight = 400,
  });

  @override
  State<GrowthTrackerScreen> createState() => _GrowthTrackerScreenState();
}

class _GrowthTrackerScreenState extends State<GrowthTrackerScreen> {
  List<GrowthRecord> _records = [];
  late ZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    _zoomPanBehavior = ZoomPanBehavior(
      enablePanning: true,
      enablePinching: true,
      zoomMode: ZoomMode.x,
    );
    _load();
  }

  Future<void> _load() async {
    final list = await widget.repository.listGrowthRecords(widget.animal.id);

    // Always oldest ➜ newest
    list.sort((a, b) => a.date.compareTo(b.date));

    setState(() => _records = list);
  }

  Future<void> _addRecord() async {
    final weightCtrl = TextEditingController();

    final result = await showDialog<GrowthRecord>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Weight Record'),
        content: TextField(
          controller: weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Weight (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(
                context,
                GrowthRecord(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  animalId: widget.animal.id,
                  date: DateTime.now(),
                  weightKg: double.tryParse(weightCtrl.text) ?? 0,
                  // aiTips can be generated here if you extend GrowthRecord
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      await widget.repository.addGrowthRecord(result);
      _load();
    }
  }

  /// Farmer-friendly AI advisory (mocked here, replace with AI service call)
  List<String> _generateTips(GrowthRecord record) {
    final target = widget.targetWeight;
    final diff = target - record.weightKg;

    if (diff > 50) {
      return [
        "Weight is below target. Increase protein in ration.",
        "Monitor monthly growth to align with market goals.",
        "Ensure feed intake matches age and weight.",
      ];
    } else {
      return [
        "Growth is on track — keep feed consistent.",
        "Maintain water availability, especially in hot weather.",
        "Record weights monthly to sustain profit margins.",
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_records.isEmpty) {
      return Scaffold(
        bottomNavigationBar: const FarmBannerAd(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text('No growth data yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 16),
                const FarmNativeAd(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addRecord,
          backgroundColor: Colors.green.shade700,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    }

    final maxWeight = [
      ..._records.map((e) => e.weightKg),
      widget.targetWeight,
    ].reduce((a, b) => a > b ? a : b);

    // Target line uses only start & end dates
    final targetLine = [
      GrowthRecord(
        id: 'start',
        animalId: widget.animal.id,
        date: _records.first.date,
        weightKg: widget.targetWeight,
      ),
      GrowthRecord(
        id: 'end',
        animalId: widget.animal.id,
        date: _records.last.date,
        weightKg: widget.targetWeight,
      ),
    ];

    // Advisory tips based on latest record
    final latestRecord = _records.last;
    final tips = _generateTips(latestRecord);

    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),

            /// Legend
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendItem(color: Colors.green, text: 'Actual Weight'),
                  SizedBox(width: 20),
                  _LegendItem(color: Colors.red, text: 'Target Weight'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// Graph
            SizedBox(
              height: 280,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SfCartesianChart(
                  zoomPanBehavior: _zoomPanBehavior,
                  tooltipBehavior: TooltipBehavior(enable: true),
                  primaryXAxis: DateTimeAxis(
                    title: const AxisTitle(text: 'Date'),
                    minimum: _records.first.date,
                    maximum: _records.last.date,
                    intervalType: DateTimeIntervalType.days,
                    interval: 1,
                    dateFormat: DateFormat('dd MMM'),
                    labelRotation: -45,
                    edgeLabelPlacement: EdgeLabelPlacement.shift,
                    majorGridLines: const MajorGridLines(width: 0),
                  ),
                  primaryYAxis: NumericAxis(
                    title: const AxisTitle(text: 'Weight (kg)'),
                    minimum: 0,
                    maximum: maxWeight + 20,
                    interval: 20,
                    majorGridLines: const MajorGridLines(width: 0.5),
                  ),
                  series: <CartesianSeries>[
                    LineSeries<GrowthRecord, DateTime>(
                      dataSource: _records,
                      xValueMapper: (r, _) => r.date,
                      yValueMapper: (r, _) => r.weightKg,
                      color: Colors.green,
                      width: 3,
                      markerSettings: const MarkerSettings(isVisible: true),
                    ),
                    LineSeries<GrowthRecord, DateTime>(
                      dataSource: targetLine,
                      xValueMapper: (r, _) => r.date,
                      yValueMapper: (r, _) => r.weightKg,
                      dashArray: const [6, 6],
                      color: Colors.red,
                      width: 2,
                    ),
                  ],
                ),
              ),
            ),

            /// AI Advisory Card
            Card(
              color: Colors.green.shade50,
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI Advisory",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ...tips.map((tip) => Text("• $tip")),
                  ],
                ),
              ),
            ),

            // ── Native Ad: below growth chart / advisory ──
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: FarmNativeAd(),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

/// Legend widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}
