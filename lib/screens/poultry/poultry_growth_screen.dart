import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:agribased/widgets/ads/farm_banner_ad.dart';
import 'package:agribased/widgets/ads/farm_native_ad.dart';

class PoultryGrowthScreen extends StatefulWidget {
  final Animal animal;
  final PoultryRepository repository;

  const PoultryGrowthScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<PoultryGrowthScreen> createState() => _PoultryGrowthScreenState();
}

class _PoultryGrowthScreenState extends State<PoultryGrowthScreen> {
  late Future<List<PoultryGrowthRecord>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.getGrowthRecords(widget.animal.id);
    setState(() {});
  }

  Future<void> _addRecord() async {
    final weightCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Growth Record'),
        content: TextField(
          controller: weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Average weight (kg)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(weightCtrl.text.trim()) ?? 0;
              if (weight <= 0) return;

              if (!mounted) return;

              final now = DateTime.now();
              final record = PoultryGrowthRecord(
                id: now.millisecondsSinceEpoch.toString(),
                batchId: widget.animal.id,
                date: now,
                averageWeightKg: weight,
                ageDays: now.difference(widget.animal.createdAt).inDays,
                createdAt: now,
                updatedAt: now,
              );

              try {
                if (!mounted) return;
                await widget.repository.addGrowthRecord(record);

                if (!mounted) return;
                if (!context.mounted) return;
                Navigator.pop(context, true);
                _load();
              } catch (e) {
                if (!mounted) return;
                if (!mounted) return;
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to save growth record: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const FarmBannerAd(),
      body: FutureBuilder<List<PoultryGrowthRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No poultry growth records yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    const FarmNativeAd(),
                  ],
                ),
              ),
            );
          }

          // Sort by date ascending (oldest → newest)
          records.sort((a, b) => a.date.compareTo(b.date));

          // Prepare chart data
          final chartData = records
              .map(
                (r) => _ChartData(r.date, r.averageWeightKg, r.targetWeightKg),
              )
              .toList();

          return SingleChildScrollView(
            child: Column(
              children: [
                // Chart Header with Summary
                Card(
                  margin: const EdgeInsets.all(12),
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Growth Progress Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Current Weight',
                                '${records.isNotEmpty ? records.last.averageWeightKg.toStringAsFixed(2) : "0.0"} kg',
                                Icons.monitor_weight,
                                Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSummaryCard(
                                'Age',
                                '${records.isNotEmpty ? records.last.ageDays : 0} days',
                                Icons.calendar_today,
                                Colors.orange,
                              ),
                            ),
                          ],
                        ),
                        if (records.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  'Total Records',
                                  '${records.length}',
                                  Icons.list,
                                  Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSummaryCard(
                                  'Avg Daily Gain',
                                  _calculateAverageDailyGain(records),
                                  Icons.trending_up,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Chart
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weight Growth Chart',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 300,
                          child: SfCartesianChart(
                            // Title
                            title: const ChartTitle(
                              text: 'Poultry Weight Over Time',
                              textStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            // X-axis (Date)
                            primaryXAxis: DateTimeAxis(
                              title: const AxisTitle(
                                text: 'Date',
                                textStyle: TextStyle(fontSize: 12),
                              ),
                              dateFormat: DateFormat('MMM dd'),
                              labelStyle: const TextStyle(fontSize: 10),
                              majorGridLines: const MajorGridLines(width: 0),
                            ),

                            // Y-axis (Weight)
                            primaryYAxis: NumericAxis(
                              title: const AxisTitle(
                                text: 'Weight (kg)',
                                textStyle: TextStyle(fontSize: 12),
                              ),
                              labelStyle: const TextStyle(fontSize: 10),
                              decimalPlaces: 2,
                            ),

                            // Tooltip
                            tooltipBehavior: TooltipBehavior(
                              enable: true,
                              format: 'point.x: point.y kg',
                              header: '',
                            ),

                            // Legend
                            legend: const Legend(
                              isVisible: true,
                              position: LegendPosition.bottom,
                              textStyle: TextStyle(fontSize: 11),
                            ),

                            // Data series
                            series: <CartesianSeries>[
                              LineSeries<_ChartData, DateTime>(
                                dataSource: chartData,
                                xValueMapper: (_ChartData data, _) => data.date,
                                yValueMapper: (_ChartData data, _) =>
                                    data.weight,
                                name: 'Actual Weight (kg)',
                                color: Colors.green.shade600,
                                width: 3,
                                markerSettings: MarkerSettings(
                                  isVisible: true,
                                  color: Colors.green.shade600,
                                  borderColor: Colors.white,
                                  borderWidth: 2,
                                  height: 8,
                                  width: 8,
                                ),
                              ),

                              // Target weight line (if available)
                              if (records.any((r) => r.targetWeightKg != null))
                                LineSeries<_ChartData, DateTime>(
                                  dataSource: chartData
                                      .where((d) => d.targetWeight != null)
                                      .toList(),
                                  xValueMapper: (_ChartData data, _) =>
                                      data.date,
                                  yValueMapper: (_ChartData data, _) =>
                                      data.targetWeight,
                                  name: 'Target Weight (kg)',
                                  color: Colors.red.shade400,
                                  width: 2,
                                  dashArray: const <double>[5, 5],
                                  markerSettings: MarkerSettings(
                                    isVisible: true,
                                    color: Colors.red.shade400,
                                    borderColor: Colors.white,
                                    borderWidth: 2,
                                    height: 6,
                                    width: 6,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                const Divider(),

                // Records List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Growth Records',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final r = records[index];
                      final isLatest = index == records.length - 1;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        elevation: isLatest ? 4 : 1,
                        color: isLatest ? Colors.green.shade50 : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLatest
                                ? Colors.green.shade600
                                : Colors.grey.shade400,
                            child: const Icon(
                              Icons.monitor_weight,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            r.date.toLocal().toString().split(" ").first,
                            style: TextStyle(
                              fontWeight: isLatest
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weight: ${r.averageWeightKg.toStringAsFixed(2)} kg',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.green.shade700,
                                ),
                              ),
                              Text(
                                'Age: ${r.ageDays} days (${(r.ageDays / 7).toStringAsFixed(1)} weeks)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (r.targetWeightKg != null)
                                Text(
                                  'Target: ${r.targetWeightKg!.toStringAsFixed(2)} kg',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                            ],
                          ),
                          trailing: isLatest
                              ? Chip(
                                  label: const Text('Latest'),
                                  backgroundColor: Colors.green.shade600,
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: FarmNativeAd(),
                ),
                const SizedBox(height: 60),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecord,
        backgroundColor: Colors.green.shade700,
        tooltip: 'Add Growth Record',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Build summary card widget
  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate average daily weight gain
  String _calculateAverageDailyGain(List<PoultryGrowthRecord> records) {
    if (records.length < 2) return 'N/A';

    final first = records.first;
    final last = records.last;

    final weightGain = last.averageWeightKg - first.averageWeightKg;
    final daysDifference = last.ageDays - first.ageDays;

    if (daysDifference <= 0) return 'N/A';

    final dailyGain = weightGain / daysDifference;
    return '${dailyGain.toStringAsFixed(3)} kg/day';
  }
}

class _ChartData {
  final DateTime date;
  final double weight;
  final double? targetWeight;

  _ChartData(this.date, this.weight, this.targetWeight);
}
