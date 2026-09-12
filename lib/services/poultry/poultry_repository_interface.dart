// lib/services/poultry/poultry_repository_interface.dart

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

abstract class PoultryRepository {
  Future<List<PoultryHealthRecord>> getHealthRecords(String batchId);
  Future<List<PoultryFeedingRecord>> getFeedingRecords(String batchId);
  Future<List<PoultryGrowthRecord>> getGrowthRecords(String batchId);
  Future<List<PoultryVetRecord>> getVetRecords(String batchId);
  Future<List<PoultryExitRecord>> getExitRecords(String batchId);
  Future<List<PoultryProductionRecord>> getProductionRecords(String batchId);
  Future<List<PoultryRationPlan>> getRationPlans(String batchId);

  // Health Records
  Future<void> addHealthRecord(PoultryHealthRecord record);

  // Mortality Records
  Future<List<PoultryMortalityRecord>> listPoultryMortalityRecords(
    String batchId,
  );
  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record);

  // Production Records
  Future<List<PoultryProductionRecord>> listPoultryProductionRecords(
    String batchId,
  );
  Future<void> addPoultryProductionRecord(PoultryProductionRecord record);
  Future<void> updatePoultryProductionRecord(PoultryProductionRecord record);

  // Feeding Records
  Future<void> addFeedingRecord(PoultryFeedingRecord record);

  // Growth Records
  Future<void> addGrowthRecord(PoultryGrowthRecord record);

  // Poultry Batch
  Future<void> addPoultryBatch(PoultryBatch batch);
  Future<PoultryBatch?> getPoultryBatch(String batchId);

  // Exit Records
  Future<void> addExitRecord(PoultryExitRecord record);

  // Vet Records
  Future<void> addVetRecord(PoultryVetRecord record);

  // Ration Plans
  Future<void> addRationPlan(PoultryRationPlan plan);
  Future<void> deleteRationPlan(String planId);

  // Utility Methods
  Future<double> getTotalVetCost(String batchId);

  // Egg Stock Transactions (Sales/Breakages from accumulated stock)
  Future<List<EggStockTransaction>> listEggStockTransactions(String batchId);
  Future<void> addEggStockTransaction(EggStockTransaction transaction);
  Future<void> deleteEggStockTransaction(String transactionId);
  Future<EggStockSummary> calculateEggStockSummary(String batchId);
}
