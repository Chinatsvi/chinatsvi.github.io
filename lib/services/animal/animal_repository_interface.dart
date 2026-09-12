import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/breeding_record.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/models/animal/vet_visit.dart';
import 'package:agribased/models/animal/activity_log_record.dart';
import 'package:agribased/models/animal/milk_production_record.dart';
import 'package:agribased/models/poultry/poultry_feed_entry.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';

abstract class AnimalRepository {
  // Animal operations
  Future<List<Animal>> listAnimals();
  Future<Animal?> getAnimal(String id);
  Future<void> addAnimal(Animal animal);
  Future<void> updateAnimal(Animal animal);
  Future<void> deleteAnimal(String id);

  // Feeding operations
  Future<List<FeedingEntry>> listFeedingEntries(String animalId);
  Future<void> addFeedingEntry(FeedingEntry entry);
  Future<void> updateFeedingEntry(FeedingEntry entry);

  // Health record operations
  Future<List<HealthRecord>> listHealthRecords(String animalId);
  Future<void> addHealthRecord(HealthRecord record);
  Future<void> updateHealthRecord(HealthRecord record);

  // Breeding record operations
  Future<List<BreedingRecord>> listBreedingRecords(String animalId);
  Future<void> addBreedingRecord(BreedingRecord record);
  Future<void> updateBreedingRecord(BreedingRecord record);

  // Growth record operations
  Future<List<GrowthRecord>> listGrowthRecords(String animalId);
  Future<void> addGrowthRecord(GrowthRecord record);

  // Exit record operations
  Future<List<ExitRecord>> listExitRecords(String animalId);
  Future<void> addExitRecord(ExitRecord record);

  // Vet visit operations
  Future<List<VetVisit>> listVetVisits(String animalId);
  Future<void> addVetVisit(VetVisit visit);
  Future<void> updateVetVisit(VetVisit visit);
  Future<void> deleteVetVisit(String id);

  // Activity log operations
  Future<List<ActivityLogRecord>> listActivityLogs(String animalId);
  Future<void> addActivityLog(ActivityLogRecord record);
  Future<void> updateActivityLog(ActivityLogRecord record);

  // Milk production operations
  Future<List<MilkProductionRecord>> listMilkProductionRecords(String animalId);
  Future<void> addMilkProductionRecord(MilkProductionRecord record);
  Future<void> updateMilkProductionRecord(MilkProductionRecord record);
  Future<void> deleteMilkProductionRecord(String animalId, String recordId);

  // Poultry production operations
  Future<List<PoultryProductionRecord>> listPoultryProductionRecords(
    String batchId,
  );
  Future<void> addPoultryProductionRecord(PoultryProductionRecord record);
  Future<List<PoultryMortalityRecord>> listPoultryMortalityRecords(
    String batchId,
  );
  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record);

  // Poultry batch operations
  Future<void> addPoultryBatch(PoultryBatch batch);

  // Poultry feed operations
  Future<List<PoultryFeedEntry>> listPoultryFeedEntries(String batchId);
  Future<void> addPoultryFeedEntry(PoultryFeedEntry entry);
  Future<void> updatePoultryFeedEntry(PoultryFeedEntry entry);
  Future<void> deletePoultryFeedEntry(String id);
}

