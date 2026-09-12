import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/crop/crop_plan.dart';
import 'package:agribased/models/crop/crop_budget.dart';
import 'package:agribased/models/crop/inventory_item.dart';
import 'package:agribased/models/crop/season_activity.dart';
import 'package:agribased/models/crop/production_record.dart';

/// Service for managing all crop management data
class CropManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _cropPlansCollection =>
      _firestore.collection('crop_plans');
  CollectionReference get _budgetsCollection =>
      _firestore.collection('crop_budgets');
  CollectionReference get _inventoryCollection =>
      _firestore.collection('farm_inventory');
  CollectionReference get _activitiesCollection =>
      _firestore.collection('season_activities');
  CollectionReference get _productionCollection =>
      _firestore.collection('production_records');

  // ========== CROP PLAN OPERATIONS ==========

  Future<String> createCropPlan(CropPlan plan) async {
    final docRef = await _cropPlansCollection.add(plan.toMap());
    return docRef.id;
  }

  Future<void> updateCropPlan(CropPlan plan) async {
    await _cropPlansCollection.doc(plan.id).update({
      ...plan.copyWith(updatedAt: DateTime.now()).toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteCropPlan(String planId) async {
    await _cropPlansCollection.doc(planId).delete();
  }

  Stream<List<CropPlan>> getCropPlans(String farmerId) {
    return _cropPlansCollection
        .where('farmerId', isEqualTo: farmerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => CropPlan.fromDocument(doc)).toList(),
        );
  }

  Future<CropPlan?> getCropPlanById(String planId) async {
    final doc = await _cropPlansCollection.doc(planId).get();
    if (doc.exists) {
      return CropPlan.fromDocument(doc);
    }
    return null;
  }

  // ========== BUDGET OPERATIONS ==========

  Future<String> createBudget(CropBudget budget) async {
    final docRef = await _budgetsCollection.add(budget.toMap());
    return docRef.id;
  }

  Future<void> updateBudget(CropBudget budget) async {
    await _budgetsCollection.doc(budget.id).update({
      ...budget.copyWith(updatedAt: DateTime.now()).toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteBudget(String budgetId) async {
    await _budgetsCollection.doc(budgetId).delete();
  }

  Stream<CropBudget?> getBudgetForCropPlan(String cropPlanId) {
    return _budgetsCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return CropBudget.fromDocument(snapshot.docs.first);
          }
          return null;
        });
  }

  // ========== INVENTORY OPERATIONS ==========

  Future<String> addInventoryItem(InventoryItem item) async {
    final docRef = await _inventoryCollection.add(item.toMap());
    return docRef.id;
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    await _inventoryCollection.doc(item.id).update({
      ...item.copyWith(updatedAt: DateTime.now()).toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteInventoryItem(String itemId) async {
    await _inventoryCollection.doc(itemId).delete();
  }

  Stream<List<InventoryItem>> getInventory(String farmerId, String cropPlanId) {
    print('🔍 [INVENTORY] Querying for farmerId: $farmerId, cropPlanId: $cropPlanId');
    
    // Try simple query first (no orderBy) - works without index
    return _inventoryCollection
        .where('farmerId', isEqualTo: farmerId)
        .where('cropPlanId', isEqualTo: cropPlanId)
        .snapshots()
        .map(
          (snapshot) {
            print('🔍 [INVENTORY] Got ${snapshot.docs.length} items from Firestore');
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>?;
              print('  - ${doc.id}: ${data?['name'] ?? 'no name'}');
            }
            return snapshot.docs
              .map((doc) => InventoryItem.fromDocument(doc))
              .toList();
          },
        )
        .handleError((error) {
          print('❌ [INVENTORY] Firestore error: $error');
          // Return empty list on error
          return <InventoryItem>[];
        });
  }

  Stream<List<InventoryItem>> getInventoryByCategory(
    String farmerId,
    String cropPlanId,
    String category,
  ) {
    return _inventoryCollection
        .where('farmerId', isEqualTo: farmerId)
        .where('cropPlanId', isEqualTo: cropPlanId)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => InventoryItem.fromDocument(doc))
              .toList(),
        );
  }

  // ========== SEASON ACTIVITY OPERATIONS ==========

  Future<String> createActivity(SeasonActivity activity) async {
    final docRef = await _activitiesCollection.add(activity.toMap());
    return docRef.id;
  }

  Future<void> updateActivity(SeasonActivity activity) async {
    await _activitiesCollection.doc(activity.id).update({
      ...activity.copyWith(updatedAt: DateTime.now()).toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteActivity(String activityId) async {
    await _activitiesCollection.doc(activityId).delete();
  }

  Stream<List<SeasonActivity>> getActivitiesForCropPlan(String cropPlanId) {
    return _activitiesCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .orderBy('plannedDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SeasonActivity.fromDocument(doc))
              .toList(),
        );
  }

  Stream<List<SeasonActivity>> getUpcomingActivities(
    String farmerId,
    DateTime fromDate,
  ) {
    return _activitiesCollection
        .where('farmerId', isEqualTo: farmerId)
        .where(
          'plannedDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(fromDate),
        )
        .orderBy('plannedDate')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SeasonActivity.fromDocument(doc))
              .toList(),
        );
  }

  // ========== PRODUCTION RECORD OPERATIONS ==========

  Future<String> createProductionRecord(ProductionRecord record) async {
    final docRef = await _productionCollection.add(record.toMap());
    return docRef.id;
  }

  Future<void> updateProductionRecord(ProductionRecord record) async {
    await _productionCollection.doc(record.id).update({
      ...record.copyWith(updatedAt: DateTime.now()).toMap(),
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteProductionRecord(String recordId) async {
    await _productionCollection.doc(recordId).delete();
  }

  Stream<List<ProductionRecord>> getProductionRecordsForCropPlan(
    String cropPlanId,
  ) {
    return _productionCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProductionRecord.fromDocument(doc))
              .toList(),
        );
  }

  // ========== ANALYTICS & REPORTS ==========

  Future<Map<String, dynamic>> getProfitLossAnalysis(String cropPlanId) async {
    // Get budget
    final budgetSnapshot = await _budgetsCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .limit(1)
        .get();

    CropBudget? budget;
    if (budgetSnapshot.docs.isNotEmpty) {
      budget = CropBudget.fromDocument(budgetSnapshot.docs.first);
    }

    // Get actual costs from activities
    final activitiesSnapshot = await _activitiesCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .get();

    final activities = activitiesSnapshot.docs
        .map((doc) => SeasonActivity.fromDocument(doc))
        .toList();

    // Calculate costs by category
    final actualCosts = activities.fold<double>(
      0,
      (total, activity) => total + (activity.cost ?? 0),
    );

    final totalInputCosts = activities
        .where((a) => a.activityType == 'input')
        .fold<double>(0, (total, a) => total + (a.cost ?? 0));

    final totalLaborCosts = activities
        .where((a) => a.activityType == 'labor')
        .fold<double>(0, (total, a) => total + (a.cost ?? 0));

    final totalOtherCosts = actualCosts - totalInputCosts - totalLaborCosts;

    // Get inventory costs for the specific crop plan only
    double totalInventoryCosts = 0;
    final inventorySnapshot = await _inventoryCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .get();
    final inventoryItems = inventorySnapshot.docs
        .map((doc) => InventoryItem.fromDocument(doc))
        .toList();
    totalInventoryCosts = inventoryItems.fold<double>(
      0,
      (total, item) => total + item.totalCost,
    );

    // Get production records
    final productionSnapshot = await _productionCollection
        .where('cropPlanId', isEqualTo: cropPlanId)
        .get();

    final records = productionSnapshot.docs
        .map((doc) => ProductionRecord.fromDocument(doc))
        .toList();

    final totalSales = records
        .where((r) => r.isSale)
        .fold<double>(0, (total, r) => total + r.calculatedValue);

    final totalLosses = records
        .where((r) => r.isLoss)
        .fold<double>(0, (total, r) => total + r.quantity);

    final totalLossCosts = records
        .where((r) => r.isLoss)
        .fold<double>(0, (total, r) => total + (r.cost ?? 0));

    final totalHarvested = records
        .where((r) => r.isHarvest)
        .fold<double>(0, (total, r) => total + r.quantity);

    // Calculate profit/loss including loss costs and inventory costs as deductions
    final actualCostsWithLossesAndInventory = actualCosts + totalLossCosts + totalInventoryCosts;
    final actualProfit = totalSales - actualCostsWithLossesAndInventory;
    final budgetedProfit = budget?.expectedProfit ?? 0;
    final budgetedCosts = budget?.totalCosts ?? 0;

    // Generate advice
    List<String> advice = [];
    if (actualCostsWithLossesAndInventory > budgetedCosts * 1.2) {
      advice.add(
        '⚠️ Actual costs are 20% higher than budgeted. Review your spending.',
      );
    }
    if (totalSales < (budget?.expectedIncome ?? 0) * 0.8) {
      advice.add(
        '💡 Sales are below expected income. Consider better marketing strategies.',
      );
    }
    if (totalLosses > totalHarvested * 0.1) {
      advice.add(
        '🚨 Significant losses recorded. Check for pests, disease, or storage issues.',
      );
    }
    if (actualProfit > budgetedProfit * 1.1) {
      advice.add('✅ Great job! Profit is above budgeted expectations.');
    }
    if (advice.isEmpty && actualProfit > 0) {
      advice.add('✅ You\'re on track with your crop plan.');
    }
    if (actualProfit <= 0) {
      advice.add(
        '⚠️ Currently at a loss. Review costs and explore better markets.',
      );
    }

    return {
      'budgetedIncome': budget?.expectedIncome ?? 0,
      'budgetedCosts': budgetedCosts,
      'budgetedProfit': budgetedProfit,
      'actualIncome': totalSales,
      'totalInputCosts': totalInputCosts,
      'totalLaborCosts': totalLaborCosts,
      'totalOtherCosts': totalOtherCosts > 0 ? totalOtherCosts : 0,
      'totalLossCosts': totalLossCosts,
      'totalInventoryCosts': totalInventoryCosts,
      'actualCosts': actualCostsWithLossesAndInventory,
      'actualProfit': actualProfit,
      'totalHarvested': totalHarvested,
      'totalLosses': totalLosses,
      'variance': actualProfit - budgetedProfit,
      'variancePercentage': budgetedProfit != 0
          ? ((actualProfit - budgetedProfit) / budgetedProfit * 100)
          : 0,
      'advice': advice,
    };
  }
}
