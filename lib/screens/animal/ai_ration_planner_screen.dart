import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import '../../models/animal/animal.dart';
import '../../services/ai_ration_planner_service.dart';
import '../../services/animal/animal_repository_interface.dart';

/// Chinatsvi-Powered Ration Planner Screen
/// Automatically generates intelligent feeding recommendations based on real farm data
class ChinatsviRationPlannerScreen extends StatefulWidget {
  final Animal animal;
  final AnimalRepository repository;

  const ChinatsviRationPlannerScreen({
    super.key,
    required this.animal,
    required this.repository,
  });

  @override
  State<ChinatsviRationPlannerScreen> createState() =>
      _ChinatsviRationPlannerScreenState();
}

class _ChinatsviRationPlannerScreenState
    extends State<ChinatsviRationPlannerScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _rationPlan;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generateRationPlan();
  }

  Future<void> _generateRationPlan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      developer.log(
        '🔍 Starting ration plan generation for animal: ${widget.animal.id}',
        name: 'ChinatsviRationPlannerScreen',
      );
      developer.log(
        '🔍 Animal species: ${widget.animal.species}',
        name: 'ChinatsviRationPlannerScreen',
      );
      developer.log(
        '🔍 Animal breed: ${widget.animal.breed}',
        name: 'ChinatsviRationPlannerScreen',
      );

      // First test if our service is working at all
      developer.log(
        '🧪 Testing service connectivity...',
        name: 'ChinatsviRationPlannerScreen',
      );
      final testResult = await ChinatsviRationPlannerService.instance
          .testService();
      developer.log(
        '🧪 Test result: $testResult',
        name: 'ChinatsviRationPlannerScreen',
      );

      // Test if we can get data directly from repository first
      try {
        final growthRecords = await widget.repository.listGrowthRecords(
          widget.animal.id,
        );
        developer.log(
          '📈 Repository test: Found ${growthRecords.length} growth records',
          name: 'ChinatsviRationPlannerScreen',
        );

        final healthRecords = await widget.repository.listHealthRecords(
          widget.animal.id,
        );
        developer.log(
          '🏥 Repository test: Found ${healthRecords.length} health records',
          name: 'ChinatsviRationPlannerScreen',
        );

        final feedingRecords = await widget.repository.listFeedingEntries(
          widget.animal.id,
        );
        developer.log(
          '🍽️ Repository test: Found ${feedingRecords.length} feeding records',
          name: 'ChinatsviRationPlannerScreen',
        );
      } catch (repoError) {
        developer.log(
          '❌ Repository test failed: $repoError',
          name: 'ChinatsviRationPlannerScreen',
        );
      }

      final isPoultry = widget.animal.species.toLowerCase() == 'poultry';
      developer.log(
        '🐔 Is poultry: $isPoultry',
        name: 'ChinatsviRationPlannerScreen',
      );

      final result = await ChinatsviRationPlannerService.instance
          .generateRationPlan(
            animalId: widget.animal.id,
            animal: widget.animal,
            isPoultry: isPoultry,
          );

      developer.log(
        '📊 Ration plan result: $result',
        name: 'ChinatsviRationPlannerScreen',
      );

      if (result['success'] == true) {
        setState(() {
          _rationPlan = result['plan'];
          developer.log(
            '✅ Chinatsvi Ration Plan loaded: ${_rationPlan!['targetWeight']}kg target weight',
            name: 'ChinatsviRationPlannerScreen',
          );
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Failed to generate ration plan';
          _rationPlan = result['fallbackPlan'];
          developer.log(
            '⚠️ Using fallback plan: ${_rationPlan?['targetWeight']}kg target weight',
            name: 'ChinatsviRationPlannerScreen',
          );
        });
      }
    } catch (e) {
      developer.log(
        '❌ Error in ration plan generation: $e',
        name: 'ChinatsviRationPlannerScreen',
      );
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chinatsvi Ration Planner - ${widget.animal.species}'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateRationPlan,
            tooltip: 'Regenerate Plan',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Analyzing your farm data...'),
                  SizedBox(height: 8),
                  Text(
                    'Chinatsvi is creating personalized feeding recommendations',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          : _error != null && _rationPlan == null
          ? _buildErrorView()
          : _buildRationPlanView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Unable to Generate Ration Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateRationPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRationPlanView() {
    if (_rationPlan == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Chinatsvi Confidence Badge
          _buildConfidenceBadge(),
          const SizedBox(height: 16),

          // Animal Profile Summary
          _buildAnimalProfileCard(),
          const SizedBox(height: 16),

          //Chinatsvi Insights
          _buildChinatsviInsightsCard(),
          const SizedBox(height: 16),

          // Ration Plan Details
          _buildRationPlanCard(),
          const SizedBox(height: 16),

          // Nutritional Requirements
          _buildNutritionalRequirementsCard(),
          const SizedBox(height: 16),

          // Supplements & Adjustments
          _buildSupplementsCard(),
          const SizedBox(height: 16),

          // Actionable Recommendations
          _buildRecommendationsCard(),

          if (_error != null) ...[
            const SizedBox(height: 16),
            _buildWarningCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildConfidenceBadge() {
    final confidence = _rationPlan!['confidence'] ?? 0.5;
    final confidencePercentage = (confidence * 100).round();
    final confidenceColor = confidence > 0.8
        ? Colors.green
        : confidence > 0.6
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: confidenceColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: confidenceColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Chinatsvi Confidence: $confidencePercentage% - Based on your farm data analysis',
              style: TextStyle(
                color: confidenceColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalProfileCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pets, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Animal Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildProfileRow('Species', widget.animal.species),
            _buildProfileRow('Breed', widget.animal.breed),
            _buildProfileRow('Age', widget.animal.ageDisplayLabel),
            if (widget.animal.targetWeightKg != null)
              _buildProfileRow(
                'Target Weight',
                '${widget.animal.targetWeightKg} kg',
              ),
            if (widget.animal.initialFlockSize != null)
              _buildProfileRow(
                'Flock Size',
                '${widget.animal.initialFlockSize}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildChinatsviInsightsCard() {
    final insights =
        (_rationPlan!['chinatsviInsights'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Chinatsvi Insights',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text('No specific insights available')
            else
              ...insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Expanded(child: Text(insight)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRationPlanCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.restaurant, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Feeding Plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPlanRow(
              'Type',
              _rationPlan!['type']?.toString() ?? 'Standard',
            ),
            _buildPlanRow(
              'Purpose',
              _rationPlan!['purpose']?.toString() ?? 'N/A',
            ),
            if (_rationPlan!['targetWeight'] != null)
              _buildPlanRow(
                'Target Weight',
                '${_rationPlan!['targetWeight']} kg',
              ),
            if (_rationPlan!['currentWeight'] != null)
              _buildPlanRow(
                'Current Weight',
                '${_rationPlan!['currentWeight']} kg',
              ),
            _buildPlanRow(
              'Daily Feed',
              '${_rationPlan!['dailyFeed']?.toString() ?? 'N/A'} kg',
            ),
            _buildPlanRow('Frequency', '2-3 times per day'),
            _buildPlanRow('Feeding Method', _getFeedingMethod()),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionalRequirementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Nutritional Requirements',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPlanRow(
              'Protein',
              _rationPlan!['protein']?.toString() ?? 'N/A',
            ),
            _buildPlanRow(
              'Energy',
              _rationPlan!['energy']?.toString() ?? 'N/A',
            ),
            if (_rationPlan!['calcium'] != null)
              _buildPlanRow('Calcium', _rationPlan!['calcium'].toString()),
            if (_rationPlan!['phosphorus'] != null)
              _buildPlanRow(
                'Phosphorus',
                _rationPlan!['phosphorus'].toString(),
              ),
            if (_rationPlan!['fiber'] != null)
              _buildPlanRow('Fiber', _rationPlan!['fiber'].toString()),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsCard() {
    final supplements =
        (_rationPlan!['supplements'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];
    final adjustments =
        (_rationPlan!['adjustments'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.medication, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Supplements & Adjustments',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (supplements.isNotEmpty) ...[
              const Text(
                'Recommended Supplements:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...supplements.map(
                (supplement) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(supplement)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (adjustments.isNotEmpty) ...[
              const Text(
                'Adjustments Needed:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ...adjustments.map(
                (adjustment) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.report_problem,
                        size: 16,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(adjustment)),
                    ],
                  ),
                ),
              ),
            ],

            if (supplements.isEmpty && adjustments.isEmpty)
              const Text('No specific supplements or adjustments needed'),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard() {
    final recommendations =
        (_rationPlan!['recommendations'] as List<dynamic>?)
            ?.map((item) => item.toString())
            .toList() ??
        [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, color: Colors.teal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Actionable Recommendations',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendations.isEmpty)
              const Text(
                'Continue monitoring and record keeping for better recommendations',
              )
            else
              ...recommendations.map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(recommendation)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Limited Data Available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add more growth, health, and production records to get more accurate AI recommendations.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getFeedingMethod() {
    final type = _rationPlan!['type']?.toString() ?? '';
    if (type.contains('broiler')) return 'Ad libitum (free feeding)';
    if (type.contains('layer')) return 'Controlled feeding';
    if (type.contains('cattle')) return 'TMR (Total Mixed Ration)';
    return 'Standard feeding';
  }

  Widget _buildPlanRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
