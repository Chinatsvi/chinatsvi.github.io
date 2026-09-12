import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/animal/animal.dart';

/// Chinatsvi-Powered Ration Planner Service
/// Generates intelligent feeding recommendations based on real farm data
class ChinatsviRationPlannerService {
  /// Singleton instance
  static final ChinatsviRationPlannerService instance =
      ChinatsviRationPlannerService._internal();
  ChinatsviRationPlannerService._internal();

  /// Test method to verify service is working
  Future<Map<String, dynamic>> testService() async {
    try {
      developer.log(
        '🧪 TEST: ChinatsviRationPlannerService.testService() called',
        name: 'ChinatsviRationPlanner',
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log(
          '❌ TEST: No authenticated user',
          name: 'ChinatsviRationPlanner',
        );
        return {'success': false, 'error': 'No authenticated user'};
      }

      developer.log(
        '✅ TEST: User authenticated: ${user.uid}',
        name: 'ChinatsviRationPlanner',
      );

      final testDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('animals')
          .limit(1)
          .get();

      developer.log(
        '📊 TEST: Found ${testDoc.docs.length} animals in collection',
        name: 'ChinatsviRationPlanner',
      );

      return {
        'success': true,
        'animalsFound': testDoc.docs.length,
        'userId': user.uid,
      };
    } catch (e) {
      developer.log(
        '❌ TEST: Error in testService: $e',
        name: 'ChinatsviRationPlanner',
      );
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Generate intelligent ration plan based on farm data
  Future<Map<String, dynamic>> generateRationPlan({
    required String animalId,
    required Animal animal,
    required bool isPoultry,
  }) async {
    try {
      developer.log(
        '🧠 STARTING Chinatsvi ration planning for ${animal.species}',
        name: 'ChinatsviRationPlanner',
      );
      developer.log('📋 Animal ID: $animalId', name: 'ChinatsviRationPlanner');
      developer.log(
        '📋 Animal object: ${animal.toString()}',
        name: 'ChinatsviRationPlanner',
      );
      developer.log(
        '📋 Animal Profile - Target Weight: ${animal.targetWeightKg}kg, Age: ${animal.ageInMonths} months (${animal.ageDisplayLabel})',
        name: 'ChinatsviRationPlanner',
      );

      // Collect all relevant farm data
      final farmData = await _collectFarmData(animalId, isPoultry);

      developer.log(
        '📊 Farm data collection completed: ${farmData['dataPoints']} data points',
        name: 'ChinatsviRationPlanner',
      );

      // If no data found, generate fallback with reasonable defaults
      if (farmData['dataPoints'] == 0) {
        developer.log(
          '⚠️ NO DATA FOUND - generating fallback plan',
          name: 'ChinatsviRationPlanner',
        );
        final fallbackPlan = await _generateFallbackPlan(animal, isPoultry);
        return {
          'success': false,
          'error':
              'No farm data found - please add growth tracker and health log records',
          'fallbackPlan': fallbackPlan,
          'dataPoints': 0,
        };
      }

      // Analyze data and generate recommendations
      final analysis = await _analyzeFarmData(farmData, animal, isPoultry);

      // Generate specific ration recommendations
      final rationPlan = await _generateRationRecommendations(
        analysis,
        animal,
        isPoultry,
      );

      developer.log(
        '✅ Chinatsvi ration plan generated successfully',
        name: 'ChinatsviRationPlanner',
      );
      developer.log(
        '📊 Final Ration Plan Target Weight: ${rationPlan['targetWeight']}kg',
        name: 'ChinatsviRationPlanner',
      );

      return {
        'success': true,
        'plan': rationPlan,
        'analysis': analysis,
        'dataPoints': farmData['dataPoints'],
        'confidence': rationPlan['confidence'],
        'lastUpdated': Timestamp.now(),
      };
    } catch (e) {
      developer.log(
        '❌ ERROR generating Chinatsvi ration plan: $e',
        name: 'ChinatsviRationPlanner',
      );
      return {
        'success': false,
        'error': e.toString(),
        'fallbackPlan': await _generateFallbackPlan(animal, isPoultry),
      };
    }
  }

  /// Collect all relevant farm data for Chinatsvi analysis
  Future<Map<String, dynamic>> _collectFarmData(
    String animalId,
    bool isPoultry,
  ) async {
    final data = <String, dynamic>{};
    int dataPoints = 0;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return {'dataPoints': 0};

      developer.log(
        '🔍 User authenticated: ${user.uid}',
        name: 'ChinatsviRationPlanner',
      );
      developer.log(
        '🔍 Collecting data for animal: $animalId',
        name: 'ChinatsviRationPlanner',
      );

      final animalRef = FirebaseFirestore.instance
          .collection('farmers')
          .doc(user.uid)
          .collection('animals')
          .doc(animalId);

      // First, get the animal document to get the correct target weight
      final animalDoc = await animalRef.get();
      if (!animalDoc.exists) return {'dataPoints': 0};

      final animalData = animalDoc.data() as Map<String, dynamic>;
      final documentTargetWeight = (animalData['targetWeightKg'] as num?)
          ?.toDouble();

      developer.log(
        '✅ Animal document exists: ${animalDoc.data()}',
        name: 'ChinatsviRationPlanner',
      );
      developer.log(
        '📏 Animal document target weight: ${documentTargetWeight ?? 'not set'}kg',
        name: 'ChinatsviRationPlanner',
      );

      // Store the document target weight for later use
      data['documentTargetWeight'] = documentTargetWeight;

      if (isPoultry) {
        // Poultry-specific collections
        developer.log(
          '🐔 Checking poultry collections...',
          name: 'ChinatsviRationPlanner',
        );

        // Check poultry-specific collections first
        final poultryCollections = [
          'poultryGrowthRecords',
          'poultry_growth_records',
          'poultryFeedingRecords',
          'poultry_feeding_records',
          'poultryProductionRecords',
          'poultry_production_records',
          'poultryHealthRecords',
          'poultry_health_records',
        ];

        for (final collectionName in poultryCollections) {
          try {
            final testSnapshot = await animalRef
                .collection(collectionName)
                .get();
            if (testSnapshot.docs.isNotEmpty) {
              developer.log(
                '✅ Found poultry data in collection: $collectionName (${testSnapshot.docs.length} docs)',
                name: 'ChinatsviRationPlanner',
              );

              // Map to standard field names
              final mappedData = testSnapshot.docs.map((doc) {
                final docData = doc.data();
                final mapped = <String, dynamic>{};

                // Map poultry fields to standard fields
                if (collectionName.contains('growth')) {
                  mapped['weightKg'] = docData['weightKg'] ?? docData['weight'];
                  mapped['date'] = docData['date'] ?? docData['recordDate'];
                } else if (collectionName.contains('feeding')) {
                  mapped['feedType'] = docData['feedType'] ?? docData['feed'];
                  mapped['quantityKg'] =
                      docData['quantityKg'] ?? docData['amount'];
                  mapped['date'] = docData['date'] ?? docData['feedingDate'];
                } else if (collectionName.contains('production')) {
                  mapped['eggsCollected'] = docData['eggsCollected'];
                  mapped['date'] = docData['date'] ?? docData['productionDate'];
                } else if (collectionName.contains('health')) {
                  mapped['type'] = docData['type'] ?? docData['healthIssue'];
                  mapped['notes'] = docData['notes'] ?? docData['symptoms'];
                  mapped['date'] = docData['date'] ?? docData['healthDate'];
                }

                return mapped;
              }).toList();

              if (collectionName.contains('growth')) {
                data['growthRecords'] = mappedData;
                dataPoints += testSnapshot.docs.length;
              } else if (collectionName.contains('feeding')) {
                data['feedingRecords'] = mappedData;
                dataPoints += testSnapshot.docs.length;
              } else if (collectionName.contains('production')) {
                data['productionRecords'] = mappedData;
                dataPoints += testSnapshot.docs.length;
              } else if (collectionName.contains('health')) {
                data['healthRecords'] = mappedData;
                dataPoints += testSnapshot.docs.length;
              }
              break;
            }
          } catch (e) {
            developer.log(
              '⚠️ Error checking poultry collection $collectionName: $e',
              name: 'ChinatsviRationPlanner',
            );
          }
        }

        // Fallback to standard collections if poultry-specific ones don't exist
        if (dataPoints == 0) {
          developer.log(
            '🐔 No poultry-specific data found, checking standard collections...',
            name: 'ChinatsviRationPlanner',
          );

          final growthSnapshot = await animalRef
              .collection('growthRecords')
              .get();
          developer.log(
            '📈 Growth records query completed: ${growthSnapshot.docs.length} documents',
            name: 'ChinatsviRationPlanner',
          );
          data['growthRecords'] = growthSnapshot.docs
              .map((doc) => doc.data())
              .toList();
          dataPoints += growthSnapshot.docs.length;

          final productionSnapshot = await animalRef
              .collection('productionRecords')
              .get();
          developer.log(
            '🥚 Production records query completed: ${productionSnapshot.docs.length} documents',
            name: 'ChinatsviRationPlanner',
          );
          data['productionRecords'] = productionSnapshot.docs
              .map((doc) => doc.data())
              .toList();
          dataPoints += productionSnapshot.docs.length;

          final healthSnapshot = await animalRef.collection('healthLogs').get();
          developer.log(
            '🏥 Health records query completed: ${healthSnapshot.docs.length} documents',
            name: 'ChinatsviRationPlanner',
          );
          data['healthRecords'] = healthSnapshot.docs
              .map((doc) => doc.data())
              .toList();
          dataPoints += healthSnapshot.docs.length;

          final feedingSnapshot = await animalRef
              .collection('feedingSchedule')
              .get();
          developer.log(
            '🍽️ Feeding records query completed: ${feedingSnapshot.docs.length} documents',
            name: 'ChinatsviRationPlanner',
          );
          data['feedingRecords'] = feedingSnapshot.docs
              .map((doc) => doc.data())
              .toList();
          dataPoints += feedingSnapshot.docs.length;
        }
      } else {
        // For other animals (cattle, goats, sheep) - use same collections as repository
        developer.log(
          '🐄 Checking livestock collections...',
          name: 'ChinatsviRationPlanner',
        );

        // Try different collection names that might exist
        final collectionsToCheck = [
          'growthRecords',
          'growth_records',
          'growth',
          'weight',
        ];

        for (final collectionName in collectionsToCheck) {
          try {
            final testSnapshot = await animalRef
                .collection(collectionName)
                .get();
            if (testSnapshot.docs.isNotEmpty) {
              developer.log(
                '✅ Found growth data in collection: $collectionName (${testSnapshot.docs.length} docs)',
                name: 'ChinatsviRationPlanner',
              );
              data['growthRecords'] = testSnapshot.docs
                  .map((doc) => doc.data())
                  .toList();
              dataPoints += testSnapshot.docs.length;
              break;
            }
          } catch (e) {
            developer.log(
              '⚠️ Error checking collection $collectionName: $e',
              name: 'ChinatsviRationPlanner',
            );
          }
        }

        // Check health collections
        final healthCollectionsToCheck = [
          'healthLogs',
          'health_logs',
          'health',
          'medical',
        ];

        for (final collectionName in healthCollectionsToCheck) {
          try {
            final testSnapshot = await animalRef
                .collection(collectionName)
                .get();
            if (testSnapshot.docs.isNotEmpty) {
              developer.log(
                '✅ Found health data in collection: $collectionName (${testSnapshot.docs.length} docs)',
                name: 'ChinatsviRationPlanner',
              );
              data['healthRecords'] = testSnapshot.docs
                  .map((doc) => doc.data())
                  .toList();
              dataPoints += testSnapshot.docs.length;
              break;
            }
          } catch (e) {
            developer.log(
              '⚠️ Error checking health collection $collectionName: $e',
              name: 'ChinatsviRationPlanner',
            );
          }
        }

        // Check feeding collections
        final feedingCollectionsToCheck = [
          'feedingSchedule',
          'feeding_schedule',
          'feeding',
          'feed',
        ];

        for (final collectionName in feedingCollectionsToCheck) {
          try {
            final testSnapshot = await animalRef
                .collection(collectionName)
                .get();
            if (testSnapshot.docs.isNotEmpty) {
              developer.log(
                '✅ Found feeding data in collection: $collectionName (${testSnapshot.docs.length} docs)',
                name: 'ChinatsviRationPlanner',
              );
              data['feedingRecords'] = testSnapshot.docs
                  .map((doc) => doc.data())
                  .toList();
              dataPoints += testSnapshot.docs.length;
              break;
            }
          } catch (e) {
            developer.log(
              '⚠️ Error checking feeding collection $collectionName: $e',
              name: 'ChinatsviRationPlanner',
            );
          }
        }
      }

      data['dataPoints'] = dataPoints;

      developer.log(
        '📊 FINAL: Collected $dataPoints data points for analysis',
        name: 'ChinatsviRationPlanner',
      );

      // Log what we found for debugging
      developer.log(
        '📈 Growth records: ${data['growthRecords']?.length ?? 0}',
        name: 'ChinatsviRationPlanner',
      );
      developer.log(
        '🏥 Health records: ${data['healthRecords']?.length ?? 0}',
        name: 'ChinatsviRationPlanner',
      );
      developer.log(
        '🍽️ Feeding records: ${data['feedingRecords']?.length ?? 0}',
        name: 'ChinatsviRationPlanner',
      );
      if (isPoultry) {
        developer.log(
          '🥚 Production records: ${data['productionRecords']?.length ?? 0}',
          name: 'ChinatsviRationPlanner',
        );
      }

      // Log sample data for debugging
      if (data['growthRecords'] != null && data['growthRecords'].isNotEmpty) {
        developer.log(
          '📊 Sample growth record: ${data['growthRecords'][0]}',
          name: 'ChinatsviRationPlanner',
        );
      }
      if (data['healthRecords'] != null && data['healthRecords'].isNotEmpty) {
        developer.log(
          '🏥 Sample health record: ${data['healthRecords'][0]}',
          name: 'ChinatsviRationPlanner',
        );
      }

      return data;
    } catch (e) {
      developer.log(
        '❌ MAJOR ERROR collecting farm data: $e',
        name: 'ChinatsviRationPlanner',
      );
      return {'dataPoints': 0};
    }
  }

  /// Analyze farm data and extract insights
  Future<Map<String, dynamic>> _analyzeFarmData(
    Map<String, dynamic> farmData,
    Animal animal,
    bool isPoultry,
  ) async {
    final analysis = <String, dynamic>{};

    try {
      developer.log(
        '🔍 Starting comprehensive farm data analysis for ${animal.species}',
        name: 'ChinatsviRationPlanner',
      );

      // Enhanced Growth Analysis
      if (farmData['growthRecords'] != null &&
          farmData['growthRecords'].isNotEmpty) {
        final growthAnalysis = _analyzeGrowthTrend(farmData['growthRecords']);
        analysis['growthTrend'] = growthAnalysis;
        analysis['currentWeight'] = growthAnalysis['currentWeight'];
        analysis['weightGainRate'] = growthAnalysis['weightGainRate'];
        analysis['growthConsistency'] = growthAnalysis['consistency'];

        developer.log(
          '📊 Enhanced Growth Analysis: Current weight = ${growthAnalysis['currentWeight']}kg',
          name: 'ChinatsviRationPlanner',
        );
      } else {
        developer.log(
          '⚠️ No growth records found - using animal profile data',
          name: 'ChinatsviRationPlanner',
        );
        analysis['growthTrend'] = {
          'trend': 'no_data',
          'consistency': 'unknown',
        };
        analysis['currentWeight'] = animal.targetWeightKg ?? 0.0;
        analysis['weightGainRate'] = 0.0;
        analysis['growthConsistency'] = 'unknown';
      }

      // Health Analysis
      if (farmData['healthRecords'] != null &&
          farmData['healthRecords'].isNotEmpty) {
        final healthAnalysis = _analyzeHealthStatus(farmData['healthRecords']);
        analysis['healthStatus'] = healthAnalysis;
        developer.log(
          '🏥 Enhanced Health Analysis: Status = ${healthAnalysis['overall']}',
          name: 'ChinatsviRationPlanner',
        );
      } else {
        developer.log(
          '⚠️ No health records found - recommend regular health monitoring',
          name: 'ChinatsviRationPlanner',
        );
        analysis['healthStatus'] = {'overall': 'unknown', 'recentIssues': []};
      }

      // Animal-specific analysis
      analysis['animalProfile'] = _analyzeAnimalProfile(animal);

      developer.log(
        '✅ Comprehensive farm data analysis completed',
        name: 'ChinatsviRationPlanner',
      );
      return analysis;
    } catch (e) {
      developer.log(
        '❌ Error analyzing farm data: $e',
        name: 'ChinatsviRationPlanner',
      );
      return {};
    }
  }

  /// Generate specific ration recommendations
  Future<Map<String, dynamic>> _generateRationRecommendations(
    Map<String, dynamic> analysis,
    Animal animal,
    bool isPoultry,
  ) async {
    try {
      developer.log(
        '🎯 Generating ration recommendations',
        name: 'ChinatsviRationPlanner',
      );

      if (isPoultry) {
        return await _generatePoultryRation(analysis, animal);
      } else {
        return await _generateLivestockRation(analysis, animal);
      }
    } catch (e) {
      developer.log(
        '❌ Error generating ration recommendations: $e',
        name: 'ChinatsviRationPlanner',
      );
      return _generateFallbackPlan(animal, isPoultry);
    }
  }

  /// Generate poultry-specific ration plan
  Future<Map<String, dynamic>> _generatePoultryRation(
    Map<String, dynamic> analysis,
    Animal animal,
  ) async {
    // Use farmer's current weight from growth tracker
    final currentWeight = analysis['currentWeight']?.toDouble() ?? 0.0;

    // Use document target weight (from Firestore) instead of animal object
    final documentTargetWeight = analysis['documentTargetWeight']?.toDouble();
    final targetWeight =
        documentTargetWeight ?? animal.targetWeightKg ?? currentWeight;

    final age = animal.ageInMonths;

    developer.log(
      '🐔 POULTRY RATION: Using farmer-entered current weight: $currentWeight kg',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '🐔 POULTRY RATION: Using document target weight: $targetWeight kg',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '🐔 POULTRY RATION: Document target weight was: ${documentTargetWeight ?? 'not set'}kg',
      name: 'ChinatsviRationPlanner',
    );

    // Generate purpose-specific insights
    final insights = _generatePoultryInsights(
      analysis,
      animal,
      currentWeight,
      targetWeight,
      age,
      animal.purpose ?? 'meat',
    );

    final rationPlan = {
      'type': 'poultry',
      'phase': age < 16
          ? 'starter'
          : age < 20
          ? 'grower'
          : 'layer',
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'dailyFeed': _calculatePoultryFeedByPurpose(
        age,
        currentWeight,
        animal.purpose ?? 'meat',
      ),
      'protein': _calculatePoultryProteinByPurpose(
        age,
        animal.purpose ?? 'meat',
      ),
      'energy': '2800-3000 kcal/kg',
      'calcium': age >= 16 ? '3.5-4.0%' : '1.0-1.2%',
      'supplements': ['Vitamin premix', 'Mineral mix'],
      'adjustments': [],
      'confidence': currentWeight > 0
          ? 0.9
          : 0.5, // Higher confidence with real farmer data
      'dataSource': currentWeight > 0
          ? 'Farmer-entered growth tracker'
          : 'Target weight estimate',
      'chinatsviInsights': insights, // Enhanced insights
    };

    developer.log(
      '🐔 POULTRY RATION: Daily feed calculated: ${rationPlan['dailyFeed']}kg',
      name: 'ChinatsviRationPlanner',
    );

    return rationPlan;
  }

  /// Generate livestock-specific ration plan
  Future<Map<String, dynamic>> _generateLivestockRation(
    Map<String, dynamic> analysis,
    Animal animal,
  ) async {
    final species = animal.species.toLowerCase();

    // Use farmer's current weight from growth tracker
    final currentWeight = analysis['currentWeight']?.toDouble() ?? 0.0;

    // Use document target weight (from Firestore) instead of animal object
    final documentTargetWeight = analysis['documentTargetWeight']?.toDouble();
    final targetWeight =
        documentTargetWeight ?? animal.targetWeightKg ?? currentWeight;

    // Use actual purpose from animal profile
    final purpose = animal.purpose ?? 'meat';

    developer.log(
      '🐄 LIVESTOCK RATION: Using farmer-entered current weight: $currentWeight kg',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '🐄 LIVESTOCK RATION: Using document target weight: $targetWeight kg',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '🐄 LIVESTOCK RATION: Animal purpose: $purpose',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '🐄 LIVESTOCK RATION: Document target weight was: ${documentTargetWeight ?? 'not set'}kg',
      name: 'ChinatsviRationPlanner',
    );

    // Generate purpose-specific insights
    final insights = _generateLivestockInsights(
      analysis,
      animal,
      currentWeight,
      targetWeight,
      species,
      purpose,
    );

    final rationPlan = {
      'type': species,
      'purpose': purpose,
      'targetWeight': targetWeight,
      'currentWeight': currentWeight,
      'dailyFeed': _calculateLivestockFeedRequirement(
        species,
        currentWeight,
        purpose,
        analysis,
      ),
      'protein': _calculateLivestockProtein(species, purpose),
      'energy': _calculateLivestockEnergy(species, currentWeight),
      'fiber': '15-20%',
      'supplements': ['Salt', 'Calcium', 'Phosphorus'],
      'adjustments': [],
      'confidence': currentWeight > 0
          ? 0.9
          : 0.5, // Higher confidence with real farmer data
      'dataSource': currentWeight > 0
          ? 'Farmer-entered growth tracker'
          : 'Target weight estimate',
      'chinatsviInsights': insights, // Enhanced insights
    };

    developer.log(
      '🐄 LIVESTOCK RATION: Daily feed calculated: ${rationPlan['dailyFeed']}kg',
      name: 'ChinatsviRationPlanner',
    );

    return rationPlan;
  }

  /// Generate fallback plan when no data is available
  Future<Map<String, dynamic>> _generateFallbackPlan(
    Animal animal,
    bool isPoultry,
  ) async {
    developer.log(
      '🔄 Generating fallback plan for ${animal.species}',
      name: 'ChinatsviRationPlanner',
    );

    double targetWeight = animal.targetWeightKg ?? 0.0;
    final age = animal.ageInMonths;

    // If target weight is 0.0, use species-based defaults
    if (targetWeight <= 0.0) {
      final species = animal.species.toLowerCase();
      if (species.contains('cattle')) {
        targetWeight = 350.0; // Default cattle weight
      } else if (species.contains('goat')) {
        targetWeight = 50.0; // Default goat weight
      } else if (species.contains('sheep')) {
        targetWeight = 40.0; // Default sheep weight
      } else if (isPoultry) {
        targetWeight = 2.0; // Default chicken weight
      } else {
        targetWeight = 100.0; // Generic default
      }
      developer.log(
        '📏 Using default target weight: ${targetWeight}kg for ${animal.species}',
        name: 'ChinatsviRationPlanner',
      );
    }

    if (isPoultry) {
      return {
        'type': 'poultry',
        'phase': age < 16
            ? 'starter'
            : age < 20
            ? 'grower'
            : 'layer',
        'targetWeight': targetWeight,
        'currentWeight': targetWeight,
        'dailyFeed': 0.12, // 120g per bird
        'protein': age < 16
            ? '22-24%'
            : age < 20
            ? '18-20%'
            : '16-18%',
        'energy': '2800-3000 kcal/kg',
        'calcium': age >= 16 ? '3.5-4.0%' : '1.0-1.2%',
        'supplements': ['Vitamin premix', 'Mineral mix'],
        'adjustments': [
          'Add growth tracker and health logs for personalized recommendations',
        ],
        'confidence': 0.3,
        'insights': [
          '⚠️ Limited data available - add growth tracker and health records for better recommendations',
        ],
      };
    } else {
      final species = animal.species.toLowerCase();
      return {
        'type': species,
        'purpose': 'meat',
        'targetWeight': targetWeight,
        'currentWeight': targetWeight,
        'dailyFeed': targetWeight * 0.025, // 2.5% of body weight
        'protein': species == 'cattle' ? '12-14%' : '14-16%',
        'energy': '2.5-3.0 Mcal/kg',
        'fiber': '15-20%',
        'supplements': ['Salt', 'Calcium', 'Phosphorus'],
        'adjustments': [
          'Add growth tracker and health logs for personalized recommendations',
        ],
        'confidence': 0.3,
        'insights': [
          '⚠️ Limited data available - add growth tracker and health records for better recommendations',
        ],
      };
    }
  }

  // Helper methods for analysis
  Map<String, dynamic> _analyzeGrowthTrend(List growthRecords) {
    developer.log(
      '📈 Analyzing ${growthRecords.length} farmer-entered growth records',
      name: 'ChinatsviRationPlanner',
    );

    if (growthRecords.isEmpty) {
      developer.log(
        '❌ No growth records found - farmer has not entered any weights',
        name: 'ChinatsviRationPlanner',
      );
      return {
        'trend': 'no_data',
        'consistency': 'unknown',
        'currentWeight': 0.0,
        'weightGainRate': 0.0,
        'message': 'No farmer-entered weights found in growth tracker',
      };
    }

    // Get actual weights from farmer-entered growth records
    final weights = <double>[];
    final dates = <DateTime>[];

    // Sort records by date (most recent first)
    final sortedRecords = List<Map<String, dynamic>>.from(growthRecords);
    sortedRecords.sort((a, b) {
      DateTime dateA = DateTime.now();
      DateTime dateB = DateTime.now();

      if (a['date'] != null) {
        if (a['date'] is String) {
          dateA = DateTime.parse(a['date'] as String);
        } else if (a['date'] is Timestamp) {
          dateA = (a['date'] as Timestamp).toDate();
        }
      }

      if (b['date'] != null) {
        if (b['date'] is String) {
          dateB = DateTime.parse(b['date'] as String);
        } else if (b['date'] is Timestamp) {
          dateB = (b['date'] as Timestamp).toDate();
        }
      }

      return dateB.compareTo(dateA); // Most recent first
    });

    for (final record in sortedRecords) {
      try {
        developer.log(
          '🔍 Analyzing farmer-entered growth record: $record',
          name: 'ChinatsviRationPlanner',
        );

        // Get the farmer's entered weight from weightKg field
        double weight = 0.0;
        if (record['weightKg'] != null) {
          weight = (record['weightKg'] as num).toDouble();
          developer.log(
            '✅ Found farmer-entered weightKg: ${weight}kg',
            name: 'ChinatsviRationPlanner',
          );
        } else if (record['weight'] != null) {
          weight = (record['weight'] as num).toDouble();
          developer.log(
            '✅ Found farmer-entered weight: ${weight}kg',
            name: 'ChinatsviRationPlanner',
          );
        } else {
          developer.log(
            '❌ No weight field found in record. Available keys: ${record.keys.toList()}',
            name: 'ChinatsviRationPlanner',
          );
          continue;
        }

        // Parse date
        DateTime recordDate = DateTime.now();
        if (record['date'] != null) {
          if (record['date'] is String) {
            recordDate = DateTime.parse(record['date'] as String);
          } else if (record['date'] is Timestamp) {
            recordDate = (record['date'] as Timestamp).toDate();
          }
        }

        if (weight > 0) {
          weights.add(weight);
          dates.add(recordDate);
          developer.log(
            '📊 Farmer entered weight: ${weight}kg on ${recordDate.toLocal().toString().split(' ')[0]}',
            name: 'ChinatsviRationPlanner',
          );
        } else {
          developer.log(
            '⚠️ Farmer entered weight is 0 or negative, skipping record',
            name: 'ChinatsviRationPlanner',
          );
        }
      } catch (e) {
        developer.log(
          '⚠️ Error parsing farmer-entered growth record: $e',
          name: 'ChinatsviRationPlanner',
        );
      }
    }

    if (weights.isEmpty) {
      developer.log(
        '❌ No valid farmer-entered weights found in growth records',
        name: 'ChinatsviRationPlanner',
      );
      return {
        'trend': 'no_data',
        'consistency': 'unknown',
        'currentWeight': 0.0,
        'weightGainRate': 0.0,
        'message': 'No valid farmer-entered weights found',
      };
    }

    // Use the most recent farmer-entered weight as current weight
    final currentWeight = weights.first; // Most recent weight (sorted by date)
    final previousWeight = weights.length > 1 ? weights[1] : weights.first;
    final weightChange = currentWeight - previousWeight;

    // Calculate days between records
    int daysBetweenRecords = 1; // default
    if (dates.length > 1) {
      try {
        daysBetweenRecords = dates[0].difference(dates[1]).inDays;
        if (daysBetweenRecords <= 0) daysBetweenRecords = 1;
      } catch (e) {
        developer.log(
          '⚠️ Error calculating days between records: $e',
          name: 'ChinatsviRationPlanner',
        );
      }
    }

    // Calculate actual daily weight gain rate from farmer-entered data
    final weightGainRate = weightChange / daysBetweenRecords;

    // Determine trend based on farmer-entered weight changes
    String trend;
    if (weightGainRate > 0.01) {
      trend = 'increasing';
    } else if (weightGainRate < -0.01) {
      trend = 'decreasing';
    } else {
      trend = 'stable';
    }

    developer.log(
      '📊 FARMER DATA ANALYSIS: Most recent weight: $currentWeight kg, Previous: $previousWeight kg',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '📊 FARMER DATA ANALYSIS: Weight change: ${weightChange.toStringAsFixed(2)}kg over $daysBetweenRecords days',
      name: 'ChinatsviRationPlanner',
    );
    developer.log(
      '📊 FARMER DATA ANALYSIS: Daily weight gain rate: ${weightGainRate.toStringAsFixed(3)}kg/day',
      name: 'ChinatsviRationPlanner',
    );

    return {
      'trend': trend,
      'consistency': 'good',
      'currentWeight': currentWeight,
      'previousWeight': previousWeight,
      'weightChange': weightChange,
      'weightGainRate': weightGainRate,
      'daysBetweenRecords': daysBetweenRecords,
      'dataPoints': weights.length,
      'message': 'Using farmer-entered weights from growth tracker',
    };
  }

  Map<String, dynamic> _analyzeHealthStatus(List healthRecords) {
    if (healthRecords.isEmpty) {
      return {
        'overall': 'unknown',
        'recentIssues': [],
        'vaccinationStatus': 'unknown',
        'nutritionalIssues': [],
        'healthScore': 0.5,
      };
    }

    final recentIssues = <String>[];
    final nutritionalIssues = <String>[];
    double healthScore = 0.5; // baseline

    // Analyze recent health records
    for (final record in healthRecords.take(5)) {
      final type = record['type']?.toString().toLowerCase() ?? '';
      final notes = record['notes']?.toString().toLowerCase() ?? '';

      // Check for specific health issues
      if (type.contains('sick') ||
          type.contains('disease') ||
          notes.contains('sick')) {
        recentIssues.add('Sickness detected');
        healthScore -= 0.2;
      }

      if (type.contains('injury') || notes.contains('injury')) {
        recentIssues.add('Injury detected');
        healthScore -= 0.1;
      }

      // Check for nutritional indicators
      if (notes.contains('weight loss') || notes.contains('losing weight')) {
        nutritionalIssues.add('Weight loss - may need increased energy');
        healthScore -= 0.15;
      }

      if (type.contains('vaccin')) {
        healthScore += 0.1; // Good for preventive care
      }
    }

    // Determine overall health status
    String overallStatus;
    if (healthScore >= 0.8) {
      overallStatus = 'excellent';
    } else if (healthScore >= 0.6) {
      overallStatus = 'good';
    } else if (healthScore >= 0.4) {
      overallStatus = 'fair';
    } else {
      overallStatus = 'poor';
    }

    developer.log(
      '🏥 Health Analysis: Status=$overallStatus, Score=${healthScore.toStringAsFixed(2)}, Issues=${recentIssues.length}',
      name: 'ChinatsviRationPlanner',
    );

    return {
      'overall': overallStatus,
      'recentIssues': recentIssues,
      'vaccinationStatus': 'unknown',
      'nutritionalIssues': nutritionalIssues,
      'healthScore': healthScore.clamp(0.0, 1.0),
      'recordCount': healthRecords.length,
    };
  }

  Map<String, dynamic> _analyzeAnimalProfile(Animal animal) {
    developer.log(
      '🔍 Analyzing animal profile: ${animal.species}, Target Weight: ${animal.targetWeightKg}kg',
      name: 'ChinatsviRationPlanner',
    );

    return {
      'age': animal.ageInMonths,
      'targetWeight': animal.targetWeightKg,
      'species': animal.species,
      'breed': animal.breed,
      'sex': animal.sex,
      'purpose': animal.purpose ?? 'meat', // ✅ Use actual purpose from animal
      'initialFlockSize': animal.initialFlockSize,
    };
  }

  // Calculation methods
  double _calculatePoultryFeedRequirement(int age, double currentWeight) {
    // Base feed requirement per bird
    double baseFeed;
    if (age < 4) {
      baseFeed = 0.03; // 30g per chick
    } else if (age < 16) {
      baseFeed = 0.08; // 80g per grower
    } else {
      baseFeed = 0.12; // 120g per layer
    }

    // Adjust for current weight (larger birds need more feed)
    if (currentWeight > 2.0) {
      baseFeed *= (currentWeight / 2.0); // Scale with weight
    }

    return baseFeed;
  }

  String _calculatePoultryProtein(int age) {
    if (age < 4) return '22-24%';
    if (age < 16) return '18-20%';
    return '16-18%';
  }

  /// Calculate purpose-specific poultry feed requirements
  double _calculatePoultryFeedByPurpose(
    int age,
    double currentWeight,
    String purpose,
  ) {
    final baseFeed = _calculatePoultryFeedRequirement(age, currentWeight);

    switch (purpose) {
      case 'meat':
        // Broilers need more protein and energy for rapid growth
        return baseFeed * 1.15; // 15% more feed for broilers
      case 'eggs':
        // Layers need consistent nutrition for egg production
        return baseFeed * 1.0; // Standard feed
      case 'breeding':
        // Breeding stock need optimal condition
        return baseFeed * 1.05; // 5% more for breeding
      case 'show':
        // Show birds need optimal condition
        return baseFeed * 1.0; // Standard feed
      case 'dual':
        // Dual purpose birds need balanced nutrition
        return baseFeed * 1.0; // Standard feed
      default:
        return baseFeed;
    }
  }

  /// Calculate purpose-specific poultry protein requirements
  String _calculatePoultryProteinByPurpose(int age, String purpose) {
    switch (purpose) {
      case 'meat':
        if (age < 4) return '24-26%'; // Higher protein for broiler chicks
        if (age < 16) return '20-22%'; // Higher protein for growing broilers
        return '18-20%'; // Standard for finishing broilers
      case 'eggs':
        if (age < 4) return '22-24%'; // Standard for layer chicks
        if (age < 16) return '18-20%'; // Standard for growing layers
        return '16-18%'; // Standard for laying hens
      case 'breeding':
        return '18-20%'; // Moderate protein for breeding
      case 'show':
        return '18-20%'; // Moderate protein for show condition
      case 'dual':
        return '18-20%'; // Balanced protein
      default:
        return _calculatePoultryProtein(age);
    }
  }

  double _calculateLivestockFeedRequirement(
    String species,
    double weight,
    String purpose,
    Map<String, dynamic> analysis,
  ) {
    // Base feed requirement as percentage of body weight
    double basePercentage;
    switch (species) {
      case 'cattle':
        basePercentage = 0.025; // 2.5% of body weight
      case 'goat':
        basePercentage = 0.04; // 4% of body weight
        break;
      case 'sheep':
        basePercentage = 0.035; // 3.5% of body weight
        break;
      default:
        basePercentage = 0.03; // 3% of body weight
    }

    // Start with base requirement
    double feedRequirement = weight * basePercentage;

    // Adjust for purpose-specific needs
    switch (purpose) {
      case 'dairy':
        feedRequirement *=
            1.30; // Dairy animals need 30% more energy for milk production
        developer.log(
          '🥛 Increasing feed by 30% for dairy production',
          name: 'ChinatsviRationPlanner',
        );
        break;
      case 'breeding':
        feedRequirement *=
            1.15; // Breeding animals need 15% more for reproduction
        developer.log(
          '🐄 Increasing feed by 15% for breeding',
          name: 'ChinatsviRationPlanner',
        );
        break;
      case 'work':
        feedRequirement *= 1.20; // Work animals need 20% more for energy
        developer.log(
          '💪 Increasing feed by 20% for work/draft',
          name: 'ChinatsviRationPlanner',
        );
        break;
      case 'show':
        feedRequirement *= 1.10; // Show animals need 10% more for condition
        developer.log(
          '🏆 Increasing feed by 10% for show condition',
          name: 'ChinatsviRationPlanner',
        );
        break;
      case 'meat':
        // Standard calculation for meat production
        break;
      case 'pet':
        feedRequirement *= 0.85; // Pets need less (maintenance only)
        developer.log(
          '🐾 Decreasing feed by 15% for pet/companion',
          name: 'ChinatsviRationPlanner',
        );
        break;
      default:
        // Use standard calculation
        break;
    }

    // Adjust for growth needs
    final growthTrend =
        analysis['growthTrend']?['trend']?.toString() ?? 'stable';
    final weightGainRate = analysis['weightGainRate']?.toDouble() ?? 0.0;

    developer.log(
      '🧮 Calculating feed for $species: Base ${feedRequirement.toStringAsFixed(2)}kg, Purpose: $purpose, Trend: $growthTrend',
      name: 'ChinatsviRationPlanner',
    );

    if (growthTrend == 'decreasing' || weightGainRate < 0.01) {
      feedRequirement *= 1.15; // Poor growth - increase feed
      developer.log(
        '⚠️ Increasing feed by 15% due to poor growth',
        name: 'ChinatsviRationPlanner',
      );
    }

    // Adjust for health issues
    final healthIssues =
        analysis['healthStatus']?['recentIssues'] as List? ?? [];
    if (healthIssues.isNotEmpty) {
      feedRequirement *= 1.10; // Increase feed for recovery
      developer.log(
        '🏥 Increasing feed by 10% due to health issues',
        name: 'ChinatsviRationPlanner',
      );
    }

    // Adjust for age (younger animals need more feed per kg)
    final age = analysis['animalProfile']?['age']?.toInt() ?? 0;
    if (age < 12) {
      // Less than 1 year
      feedRequirement *= 1.25;
    } else if (age < 24) {
      // Less than 2 years
      feedRequirement *= 1.10;
    }

    developer.log(
      '🎯 Final feed requirement: ${feedRequirement.toStringAsFixed(2)}kg per day for ${weight}kg $species ($purpose)',
      name: 'ChinatsviRationPlanner',
    );

    return feedRequirement;
  }

  String _calculateLivestockProtein(String species, String purpose) {
    switch (species) {
      case 'cattle':
        switch (purpose) {
          case 'dairy':
            return '16-18%'; // Dairy needs higher protein for milk
          case 'breeding':
            return '14-16%'; // Breeding needs moderate protein
          case 'work':
            return '12-14%'; // Work needs standard protein
          case 'show':
            return '14-16%'; // Show needs good protein for condition
          case 'meat':
          default:
            return '12-14%'; // Standard for meat production
        }
      case 'goat':
        switch (purpose) {
          case 'dairy':
            return '16-18%'; // Dairy goats need more protein
          case 'breeding':
            return '15-17%'; // Breeding goats need extra protein
          case 'meat':
          default:
            return '14-16%'; // Standard for goats
        }
      case 'sheep':
        switch (purpose) {
          case 'dairy':
            return '15-17%'; // Dairy sheep
          case 'breeding':
            return '14-16%'; // Breeding sheep
          case 'wool': // If they had wool purpose
            return '12-14%'; // Wool production needs less protein
          case 'meat':
          default:
            return '12-14%'; // Standard for sheep
        }
      default:
        return '12-16%'; // Generic default
    }
  }

  String _calculateLivestockEnergy(String species, double weight) {
    if (weight < 100) return '2.5-2.8 Mcal/kg';
    if (weight < 300) return '2.8-3.0 Mcal/kg';
    return '3.0-3.2 Mcal/kg';
  }

  /// Generate comprehensive poultry insights based on analysis
  List<String> _generatePoultryInsights(
    Map<String, dynamic> analysis,
    Animal animal,
    double currentWeight,
    double targetWeight,
    int age,
    String purpose,
  ) {
    final insights = <String>[];
    final growthTrend =
        analysis['growthTrend']?['trend']?.toString() ?? 'stable';
    final healthStatus =
        analysis['healthStatus']?['overall']?.toString() ?? 'unknown';
    final weightGainRate = analysis['weightGainRate']?.toDouble() ?? 0.0;
    final productionRecords = analysis['productionRecords'] as List? ?? [];

    // Weight-based insights
    if (currentWeight > 0) {
      final weightProgress = (currentWeight / targetWeight * 100).clamp(0, 100);
      if (weightProgress >= 95) {
        insights.add(
          ' Excellent! Bird is at ${weightProgress.toStringAsFixed(0)}% of target weight',
        );
      } else if (weightProgress >= 80) {
        insights.add(
          ' Good progress: Bird is at ${weightProgress.toStringAsFixed(0)}% of target weight',
        );
      } else if (weightProgress >= 60) {
        insights.add(
          ' Bird is at ${weightProgress.toStringAsFixed(0)}% of target weight - monitor growth',
        );
      } else {
        insights.add(
          ' Bird is only ${weightProgress.toStringAsFixed(0)}% of target weight - review feeding',
        );
      }
    }

    // Growth trend insights
    switch (growthTrend) {
      case 'increasing':
        insights.add(
          ' Excellent weight gain trend - continue current feeding program',
        );
        break;
      case 'stable':
        insights.add(
          ' Weight is stable - ensure adequate nutrition for growth phase',
        );
        break;
      case 'decreasing':
        insights.add(
          ' Weight loss detected - increase feed quantity or check for health issues',
        );
        break;
    }

    // Production insights (for layers)
    if (purpose == 'eggs' && productionRecords.isNotEmpty) {
      final recentProduction = productionRecords
          .take(7)
          .toList(); // Last 7 days
      if (recentProduction.isNotEmpty) {
        final totalEggs = recentProduction.fold<int>(0, (sum, record) {
          return sum + (record['eggsCollected'] as int? ?? 0);
        });
        final avgDailyEggs = (totalEggs / recentProduction.length)
            .toStringAsFixed(1);

        insights.add(
          ' Recent egg production: ${avgDailyEggs} eggs/day (last 7 days)',
        );

        if (double.parse(avgDailyEggs) >= 0.8) {
          insights.add(
            ' Excellent egg production - maintain current nutrition',
          );
        } else if (double.parse(avgDailyEggs) >= 0.6) {
          insights.add(' Good egg production - ensure adequate calcium');
        } else {
          insights.add(' Low egg production - check nutrition and lighting');
        }
      }
    }

    // Age-specific insights
    if (age < 4) {
      insights.add(
        ' Chick phase: Ensure 22-24% protein for optimal development',
      );
      insights.add(' Provide clean water and maintain brooder temperature');
      insights.add(
        ' Brooder temperature: 32-35°C for first week, 30-32°C for second week',
      );
    } else if (age < 16) {
      insights.add(' Grower phase: 18-20% protein supports rapid growth');
      insights.add(' Introduce grains gradually to develop digestive system');
      insights.add(' Provide adequate space: 0.05-0.1 m² per bird');
    } else {
      insights.add(
        ' Layer phase: 16-18% protein with 3.5-4.0% calcium for egg production',
      );
      insights.add(' Monitor egg production and adjust calcium as needed');
      insights.add(' Provide 14-16 hours of light for optimal egg laying');
    }

    // Purpose-specific insights
    switch (purpose) {
      case 'meat':
        insights.add(
          ' Meat production: Focus on high-energy feed for rapid weight gain',
        );
        insights.add(' Monitor feed conversion ratio for cost efficiency');
        insights.add(' Target weight gain: 30-40g per day for broilers');
        break;
      case 'eggs':
        insights.add(
          ' Egg production: Optimize nutrition for consistent laying',
        );
        insights.add(' Ensure adequate calcium for strong eggshells');
        insights.add(' Maintain consistent lighting schedule');
        break;
      case 'breeding':
        insights.add(
          ' Breeding stock: Maintain optimal body condition for reproduction',
        );
        insights.add(' Ensure adequate calcium for strong eggshells');
        insights.add(' Select birds with good conformation for breeding');
        break;
      case 'show':
        insights.add(
          ' Show birds: Maintain uniform appearance and feather quality',
        );
        insights.add(' Consider adding omega-3 for enhanced plumage');
        insights.add(' Follow breed standards for optimal presentation');
        break;
      case 'dual':
        insights.add(
          ' Dual purpose: Balance egg production and meat qualities',
        );
        insights.add(' Monitor both egg yield and weight gain');
        insights.add(' Adjust feed based on primary production goal');
        break;
    }

    // Health-based insights
    switch (healthStatus) {
      case 'excellent':
        insights.add(
          ' Excellent health status - maintain current management practices',
        );
        break;
      case 'good':
        insights.add(' Good health - continue monitoring and preventive care');
        break;
      case 'fair':
        insights.add(' Fair health - review biosecurity and nutrition program');
        insights.add(' Consider health check-up if condition doesn\'t improve');
        break;
      case 'poor':
        insights.add(
          ' Poor health status - immediate veterinary attention recommended',
        );
        insights.add(' Isolate sick birds and review management practices');
        break;
    }

    // Nutritional insights
    if (weightGainRate < 0.01 && age < 20) {
      insights.add(
        ' Low weight gain rate - consider increasing protein or energy density',
      );
    }
    if (weightGainRate > 0.05) {
      insights.add(
        ' High weight gain - monitor for leg problems and provide adequate space',
      );
    }

    // Management insights
    insights.add(' Ensure adequate housing space: 0.1-0.2 m² per bird');
    insights.add(' Monitor temperature: 21-24°C optimal for adult birds');
    insights.add(' Provide continuous access to clean water');
    insights.add(' Implement regular parasite control program');
    insights.add(' Maintain clean litter to prevent disease');

    // Performance insights
    if (purpose == 'eggs' && productionRecords.isNotEmpty) {
      final latestRecord = productionRecords.first;
      final eggsToday = latestRecord['eggsCollected'] as int? ?? 0;

      if (eggsToday >= 1) {
        insights.add(' Bird is actively laying - maintain current nutrition');
      } else {
        insights.add(
          ' No eggs recorded today - check for stress or nutritional issues',
        );
      }
    }

    return insights;
  }

  /// Generate comprehensive livestock insights based on analysis
  List<String> _generateLivestockInsights(
    Map<String, dynamic> analysis,
    Animal animal,
    double currentWeight,
    double targetWeight,
    String species,
    String purpose,
  ) {
    final insights = <String>[];
    final growthTrend =
        analysis['growthTrend']?['trend']?.toString() ?? 'stable';
    final healthStatus =
        analysis['healthStatus']?['overall']?.toString() ?? 'unknown';
    final weightGainRate = analysis['weightGainRate']?.toDouble() ?? 0.0;
    final age = analysis['animalProfile']?['age']?.toInt() ?? 0;

    // Weight-based insights
    if (currentWeight > 0) {
      final weightProgress = (currentWeight / targetWeight * 100).clamp(0, 100);
      if (weightProgress >= 95) {
        insights.add(
          '🎯 Excellent! Animal is at ${weightProgress.toStringAsFixed(0)}% of target weight',
        );
      } else if (weightProgress >= 80) {
        insights.add(
          '📈 Good progress: Animal is at ${weightProgress.toStringAsFixed(0)}% of target weight',
        );
      } else if (weightProgress >= 60) {
        insights.add(
          '⚠️ Animal is at ${weightProgress.toStringAsFixed(0)}% of target weight - monitor growth',
        );
      } else {
        insights.add(
          '❌ Animal is only ${weightProgress.toStringAsFixed(0)}% of target weight - review feeding',
        );
      }
    }

    // Growth trend insights
    switch (growthTrend) {
      case 'increasing':
        insights.add(
          '📊 Excellent weight gain trend - continue current feeding program',
        );
        break;
      case 'stable':
        insights.add(
          '📊 Weight is stable - ensure adequate nutrition for maintenance',
        );
        break;
      case 'decreasing':
        insights.add(
          '⚠️ Weight loss detected - increase feed quantity or check for health issues',
        );
        break;
    }

    // Species-specific insights
    switch (species) {
      case 'cattle':
        insights.add(
          '🐄 Cattle: Ensure adequate roughage (minimum 1.5% of body weight)',
        );
        insights.add('💧 Provide 30-50 liters of water daily for adult cattle');
        if (purpose == 'dairy') {
          insights.add(
            '🥛 Dairy cattle: Monitor milk yield and adjust energy accordingly',
          );
          insights.add(
            '🌾 Maintain body condition score 2.5-3.5 for optimal milk production',
          );
        }
        break;
      case 'goat':
        insights.add(
          '🐐 Goats: Provide browse and forage variety for optimal nutrition',
        );
        insights.add(
          '🧂 Ensure adequate mineral supplementation, especially copper',
        );
        if (purpose == 'dairy') {
          insights.add(
            '🥛 Dairy goats: Milk production requires high-quality forage',
          );
        }
        break;
      case 'sheep':
        insights.add(
          '🐑 Sheep: Provide adequate grazing space (minimum 2 acres per 10 ewes)',
        );
        insights.add(
          '🦏 Monitor for internal parasites, especially in grazing season',
        );
        break;
    }

    // Purpose-specific insights
    switch (purpose) {
      case 'dairy':
        insights.add(
          '🥛 Dairy production: High-energy diet essential for milk yield',
        );
        insights.add(
          '⏰ Maintain consistent feeding schedule for milk production',
        );
        insights.add('🧪 Test milk quality regularly to optimize nutrition');
        break;
      case 'breeding':
        insights.add(
          '🐄 Breeding: Maintain optimal body condition for reproduction',
        );
        insights.add('🥗 Provide extra nutrition 60 days before breeding');
        insights.add('👶 Ensure adequate minerals for fetal development');
        break;
      case 'meat':
        insights.add('🍖 Meat production: Focus on efficient weight gain');
        insights.add('⚖️ Monitor feed conversion ratio for profitability');
        insights.add(
          '📈 Target consistent weight gain of 0.7-0.9 kg/day for beef cattle',
        );
        break;
      case 'work':
        insights.add(
          '💪 Work animals: High-energy diet needed for physical labor',
        );
        insights.add('🏋️ Provide adequate rest and recovery time');
        insights.add('🦯 Monitor for signs of fatigue and adjust workload');
        break;
      case 'show':
        insights.add('🏆 Show animals: Maintain excellent body condition');
        insights.add('✨ Focus on muscle development and coat quality');
        insights.add(
          '🎯 Follow specific breed standards for optimal presentation',
        );
        break;
    }

    // Age-specific insights
    if (age < 12) {
      insights.add('👶 Young animal: Higher protein needed for growth');
      insights.add('🥛 Provide milk replacer or creep feeding for young stock');
    } else if (age < 24) {
      insights.add('🌱 Growing animal: Balance growth and development');
      insights.add('📊 Monitor growth rate against breed standards');
    } else {
      insights.add('🐄 Adult animal: Focus on maintenance and production');
      insights.add('🦷 Monitor dental health for efficient feed utilization');
    }

    // Health-based insights
    switch (healthStatus) {
      case 'excellent':
        insights.add(
          '💚 Excellent health status - maintain current management practices',
        );
        break;
      case 'good':
        insights.add('💚 Good health - continue preventive care measures');
        break;
      case 'fair':
        insights.add(
          '⚠️ Fair health - review nutrition and management program',
        );
        insights.add(
          '🩺 Schedule health check-up if condition doesn\'t improve',
        );
        break;
      case 'poor':
        insights.add(
          '🚨 Poor health status - immediate veterinary attention required',
        );
        insights.add(
          '🏥 Isolate if contagious and review biosecurity measures',
        );
        break;
    }

    // Performance insights
    if (weightGainRate < 0.01 && age < 24) {
      insights.add('🔍 Low weight gain - review feed quality and quantity');
    }
    if (weightGainRate > 0.05) {
      insights.add('⚡ Rapid weight gain - monitor for metabolic issues');
    }

    // Management insights
    insights.add('🏠 Provide adequate shelter and protection from elements');
    insights.add('🌾 Ensure consistent feeding schedule - same time daily');
    insights.add('💧 Monitor water quality and availability');
    insights.add('📝 Keep detailed records of performance and health');

    return insights;
  }
}
