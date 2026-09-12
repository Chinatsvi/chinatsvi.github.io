import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/poultry/poultry_batch.dart';
import '../../models/poultry/poultry_exit_record.dart';
import '../../models/poultry/poultry_mortality_record.dart';

// Centralized calculation service for poultry operations
class PoultryCalculationService {
  static const String CURRENCY_SYMBOL = 'R'; // Use ZAR consistently

  // Calculate egg percentage
  static double calculateEggPercentage({
    required int eggsCollected,
    required int currentBirdCount,
  }) {
    if (currentBirdCount <= 0) return 0.0;
    return (eggsCollected / currentBirdCount) * 100;
  }

  // Update batch current count based on mortality
  static Future<void> updateBirdCountAfterMortality({
    required String batchId,
    required int deaths,
  }) async {
    try {
      final batchRef = FirebaseFirestore.instance
          .collection('poultry_batches')
          .doc(batchId);

      // Get current batch
      final batchDoc = await batchRef.get();
      if (!batchDoc.exists) return;

      final batch = PoultryBatch.fromDocument(batchDoc);

      // Calculate new current count
      final newCurrentCount = (batch.currentCount - deaths).clamp(
        0,
        batch.initialCount,
      );

      // Update the batch
      await batchRef.update({
        'currentCount': newCurrentCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating bird count: $e');
    }
  }

  // Update batch current count based on exit (sold/slaughtered/culled)
  static Future<void> updateBirdCountAfterExit({
    required String batchId,
    required int exited,
  }) async {
    try {
      final batchRef = FirebaseFirestore.instance
          .collection('poultry_batches')
          .doc(batchId);

      // Get current batch
      final batchDoc = await batchRef.get();
      if (!batchDoc.exists) return;

      final batch = PoultryBatch.fromDocument(batchDoc);

      // Calculate new current count
      final newCurrentCount = (batch.currentCount - exited).clamp(
        0,
        batch.initialCount,
      );

      // Update the batch
      await batchRef.update({
        'currentCount': newCurrentCount,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error updating bird count after exit: $e');
    }
  }

  // Calculate total mortality for a batch
  static Future<int> getTotalMortality(String batchId) async {
    try {
      final mortalitySnapshot = await FirebaseFirestore.instance
          .collection('poultry_mortality_records')
          .where('batchId', isEqualTo: batchId)
          .get();

      int totalDeaths = 0;
      for (final doc in mortalitySnapshot.docs) {
        final record = PoultryMortalityRecord.fromMap(doc.id, doc.data());
        totalDeaths += record.deaths;
      }

      return totalDeaths;
    } catch (e) {
      print('Error calculating total mortality: $e');
      return 0;
    }
  }

  // Calculate total mortality expense (costLoss) for a batch
  static Future<double> getTotalMortalityExpense(String batchId) async {
    try {
      final mortalitySnapshot = await FirebaseFirestore.instance
          .collection('poultry_mortality_records')
          .where('batchId', isEqualTo: batchId)
          .get();

      double totalExpense = 0.0;
      for (final doc in mortalitySnapshot.docs) {
        final record = doc.data();
        totalExpense += (record['costLoss'] as num?)?.toDouble() ?? 0.0;
      }

      return totalExpense;
    } catch (e) {
      print('Error calculating total mortality expense: $e');
      return 0.0;
    }
  }

  // Calculate total feed cost for a batch
  static Future<double> getTotalFeedCost(String batchId) async {
    try {
      final feedingSnapshot = await FirebaseFirestore.instance
          .collection('poultry_feeding_records')
          .where('batchId', isEqualTo: batchId)
          .get();

      double totalCost = 0.0;
      for (final doc in feedingSnapshot.docs) {
        final record = doc.data();
        totalCost += record['cost']?.toDouble() ?? 0.0;
      }

      return totalCost;
    } catch (e) {
      print('Error calculating total feed cost: $e');
      return 0.0;
    }
  }

  // Calculate total vet cost for a batch
  static Future<double> getTotalVetCost(String batchId) async {
    try {
      final vetSnapshot = await FirebaseFirestore.instance
          .collection('poultry_vet_records')
          .where('batchId', isEqualTo: batchId)
          .get();

      double totalCost = 0.0;
      for (final doc in vetSnapshot.docs) {
        final record = doc.data();
        totalCost += record['cost']?.toDouble() ?? 0.0;
      }

      return totalCost;
    } catch (e) {
      print('Error calculating total vet cost: $e');
      return 0.0;
    }
  }

  // Calculate total revenue from eggs
  static Future<double> getTotalEggRevenue(String batchId) async {
    try {
      final productionSnapshot = await FirebaseFirestore.instance
          .collection('poultry_production_records')
          .where('batchId', isEqualTo: batchId)
          .get();

      double totalRevenue = 0.0;
      for (final doc in productionSnapshot.docs) {
        final record = doc.data();
        totalRevenue += record['revenue']?.toDouble() ?? 0.0;
      }

      return totalRevenue;
    } catch (e) {
      print('Error calculating total egg revenue: $e');
      return 0.0;
    }
  }

  // Calculate total revenue from birds sold out of a batch.
  static Future<double> getTotalBirdSalesRevenue(String batchId) async {
    try {
      final exitSnapshot = await FirebaseFirestore.instance
          .collection('poultry_exit_records')
          .where('batchId', isEqualTo: batchId)
          .get();

      double totalRevenue = 0.0;
      for (final doc in exitSnapshot.docs) {
        final record = PoultryExitRecord.fromDocument(doc);
        if (record.isSold) {
          totalRevenue += record.income ?? 0.0;
        }
      }

      return totalRevenue;
    } catch (e) {
      print('Error calculating total bird sales revenue: $e');
      return 0.0;
    }
  }

  // Calculate profit/loss for a batch
  static Future<Map<String, double>> calculateProfitLoss({
    required PoultryBatch batch,
  }) async {
    try {
      // Get all costs and revenues
      final feedCost = await getTotalFeedCost(batch.id);
      final vetCost = await getTotalVetCost(batch.id);
      final mortalityExpense = await getTotalMortalityExpense(batch.id);
      final eggRevenue = await getTotalEggRevenue(batch.id);
      final birdSalesRevenue = await getTotalBirdSalesRevenue(batch.id);

      // Calculate initial batch cost (previously 'per chick' -> now stored as batch cost)
      double initialBirdCost = 0.0;
      if (batch.chickCost != null) {
        initialBirdCost = batch.chickCost!; // cost for whole batch
      }

      // Total costs (include mortality expense if recorded)
      final totalCosts =
          initialBirdCost + feedCost + vetCost + mortalityExpense;

      // Include both egg sales and money received for sold birds.
      final totalRevenue = eggRevenue + birdSalesRevenue;

      // Profit/Loss
      final profitLoss = totalRevenue - totalCosts;

      return {
        'initialBirdCost': initialBirdCost,
        'feedCost': feedCost,
        'vetCost': vetCost,
        'totalCosts': totalCosts,
        'eggRevenue': eggRevenue,
        'birdSalesRevenue': birdSalesRevenue,
        'totalRevenue': totalRevenue,
        'profitLoss': profitLoss,
      };
    } catch (e) {
      print('Error calculating profit/loss: $e');
      return {'profitLoss': 0.0};
    }
  }

  // Format currency consistently
  static String formatCurrency(double amount) {
    return '$CURRENCY_SYMBOL${amount.toStringAsFixed(2)}';
  }

  // Get batch summary for display
  static Future<Map<String, dynamic>> getBatchSummary(String batchId) async {
    try {
      // Get batch
      final batchDoc = await FirebaseFirestore.instance
          .collection('poultry_batches')
          .doc(batchId)
          .get();

      if (!batchDoc.exists) return {};

      final batch = PoultryBatch.fromDocument(batchDoc);

      // Get today's production
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayProductionSnapshot = await FirebaseFirestore.instance
          .collection('poultry_production_records')
          .where('batchId', isEqualTo: batchId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
          .where('date', isLessThan: Timestamp.fromDate(todayEnd))
          .get();

      int todayEggs = 0;
      for (final doc in todayProductionSnapshot.docs) {
        final record = doc.data();
        todayEggs += (record['eggsCollected'] as num?)?.toInt() ?? 0;
      }

      // Calculate egg percentage
      final eggPercentage = calculateEggPercentage(
        eggsCollected: todayEggs,
        currentBirdCount: batch.currentCount,
      );

      // Get profit/loss
      final profitLossData = await calculateProfitLoss(batch: batch);

      return {
        'batch': batch,
        'todayEggs': todayEggs,
        'eggPercentage': eggPercentage,
        'profitLoss': profitLossData['profitLoss'] ?? 0.0,
        'mortalityRate': batch.mortalityRate,
        'currencySymbol': CURRENCY_SYMBOL,
      };
    } catch (e) {
      print('Error getting batch summary: $e');
      return {};
    }
  }
}
