import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'poultry_repository_interface.dart';
import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/models/poultry/poultry_vet_record.dart';
import 'package:agribased/models/poultry/poultry_exit_record.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_ration_plan.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/egg_stock.dart';

class FirestorePoultryRepository implements PoultryRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* ─────────────── FETCH RECORDS ─────────────── */

  @override
  Future<List<PoultryHealthRecord>> getHealthRecords(String batchId) async {
    final snapshot = await _db
        .collection('poultry_health_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date')
        .get();
    return snapshot.docs
        .map((d) => PoultryHealthRecord.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<PoultryFeedingRecord>> getFeedingRecords(String batchId) async {
    final snapshot = await _db
        .collection('poultry_feeding_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date')
        .get();
    return snapshot.docs
        .map((d) => PoultryFeedingRecord.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<PoultryGrowthRecord>> getGrowthRecords(String batchId) async {
    final snapshot = await _db
        .collection('poultry_growth_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date')
        .get();
    return snapshot.docs
        .map((d) => PoultryGrowthRecord.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<PoultryVetRecord>> getVetRecords(String batchId) async {
    final snapshot = await _db
        .collection('poultry_vet_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('visitDate')
        .get();
    return snapshot.docs
        .map((d) => PoultryVetRecord.fromMap({'id': d.id, ...d.data()}))
        .toList();
  }

  @override
  Future<List<PoultryExitRecord>> getExitRecords(String batchId) async {
    final snapshot = await _db
        .collection('poultry_exit_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date')
        .get();
    return snapshot.docs.map((d) => PoultryExitRecord.fromDocument(d)).toList();
  }

  @override
  Future<List<PoultryProductionRecord>> getProductionRecords(
    String batchId,
  ) async {
    return listPoultryProductionRecords(batchId);
  }

  @override
  Future<List<PoultryProductionRecord>> listPoultryProductionRecords(
    String batchId,
  ) async {
    final snapshot = await _db
        .collection('poultry_production_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date')
        .get();
    return snapshot.docs
        .map((d) => PoultryProductionRecord.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<PoultryRationPlan>> getRationPlans(String batchId) async {
    final snapshot = await _db
        .collection('poultry_ration_plans')
        .where('batchId', isEqualTo: batchId)
        .get();
    return snapshot.docs
        .map((d) => PoultryRationPlan.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<List<PoultryMortalityRecord>> listPoultryMortalityRecords(
    String batchId,
  ) async {
    final snapshot = await _db
        .collection('poultry_mortality_records')
        .where('batchId', isEqualTo: batchId)
        .orderBy('date')
        .get();
    return snapshot.docs
        .map((d) => PoultryMortalityRecord.fromMap(d.id, d.data()))
        .toList();
  }

  /* ─────────────── ADD / SAVE RECORDS ─────────────── */

  @override
  Future<void> addHealthRecord(PoultryHealthRecord record) async {
    await _db
        .collection('poultry_health_records')
        .doc(record.id)
        .set(record.toMap());
  }

  @override
  Future<void> addFeedingRecord(PoultryFeedingRecord record) async {
    await _db
        .collection('poultry_feeding_records')
        .doc(record.id)
        .set(record.toMap());
  }

  @override
  Future<void> addGrowthRecord(PoultryGrowthRecord record) async {
    await _db
        .collection('poultry_growth_records')
        .doc(record.id)
        .set(record.toMap());
  }

  @override
  Future<void> addVetRecord(PoultryVetRecord record) async {
    await _db
        .collection('poultry_vet_records')
        .doc(record.id)
        .set(record.toMap());
  }

  @override
  Future<void> addExitRecord(PoultryExitRecord record) async {
    final batchRef = _db.collection('poultry_batches').doc(record.batchId);

    debugPrint(
      'FirestorePoultryRepository.addExitRecord: starting for ${record.id} (batch=${record.batchId}, qty=${record.quantity})',
    );

    try {
      await _db.runTransaction((tx) async {
        final exitRef = _db.collection('poultry_exit_records').doc(record.id);
        tx.set(exitRef, record.toMap());

        // If birds exited, decrement currentCount safely
        final batchSnap = await tx.get(batchRef);
        if (!batchSnap.exists) return;

        final data = batchSnap.data() as Map<String, dynamic>;
        final current =
            (data['currentCount'] as num?)?.toInt() ??
            (data['initialCount'] as num?)?.toInt() ??
            0;
        final newCount = (current - record.quantity).clamp(0, 1 << 30);
        tx.update(batchRef, {
          'currentCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint(
        'FirestorePoultryRepository.addExitRecord: transaction committed for ${record.id}',
      );
    } catch (e, st) {
      debugPrint(
        'FirestorePoultryRepository.addExitRecord: transaction ERROR for ${record.id}: $e\n$st',
      );
      // Fallback: try non-transactional write + atomic decrement
      try {
        debugPrint(
          'Attempting fallback non-transactional write for exit ${record.id}',
        );
        final exitRef = _db.collection('poultry_exit_records').doc(record.id);
        await exitRef.set(record.toMap());
        await batchRef.update({
          'currentCount': FieldValue.increment(-record.quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('Fallback write/update succeeded for exit ${record.id}');
      } catch (fallbackErr, fallbackSt) {
        debugPrint(
          'Fallback also failed for exit ${record.id}: $fallbackErr\n$fallbackSt',
        );
        rethrow;
      }
    }
  }

  Future<void> addProductionRecord(PoultryProductionRecord record) async {
    await addPoultryProductionRecord(record);
  }

  @override
  Future<void> addPoultryProductionRecord(
    PoultryProductionRecord record,
  ) async {
    await _db
        .collection('poultry_production_records')
        .doc(record.id)
        .set(record.toMap());
  }

  @override
  Future<void> updatePoultryProductionRecord(
    PoultryProductionRecord record,
  ) async {
    await _db
        .collection('poultry_production_records')
        .doc(record.id)
        .update(record.toMap());
  }

  @override
  Future<void> addRationPlan(PoultryRationPlan plan) async {
    await _db.collection('poultry_ration_plans').doc(plan.id).set(plan.toMap());
  }

  @override
  Future<void> deleteRationPlan(String planId) async {
    await _db.collection('poultry_ration_plans').doc(planId).delete();
  }

  Future<void> addMortalityRecord(PoultryMortalityRecord record) async {
    await addPoultryMortalityRecord(record);
  }

  @override
  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record) async {
    final batchRef = _db.collection('poultry_batches').doc(record.batchId);

    debugPrint(
      'FirestorePoultryRepository.addPoultryMortalityRecord: starting for ${record.id} (batch=${record.batchId}, deaths=${record.deaths})',
    );

    try {
      // Use a transaction to write the mortality record and decrement currentCount
      await _db.runTransaction((tx) async {
        // Write mortality record
        final mortRef = _db
            .collection('poultry_mortality_records')
            .doc(record.id);
        tx.set(mortRef, record.toMap());

        // Read batch and safely decrement currentCount
        final batchSnap = await tx.get(batchRef);
        if (!batchSnap.exists) return;

        final data = batchSnap.data() as Map<String, dynamic>;
        final current =
            (data['currentCount'] as num?)?.toInt() ??
            (data['initialCount'] as num?)?.toInt() ??
            0;
        final newCount = (current - record.deaths).clamp(0, 1 << 30);
        tx.update(batchRef, {
          'currentCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      debugPrint(
        'FirestorePoultryRepository.addPoultryMortalityRecord: transaction committed for ${record.id}',
      );
    } catch (e, st) {
      debugPrint(
        'FirestorePoultryRepository.addPoultryMortalityRecord: transaction ERROR for ${record.id}: $e\n$st',
      );
      // Fallback: try non-transactional write + atomic decrement using FieldValue.increment
      try {
        debugPrint(
          'Attempting fallback non-transactional write for ${record.id}',
        );
        final mortRef = _db
            .collection('poultry_mortality_records')
            .doc(record.id);
        await mortRef.set(record.toMap());

        // Use atomic increment to decrement currentCount by deaths (safe without transaction)
        await batchRef.update({
          'currentCount': FieldValue.increment(-record.deaths),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('Fallback write/update succeeded for ${record.id}');
      } catch (fallbackErr, fallbackSt) {
        debugPrint(
          'Fallback also failed for ${record.id}: $fallbackErr\n$fallbackSt',
        );
        rethrow; // let caller see the error so UI shows SnackBar
      }
    }
  }

  @override
  Future<void> addPoultryBatch(PoultryBatch batch) async {
    await _db.collection('poultry_batches').doc(batch.id).set(batch.toMap());
  }

  @override
  Future<PoultryBatch?> getPoultryBatch(String batchId) async {
    try {
      final doc = await _db.collection('poultry_batches').doc(batchId).get();
      if (!doc.exists) return null;
      return PoultryBatch.fromDocument(doc);
    } catch (e) {
      debugPrint('FirestorePoultryRepository.getPoultryBatch error: $e');
      return null;
    }
  }

  /* ─────────────── PROFIT / LOSS / COST ─────────────── */

  Future<double> getTotalFeedCost(String batchId) async {
    final records = await getFeedingRecords(batchId);
    double total = 0.0;
    for (final r in records) {
      final cost =
          double.tryParse(r.notes?.split('Total Cost: R').last ?? '') ?? 0;
      total += cost;
    }
    return total;
  }

  @override
  Future<double> getTotalVetCost(String batchId) async {
    final records = await getVetRecords(batchId);
    return records.fold<double>(
      0.0,
      (total, record) => total + (record.cost ?? 0.0),
    );
  }

  Future<double> getTotalExitIncome(String batchId) async {
    final records = await getExitRecords(batchId);
    double total = 0.0;
    for (final r in records) {
      total += r.income ?? 0;
    }
    return total;
  }

  /* ─────────────── EGG STOCK TRANSACTIONS ─────────────── */

  @override
  Future<List<EggStockTransaction>> listEggStockTransactions(String batchId) async {
    final snapshot = await _db
        .collection('egg_stock_transactions')
        .where('batchId', isEqualTo: batchId)
        .orderBy('transactionDate', descending: true)
        .get();
    return snapshot.docs
        .map((d) => EggStockTransaction.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Future<void> addEggStockTransaction(EggStockTransaction transaction) async {
    await _db
        .collection('egg_stock_transactions')
        .doc(transaction.id)
        .set(transaction.toMap());
  }

  @override
  Future<void> deleteEggStockTransaction(String transactionId) async {
    await _db.collection('egg_stock_transactions').doc(transactionId).delete();
  }

  @override
  Future<EggStockSummary> calculateEggStockSummary(String batchId) async {
    // Get all production records
    final productionRecords = await listPoultryProductionRecords(batchId);
    
    int totalCollected = 0;
    int totalSoldFromDaily = 0;
    int totalBrokenFromDaily = 0;
    
    for (final record in productionRecords) {
      totalCollected += record.eggsCollected;
      totalSoldFromDaily += record.eggsSold;
      totalBrokenFromDaily += record.eggsBroken;
    }
    
    // Get all stock transactions
    final transactions = await listEggStockTransactions(batchId);
    
    int totalSoldFromStock = 0;
    int totalBrokenFromStock = 0;
    
    for (final transaction in transactions) {
      if (transaction.type == 'sale') {
        totalSoldFromStock += transaction.quantity;
      } else if (transaction.type == 'breakage') {
        totalBrokenFromStock += transaction.quantity;
      }
    }
    
    return EggStockSummary(
      totalCollected: totalCollected,
      totalSoldFromDaily: totalSoldFromDaily,
      totalBrokenFromDaily: totalBrokenFromDaily,
      totalSoldFromStock: totalSoldFromStock,
      totalBrokenFromStock: totalBrokenFromStock,
    );
  }
}
