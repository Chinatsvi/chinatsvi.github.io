import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/models/poultry/poultry_vet_record.dart';
import 'package:agribased/models/poultry/poultry_exit_record.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_ration_plan.dart';

abstract class PoultryRepository {
  // FETCH
  Future<List<PoultryHealthRecord>> getHealthRecords(String batchId);
  Future<List<PoultryFeedingRecord>> getFeedingRecords(String batchId);
  Future<List<PoultryGrowthRecord>> getGrowthRecords(String batchId);
  Future<List<PoultryVetRecord>> getVetRecords(String batchId);
  Future<List<PoultryExitRecord>> getExitRecords(String batchId);
  Future<List<PoultryProductionRecord>> getProductionRecords(String batchId);
  Future<List<PoultryRationPlan>> getRationPlans(String batchId);

  // ADD / SAVE
  Future<void> addHealthRecord(PoultryHealthRecord record);
  Future<void> addFeedingRecord(PoultryFeedingRecord record);
  Future<void> addGrowthRecord(PoultryGrowthRecord record);
  Future<void> addVetRecord(PoultryVetRecord record);
  Future<void> addExitRecord(PoultryExitRecord record);
  Future<void> addProductionRecord(PoultryProductionRecord record);
  Future<void> addRationPlan(PoultryRationPlan plan);

  // UTILITY for PROFIT / LOSS
  Future<double> getTotalFeedCost(String batchId);
  Future<double> getTotalVetCost(String batchId);
  Future<double> getTotalExitIncome(String batchId); // income from sales/slaughter
}
