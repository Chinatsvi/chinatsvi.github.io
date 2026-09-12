import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/models/poultry/poultry_vet_record.dart';
import 'package:agribased/models/poultry/poultry_exit_record.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_ration_plan.dart';
import 'package:agribased/models/poultry/egg_stock.dart';
import 'package:agribased/services/poultry/poultry_repository_interface.dart';
import 'package:agribased/services/poultry/firestore_poultry_repository.dart';
import 'package:agribased/services/poultry/poultry_calculation_service.dart';

// Enhanced Poultry Repository with Stream support
class EnhancedPoultryRepository implements PoultryRepository {
  final PoultryRepository _baseRepo = FirestorePoultryRepository();

  // Stream methods (not in base interface)
  Stream<List<PoultryBatch>> watchPoultryBatches() {
    return FirebaseFirestore.instance
        .collection('poultry_batches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryBatch.fromDocument(doc))
              .toList(),
        );
  }

  Stream<PoultryBatch?> watchPoultryBatch(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_batches')
        .doc(batchId)
        .snapshots()
        .map((doc) => doc.exists ? PoultryBatch.fromDocument(doc) : null);
  }

  Stream<List<PoultryHealthRecord>> watchHealthRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_health_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryHealthRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PoultryFeedingRecord>> watchFeedingRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_feeding_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryFeedingRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PoultryGrowthRecord>> watchGrowthRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_growth_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryGrowthRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PoultryVetRecord>> watchVetRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_vet_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    PoultryVetRecord.fromMap({'id': doc.id, ...doc.data()}),
              )
              .toList(),
        );
  }

  Stream<List<PoultryExitRecord>> watchExitRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_exit_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryExitRecord.fromDocument(doc))
              .toList(),
        );
  }

  Stream<List<PoultryMortalityRecord>> watchMortalityRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_mortality_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryMortalityRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PoultryProductionRecord>> watchProductionRecords(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_production_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryProductionRecord.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<PoultryRationPlan>> watchRationPlans(String batchId) {
    return FirebaseFirestore.instance
        .collection('poultry_ration_plans')
        .where('batchId', isEqualTo: batchId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PoultryRationPlan.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Delegate other methods to base repository
  @override
  Future<List<PoultryHealthRecord>> getHealthRecords(String batchId) =>
      _baseRepo.getHealthRecords(batchId);

  @override
  Future<List<PoultryFeedingRecord>> getFeedingRecords(String batchId) =>
      _baseRepo.getFeedingRecords(batchId);

  @override
  Future<List<PoultryGrowthRecord>> getGrowthRecords(String batchId) =>
      _baseRepo.getGrowthRecords(batchId);

  @override
  Future<List<PoultryVetRecord>> getVetRecords(String batchId) =>
      _baseRepo.getVetRecords(batchId);

  @override
  Future<List<PoultryExitRecord>> getExitRecords(String batchId) =>
      _baseRepo.getExitRecords(batchId);

  @override
  Future<List<PoultryProductionRecord>> getProductionRecords(String batchId) =>
      _baseRepo.getProductionRecords(batchId);

  @override
  Future<List<PoultryRationPlan>> getRationPlans(String batchId) =>
      _baseRepo.getRationPlans(batchId);

  @override
  Future<void> addHealthRecord(PoultryHealthRecord record) =>
      _baseRepo.addHealthRecord(record);

  @override
  Future<void> addFeedingRecord(PoultryFeedingRecord record) =>
      _baseRepo.addFeedingRecord(record);

  @override
  Future<void> addGrowthRecord(PoultryGrowthRecord record) =>
      _baseRepo.addGrowthRecord(record);

  @override
  Future<void> addVetRecord(PoultryVetRecord record) =>
      _baseRepo.addVetRecord(record);

  @override
  Future<void> addExitRecord(PoultryExitRecord record) async {
    await _baseRepo.addExitRecord(record);
  }

  @override
  Future<void> addPoultryProductionRecord(PoultryProductionRecord record) =>
      _baseRepo.addPoultryProductionRecord(record);

  @override
  Future<void> updatePoultryProductionRecord(PoultryProductionRecord record) =>
      _baseRepo.updatePoultryProductionRecord(record);

  @override
  Future<void> addRationPlan(PoultryRationPlan plan) =>
      _baseRepo.addRationPlan(plan);

  @override
  Future<void> deleteRationPlan(String planId) =>
      _baseRepo.deleteRationPlan(planId);

  @override
  Future<double> getTotalVetCost(String batchId) =>
      _baseRepo.getTotalVetCost(batchId);

  @override
  Future<List<EggStockTransaction>> listEggStockTransactions(String batchId) =>
      _baseRepo.listEggStockTransactions(batchId);

  @override
  Future<void> addEggStockTransaction(EggStockTransaction transaction) =>
      _baseRepo.addEggStockTransaction(transaction);

  @override
  Future<void> deleteEggStockTransaction(String transactionId) =>
      _baseRepo.deleteEggStockTransaction(transactionId);

  @override
  Future<EggStockSummary> calculateEggStockSummary(String batchId) =>
      _baseRepo.calculateEggStockSummary(batchId);

  @override
  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record) async {
    // Add the mortality record (base repo already updates batch counts)
    await _baseRepo.addPoultryMortalityRecord(record);
  }

  @override
  Future<List<PoultryProductionRecord>> listPoultryProductionRecords(
    String batchId,
  ) => _baseRepo.listPoultryProductionRecords(batchId);

  @override
  Future<void> addPoultryBatch(PoultryBatch batch) =>
      _baseRepo.addPoultryBatch(batch);

  @override
  Future<PoultryBatch?> getPoultryBatch(String batchId) =>
      _baseRepo.getPoultryBatch(batchId);

  @override
  Future<List<PoultryMortalityRecord>> listPoultryMortalityRecords(
    String batchId,
  ) => _baseRepo.listPoultryMortalityRecords(batchId);

  // Stream for egg stock transactions
  Stream<List<EggStockTransaction>> watchEggStockTransactions(String batchId) {
    return FirebaseFirestore.instance
        .collection('egg_stock_transactions')
        .where('batchId', isEqualTo: batchId)
        .orderBy('transactionDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EggStockTransaction.fromDocument(doc))
              .toList(),
        );
  }
}

// Provider for enhanced poultry repository
final enhancedPoultryRepositoryProvider = Provider<EnhancedPoultryRepository>((
  ref,
) {
  return EnhancedPoultryRepository();
});

// Provider for poultry batches list
final poultryBatchesProvider = StreamProvider<List<PoultryBatch>>((ref) {
  final repository = ref.watch(enhancedPoultryRepositoryProvider);
  return repository.watchPoultryBatches();
});

// Provider for specific poultry batch
final poultryBatchProvider = StreamProvider.family<PoultryBatch?, String>((
  ref,
  batchId,
) {
  final repository = ref.watch(enhancedPoultryRepositoryProvider);
  return repository.watchPoultryBatch(batchId);
});

// Providers for specific batch records
final poultryHealthRecordsProvider =
    StreamProvider.family<List<PoultryHealthRecord>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchHealthRecords(batchId);
    });

final poultryFeedingRecordsProvider =
    StreamProvider.family<List<PoultryFeedingRecord>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchFeedingRecords(batchId);
    });

final poultryGrowthRecordsProvider =
    StreamProvider.family<List<PoultryGrowthRecord>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchGrowthRecords(batchId);
    });

final poultryVetRecordsProvider =
    StreamProvider.family<List<PoultryVetRecord>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchVetRecords(batchId);
    });

final poultryExitRecordsProvider =
    StreamProvider.family<List<PoultryExitRecord>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchExitRecords(batchId);
    });

final poultryMortalityRecordsProvider =
    StreamProvider.family<List<PoultryMortalityRecord>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchMortalityRecords(batchId);
    });

final poultryProductionRecordsProvider =
    StreamProvider.family<List<PoultryProductionRecord>, String>((
      ref,
      batchId,
    ) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchProductionRecords(batchId);
    });

final poultryRationPlansProvider =
    StreamProvider.family<List<PoultryRationPlan>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchRationPlans(batchId);
    });

final eggStockTransactionsProvider =
    StreamProvider.family<List<EggStockTransaction>, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.watchEggStockTransactions(batchId);
    });

final eggStockSummaryProvider =
    FutureProvider.family<EggStockSummary, String>((ref, batchId) {
      final repository = ref.watch(enhancedPoultryRepositoryProvider);
      return repository.calculateEggStockSummary(batchId);
    });
