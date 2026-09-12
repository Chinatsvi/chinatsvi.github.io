import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/models/animal/vet_visit.dart';
import 'package:agribased/models/animal/breeding_record.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/poultry_health_record.dart';
import 'package:agribased/models/poultry/poultry_feeding_record.dart';
import 'package:agribased/models/poultry/poultry_growth_record.dart';
import 'package:agribased/models/poultry/poultry_vet_record.dart';
import 'package:agribased/models/poultry/poultry_exit_record.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_ration_plan.dart';
import 'package:agribased/providers/enhanced_animal_provider.dart';
import 'package:agribased/providers/enhanced_poultry_provider.dart';

// Unified Livestock Data Model
class LivestockData {
  final Animal? animal;
  final PoultryBatch? poultryBatch;
  final List<HealthRecord> healthRecords;
  final List<FeedingEntry> feedingEntries;
  final List<GrowthRecord> growthRecords;
  final List<VetVisit> vetVisits;
  final List<BreedingRecord> breedingRecords;
  final List<ExitRecord> exitRecords;
  final List<PoultryHealthRecord> poultryHealthRecords;
  final List<PoultryFeedingRecord> poultryFeedingRecords;
  final List<PoultryGrowthRecord> poultryGrowthRecords;
  final List<PoultryVetRecord> poultryVetRecords;
  final List<PoultryExitRecord> poultryExitRecords;
  final List<PoultryMortalityRecord> poultryMortalityRecords;
  final List<PoultryProductionRecord> poultryProductionRecords;
  final List<PoultryRationPlan> poultryRationPlans;

  const LivestockData({
    this.animal,
    this.poultryBatch,
    this.healthRecords = const [],
    this.feedingEntries = const [],
    this.growthRecords = const [],
    this.vetVisits = const [],
    this.breedingRecords = const [],
    this.exitRecords = const [],
    this.poultryHealthRecords = const [],
    this.poultryFeedingRecords = const [],
    this.poultryGrowthRecords = const [],
    this.poultryVetRecords = const [],
    this.poultryExitRecords = const [],
    this.poultryMortalityRecords = const [],
    this.poultryProductionRecords = const [],
    this.poultryRationPlans = const [],
  });

  bool get isPoultry => animal?.species.toLowerCase() == 'poultry';
  bool get isLayer => poultryBatch?.isLayer ?? false;
  bool get isBroiler => poultryBatch?.isBroiler ?? false;

  LivestockData copyWith({
    Animal? animal,
    PoultryBatch? poultryBatch,
    List<HealthRecord>? healthRecords,
    List<FeedingEntry>? feedingEntries,
    List<GrowthRecord>? growthRecords,
    List<VetVisit>? vetVisits,
    List<BreedingRecord>? breedingRecords,
    List<ExitRecord>? exitRecords,
    List<PoultryHealthRecord>? poultryHealthRecords,
    List<PoultryFeedingRecord>? poultryFeedingRecords,
    List<PoultryGrowthRecord>? poultryGrowthRecords,
    List<PoultryVetRecord>? poultryVetRecords,
    List<PoultryExitRecord>? poultryExitRecords,
    List<PoultryMortalityRecord>? poultryMortalityRecords,
    List<PoultryProductionRecord>? poultryProductionRecords,
    List<PoultryRationPlan>? poultryRationPlans,
  }) {
    return LivestockData(
      animal: animal ?? this.animal,
      poultryBatch: poultryBatch ?? this.poultryBatch,
      healthRecords: healthRecords ?? this.healthRecords,
      feedingEntries: feedingEntries ?? this.feedingEntries,
      growthRecords: growthRecords ?? this.growthRecords,
      vetVisits: vetVisits ?? this.vetVisits,
      breedingRecords: breedingRecords ?? this.breedingRecords,
      exitRecords: exitRecords ?? this.exitRecords,
      poultryHealthRecords: poultryHealthRecords ?? this.poultryHealthRecords,
      poultryFeedingRecords:
          poultryFeedingRecords ?? this.poultryFeedingRecords,
      poultryGrowthRecords: poultryGrowthRecords ?? this.poultryGrowthRecords,
      poultryVetRecords: poultryVetRecords ?? this.poultryVetRecords,
      poultryExitRecords: poultryExitRecords ?? this.poultryExitRecords,
      poultryMortalityRecords:
          poultryMortalityRecords ?? this.poultryMortalityRecords,
      poultryProductionRecords:
          poultryProductionRecords ?? this.poultryProductionRecords,
      poultryRationPlans: poultryRationPlans ?? this.poultryRationPlans,
    );
  }
}

// Centralized Livestock Service
class LivestockService {
  final EnhancedAnimalRepository _animalRepo;
  final EnhancedPoultryRepository _poultryRepo;

  LivestockService({
    required EnhancedAnimalRepository animalRepo,
    required EnhancedPoultryRepository poultryRepo,
  }) : _animalRepo = animalRepo,
       _poultryRepo = poultryRepo;

  // Stream all data for a specific animal/batch
  Stream<LivestockData> watchLivestockData(String animalId) async* {
    // Get basic animal data
    final animal = await _animalRepo.getAnimal(animalId);
    if (animal == null) return;

    PoultryBatch? poultryBatch;
    if (animal.species.toLowerCase() == 'poultry') {
      // Get poultry batch data
      await for (final batch in _poultryRepo.watchPoultryBatch(animalId)) {
        poultryBatch = batch;

        // Stream all related data
        final healthStream = _animalRepo.watchHealthRecords(animalId);
        final feedingStream = _animalRepo.watchFeedingEntries(animalId);
        final growthStream = _animalRepo.watchGrowthRecords(animalId);
        final vetStream = _animalRepo.watchVetVisits(animalId);
        final breedingStream = _animalRepo.watchBreedingLogs(animalId);
        final exitStream = _animalRepo.watchExitRecords(animalId);

        // Poultry-specific streams
        final poultryHealthStream = _poultryRepo.watchHealthRecords(animalId);
        final poultryFeedingStream = _poultryRepo.watchFeedingRecords(animalId);
        final poultryGrowthStream = _poultryRepo.watchGrowthRecords(animalId);
        final poultryVetStream = _poultryRepo.watchVetRecords(animalId);
        final poultryExitStream = _poultryRepo.watchExitRecords(animalId);
        final poultryMortalityStream = _poultryRepo.watchMortalityRecords(
          animalId,
        );
        final poultryProductionStream = _poultryRepo.watchProductionRecords(
          animalId,
        );
        final poultryRationStream = _poultryRepo.watchRationPlans(animalId);

        // Combine all streams - simplified approach
        await for (final healthRecords in healthStream) {
          await for (final feedingEntries in feedingStream) {
            await for (final growthRecords in growthStream) {
              await for (final vetVisits in vetStream) {
                await for (final breedingRecords in breedingStream) {
                  await for (final exitRecords in exitStream) {
                    await for (final poultryHealthRecords
                        in poultryHealthStream) {
                      await for (final poultryFeedingRecords
                          in poultryFeedingStream) {
                        await for (final poultryGrowthRecords
                            in poultryGrowthStream) {
                          await for (final poultryVetRecords
                              in poultryVetStream) {
                            await for (final poultryExitRecords
                                in poultryExitStream) {
                              await for (final poultryMortalityRecords
                                  in poultryMortalityStream) {
                                await for (final poultryProductionRecords
                                    in poultryProductionStream) {
                                  await for (final poultryRationPlans
                                      in poultryRationStream) {
                                    yield LivestockData(
                                      animal: animal,
                                      poultryBatch: poultryBatch,
                                      healthRecords: healthRecords,
                                      feedingEntries: feedingEntries,
                                      growthRecords: growthRecords,
                                      vetVisits: vetVisits,
                                      breedingRecords: breedingRecords,
                                      exitRecords: exitRecords,
                                      poultryHealthRecords:
                                          poultryHealthRecords,
                                      poultryFeedingRecords:
                                          poultryFeedingRecords,
                                      poultryGrowthRecords:
                                          poultryGrowthRecords,
                                      poultryVetRecords: poultryVetRecords,
                                      poultryExitRecords: poultryExitRecords,
                                      poultryMortalityRecords:
                                          poultryMortalityRecords,
                                      poultryProductionRecords:
                                          poultryProductionRecords,
                                      poultryRationPlans: poultryRationPlans,
                                    );
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    } else {
      // Non-poultry animals - only stream animal-specific data
      final healthStream = _animalRepo.watchHealthRecords(animalId);
      final feedingStream = _animalRepo.watchFeedingEntries(animalId);
      final growthStream = _animalRepo.watchGrowthRecords(animalId);
      final vetStream = _animalRepo.watchVetVisits(animalId);
      final breedingStream = _animalRepo.watchBreedingLogs(animalId);
      final exitStream = _animalRepo.watchExitRecords(animalId);

      await for (final healthRecords in healthStream) {
        await for (final feedingEntries in feedingStream) {
          await for (final growthRecords in growthStream) {
            await for (final vetVisits in vetStream) {
              await for (final breedingRecords in breedingStream) {
                await for (final exitRecords in exitStream) {
                  yield LivestockData(
                    animal: animal,
                    healthRecords: healthRecords,
                    feedingEntries: feedingEntries,
                    growthRecords: growthRecords,
                    vetVisits: vetVisits,
                    breedingRecords: breedingRecords,
                    exitRecords: exitRecords,
                  );
                }
              }
            }
          }
        }
      }
    }
  }

  // CRUD operations that trigger updates
  Future<void> addHealthRecord(HealthRecord record) async {
    await _animalRepo.addHealthRecord(record);
  }

  Future<void> addFeedingEntry(FeedingEntry entry) async {
    await _animalRepo.addFeedingEntry(entry);
  }

  Future<void> addGrowthRecord(GrowthRecord record) async {
    await _animalRepo.addGrowthRecord(record);
  }

  Future<void> addVetVisit(VetVisit visit) async {
    await _animalRepo.addVetVisit(visit);
  }

  Future<void> addBreedingRecord(BreedingRecord record) async {
    await _animalRepo.addBreedingRecord(record);
  }

  Future<void> addExitRecord(ExitRecord record) async {
    await _animalRepo.addExitRecord(record);
  }

  // Poultry-specific CRUD operations
  Future<void> addPoultryHealthRecord(PoultryHealthRecord record) async {
    await _poultryRepo.addHealthRecord(record);
  }

  Future<void> addPoultryFeedingRecord(PoultryFeedingRecord record) async {
    await _poultryRepo.addFeedingRecord(record);
  }

  Future<void> addPoultryGrowthRecord(PoultryGrowthRecord record) async {
    await _poultryRepo.addGrowthRecord(record);
  }

  Future<void> addPoultryVetRecord(PoultryVetRecord record) async {
    await _poultryRepo.addVetRecord(record);
  }

  Future<void> addPoultryExitRecord(PoultryExitRecord record) async {
    await _poultryRepo.addExitRecord(record);
  }

  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record) async {
    await _poultryRepo.addPoultryMortalityRecord(record);
  }

  Future<void> addPoultryProductionRecord(
    PoultryProductionRecord record,
  ) async {
    await _poultryRepo.addPoultryProductionRecord(record);
  }

  Future<void> addPoultryRationPlan(PoultryRationPlan plan) async {
    await _poultryRepo.addRationPlan(plan);
  }

  // Event-driven calculations
  double calculateTotalFeedCost(String animalId) {
    // Implementation for calculating total feed cost
    // This will automatically update when feeding records change
    return 0.0; // Placeholder
  }

  double calculateMortalityRate(String batchId) {
    // Implementation for calculating mortality rate
    // This will automatically update when mortality records change
    return 0.0; // Placeholder
  }

  double calculateProfitLoss(String animalId) {
    // Implementation for calculating profit/loss
    // This will automatically update when any relevant record changes
    return 0.0; // Placeholder
  }
}

// Riverpod providers
final livestockServiceProvider = Provider<LivestockService>((ref) {
  return LivestockService(
    animalRepo: ref.watch(enhancedAnimalRepositoryProvider),
    poultryRepo: ref.watch(enhancedPoultryRepositoryProvider),
  );
});

final livestockDataProvider = StreamProvider.family<LivestockData, String>((
  ref,
  animalId,
) {
  final service = ref.watch(livestockServiceProvider);
  return service.watchLivestockData(animalId);
});

// Event bus for cross-tab communication
class LivestockEventBus {
  static final _controller = StreamController<LivestockEvent>.broadcast();

  static Stream<LivestockEvent> get events => _controller.stream;

  static void emit(LivestockEvent event) {
    _controller.add(event);
  }

  static void dispose() {
    _controller.close();
  }
}

abstract class LivestockEvent {
  final String animalId;
  final DateTime timestamp;

  LivestockEvent(this.animalId) : timestamp = DateTime.now();
}

class HealthRecordAddedEvent extends LivestockEvent {
  final HealthRecord record;

  HealthRecordAddedEvent(this.record) : super(record.animalId);
}

class FeedingEntryAddedEvent extends LivestockEvent {
  final FeedingEntry entry;

  FeedingEntryAddedEvent(this.entry) : super(entry.animalId);
}

class MortalityRecordedEvent extends LivestockEvent {
  final PoultryMortalityRecord record;

  MortalityRecordedEvent(this.record) : super(record.batchId);
}

class WeightUpdatedEvent extends LivestockEvent {
  final GrowthRecord record;

  WeightUpdatedEvent(this.record) : super(record.animalId);
}
