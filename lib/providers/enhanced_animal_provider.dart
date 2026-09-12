import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/models/animal/vet_visit.dart';
import 'package:agribased/models/animal/breeding_record.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/models/animal/activity_log_record.dart';
import 'package:agribased/models/animal/milk_production_record.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/poultry_feed_entry.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'package:agribased/services/animal/animal_repository_interface.dart';
import 'package:agribased/services/animal/firestore_animal_repository.dart';

// Enhanced Animal Repository with Stream support
class EnhancedAnimalRepository implements AnimalRepository {
  final AnimalRepository _baseRepo = FirestoreAnimalRepository();

  Stream<List<Animal>> watchAnimals() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(user.uid)
        .collection('animals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_animalFromDoc).toList());
  }

  Stream<List<HealthRecord>> watchHealthRecords(String animalId) {
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('animals')
        .doc(animalId)
        .collection('healthLogs')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _healthRecordFromDoc(doc, animalId))
              .where((record) => !record.deleted)
              .toList(),
        );
  }

  Stream<List<FeedingEntry>> watchFeedingEntries(String animalId) {
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('animals')
        .doc(animalId)
        .collection('feedingSchedule')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _feedingEntryFromDoc(doc, animalId))
              .where((entry) => !entry.deleted)
              .toList(),
        );
  }

  Stream<List<GrowthRecord>> watchGrowthRecords(String animalId) {
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('animals')
        .doc(animalId)
        .collection('growthRecords')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_growthRecordFromDoc).toList());
  }

  Stream<List<VetVisit>> watchVetVisits(String animalId) {
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('animals')
        .doc(animalId)
        .collection('vetVisits')
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _vetVisitFromDoc(doc, animalId))
              .where((visit) => !visit.deleted)
              .toList(),
        );
  }

  Stream<List<BreedingRecord>> watchBreedingLogs(String animalId) {
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('animals')
        .doc(animalId)
        .collection('breedingLogs')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => _breedingRecordFromDoc(doc, animalId))
              .where((record) => !record.deleted)
              .toList(),
        );
  }

  Stream<List<ExitRecord>> watchExitRecords(String animalId) {
    return FirebaseFirestore.instance
        .collection('farmers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('animals')
        .doc(animalId)
        .collection('exitRecords')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_exitRecordFromDoc).toList());
  }

  // Helper methods for converting documents to models
  Animal _animalFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Animal(
      id: doc.id,
      animalTags: (d['animalTags'] is List)
          ? (d['animalTags'] as List).whereType<String>().toList()
          : const [],
      species: d['species'] ?? '',
      breed: d['breed'] ?? '',
      ageMonths: (d['ageMonths'] ?? 0) as int,
      photoUrl: d['photoUrl'],
      sex: d['sex'],
      maleCount: (d['maleCount'] as num?)?.toInt(),
      femaleCount: (d['femaleCount'] as num?)?.toInt(),
      targetWeightKg: (d['targetWeightKg'] as num?)?.toDouble(),
      initialFlockSize: (d['initialFlockSize'] as num?)?.toInt(),
      purpose: d['purpose'] as String?,
      totalCount: (d['totalCount'] as num?)?.toInt() ?? 1,
      totalCost: (d['totalCost'] as num?)?.toDouble() ?? 0.0,
      currency: d['currency'] as String?,
      notes: d['notes'] as String?,
      createdAt: (d['createdAt'] is Timestamp)
          ? (d['createdAt'] as Timestamp).toDate()
          : ((d['createdAt'] is String)
              ? (DateTime.tryParse(d['createdAt']) ?? DateTime.now())
              : DateTime.now()),
    );
  }

  HealthRecord _healthRecordFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String animalId,
  ) {
    final data = doc.data()!;
    if (data.containsKey('cost') && data.containsKey('deleted')) {
      return HealthRecord.fromMap({
        ...data,
        'id': doc.id,
        'animalId': animalId,
      });
    } else {
      return HealthRecord(
        id: doc.id,
        animalId: animalId,
        date: (data['date'] as Timestamp).toDate(),
        type: data['type'] as String? ?? 'Unknown',
        product: data['product'] as String?,
        notes: data['notes'] as String?,
        cost: data['cost'] != null ? (data['cost'] as num).toDouble() : null,
        deleted: false,
        aiTips: data['aiTips'] != null
            ? List<String>.from(data['aiTips'] as List)
            : null,
      );
    }
  }

  FeedingEntry _feedingEntryFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String animalId,
  ) {
    final data = doc.data()!;
    if (data.containsKey('deleted')) {
      return FeedingEntry.fromMap({
        ...data,
        'id': doc.id,
        'animalId': animalId,
      });
    } else {
      return FeedingEntry(
        id: doc.id,
        animalId: animalId,
        date: (data['date'] as Timestamp).toDate(),
        feedType: data['feedType'] as String? ?? 'Unknown',
        quantityKg: (data['quantityKg'] as num?)?.toDouble() ?? 0.0,
        cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
        notes: data['notes'] as String?,
        deleted: false,
        growthRecordId: data['growthRecordId'] as String?,
        healthRecordId: data['healthRecordId'] as String?,
        breedingRecordId: data['breedingRecordId'] as String?,
        aiTips: data['aiTips'] != null
            ? List<String>.from(data['aiTips'] as List)
            : null,
      );
    }
  }

  GrowthRecord _growthRecordFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return GrowthRecord(
      id: doc.id,
      animalId: doc.reference.parent.parent!.id,
      date: (d['date'] as Timestamp).toDate(),
      weightKg: (d['weightKg'] as num).toDouble(),
    );
  }

  VetVisit _vetVisitFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String animalId,
  ) {
    final data = doc.data()!;
    if (data.containsKey('cost') && data.containsKey('deleted')) {
      return VetVisit.fromMap({...data, 'id': doc.id, 'animalId': animalId});
    } else {
      return VetVisit(
        id: doc.id,
        animalId: animalId,
        visitDate: (data['visitDate'] as Timestamp).toDate(),
        vetName: data['vetName'] as String? ?? 'Unknown',
        notes: data['notes'] as String?,
        cost: data['cost'] != null ? (data['cost'] as num).toDouble() : null,
        deleted: false,
      );
    }
  }

  BreedingRecord _breedingRecordFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
    String animalId,
  ) {
    final data = doc.data()!;
    if (data.containsKey('cost') && data.containsKey('deleted')) {
      return BreedingRecord.fromMap({
        ...data,
        'id': doc.id,
        'animalId': animalId,
      });
    } else {
      return BreedingRecord(
        id: doc.id,
        animalId: animalId,
        date: (data['date'] as Timestamp).toDate(),
        method: data['method'] as String? ?? 'Unknown',
        sireId: data['sireId'] as String?,
        sireName: data['sireName'] as String?,
        expectedDueDate: data['expectedDueDate'] != null
            ? (data['expectedDueDate'] as Timestamp).toDate()
            : null,
        notes: data['notes'] as String?,
        cost: data['cost'] != null ? (data['cost'] as num).toDouble() : null,
        deleted: false,
      );
    }
  }

  ExitRecord _exitRecordFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final dateValue = d['date'];
    return ExitRecord(
      id: doc.id,
      animalId: doc.reference.parent.parent!.id,
      date: dateValue is Timestamp
          ? dateValue.toDate()
          : (dateValue is String
              ? (DateTime.tryParse(dateValue) ?? DateTime.now())
              : DateTime.now()),
      reason: d['reason'] ?? 'sale',
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
      animalTag: d['animalTag'] as String?,
      sex: d['sex'] as String?,
      maleQuantity: (d['maleQuantity'] as num?)?.toInt(),
      femaleQuantity: (d['femaleQuantity'] as num?)?.toInt(),
      salePrice: (d['salePrice'] as num?)?.toDouble(),
      notes: d['notes'] as String?,
    );
  }

  // Delegate other methods to base repository
  @override
  Future<List<Animal>> listAnimals() => _baseRepo.listAnimals();

  @override
  Future<Animal?> getAnimal(String id) => _baseRepo.getAnimal(id);

  @override
  Future<void> addAnimal(Animal animal) => _baseRepo.addAnimal(animal);

  @override
  Future<void> updateAnimal(Animal animal) => _baseRepo.updateAnimal(animal);

  @override
  Future<void> deleteAnimal(String id) => _baseRepo.deleteAnimal(id);

  @override
  Future<List<HealthRecord>> listHealthRecords(String animalId) =>
      _baseRepo.listHealthRecords(animalId);

  @override
  Future<void> addHealthRecord(HealthRecord record) =>
      _baseRepo.addHealthRecord(record);

  @override
  Future<void> updateHealthRecord(HealthRecord record) =>
      _baseRepo.updateHealthRecord(record);

  @override
  Future<List<BreedingRecord>> listBreedingRecords(String animalId) =>
      _baseRepo.listBreedingRecords(animalId);

  @override
  Future<void> addBreedingRecord(BreedingRecord record) =>
      _baseRepo.addBreedingRecord(record);

  @override
  Future<void> updateBreedingRecord(BreedingRecord record) =>
      _baseRepo.updateBreedingRecord(record);

  @override
  Future<List<FeedingEntry>> listFeedingEntries(String animalId) =>
      _baseRepo.listFeedingEntries(animalId);

  @override
  Future<void> addFeedingEntry(FeedingEntry entry) =>
      _baseRepo.addFeedingEntry(entry);

  @override
  Future<void> updateFeedingEntry(FeedingEntry entry) =>
      _baseRepo.updateFeedingEntry(entry);

  @override
  Future<List<GrowthRecord>> listGrowthRecords(String animalId) =>
      _baseRepo.listGrowthRecords(animalId);

  @override
  Future<void> addGrowthRecord(GrowthRecord record) =>
      _baseRepo.addGrowthRecord(record);

  @override
  Future<List<ExitRecord>> listExitRecords(String animalId) =>
      _baseRepo.listExitRecords(animalId);

  @override
  Future<void> addExitRecord(ExitRecord record) =>
      _baseRepo.addExitRecord(record);

  @override
  Future<List<VetVisit>> listVetVisits(String animalId) =>
      _baseRepo.listVetVisits(animalId);

  @override
  Future<void> addVetVisit(VetVisit visit) => _baseRepo.addVetVisit(visit);

  @override
  Future<void> updateVetVisit(VetVisit visit) =>
      _baseRepo.updateVetVisit(visit);

  @override
  Future<void> deleteVetVisit(String id) => _baseRepo.deleteVetVisit(id);

  @override
  Future<List<ActivityLogRecord>> listActivityLogs(String animalId) =>
      _baseRepo.listActivityLogs(animalId);

  @override
  Future<void> addActivityLog(ActivityLogRecord record) =>
      _baseRepo.addActivityLog(record);

  @override
  Future<void> updateActivityLog(ActivityLogRecord record) =>
      _baseRepo.updateActivityLog(record);

  // Milk production methods
  @override
  Future<List<MilkProductionRecord>> listMilkProductionRecords(
    String animalId,
  ) => _baseRepo.listMilkProductionRecords(animalId);

  @override
  Future<void> addMilkProductionRecord(MilkProductionRecord record) =>
      _baseRepo.addMilkProductionRecord(record);

  @override
  Future<void> updateMilkProductionRecord(MilkProductionRecord record) =>
      _baseRepo.updateMilkProductionRecord(record);

  @override
  Future<void> deleteMilkProductionRecord(String animalId, String recordId) =>
      _baseRepo.deleteMilkProductionRecord(animalId, recordId);

  // Poultry-related methods
  @override
  Future<void> addPoultryBatch(PoultryBatch batch) =>
      _baseRepo.addPoultryBatch(batch);

  @override
  Future<void> addPoultryFeedEntry(PoultryFeedEntry entry) =>
      _baseRepo.addPoultryFeedEntry(entry);

  @override
  Future<void> updatePoultryFeedEntry(PoultryFeedEntry entry) =>
      _baseRepo.updatePoultryFeedEntry(entry);

  @override
  Future<void> deletePoultryFeedEntry(String id) =>
      _baseRepo.deletePoultryFeedEntry(id);

  @override
  Future<List<PoultryFeedEntry>> listPoultryFeedEntries(String batchId) =>
      _baseRepo.listPoultryFeedEntries(batchId);

  @override
  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record) =>
      _baseRepo.addPoultryMortalityRecord(record);

  @override
  Future<List<PoultryMortalityRecord>> listPoultryMortalityRecords(
    String batchId,
  ) => _baseRepo.listPoultryMortalityRecords(batchId);

  @override
  Future<void> addPoultryProductionRecord(PoultryProductionRecord record) =>
      _baseRepo.addPoultryProductionRecord(record);

  @override
  Future<List<PoultryProductionRecord>> listPoultryProductionRecords(
    String batchId,
  ) => _baseRepo.listPoultryProductionRecords(batchId);
}

// Provider for enhanced animal repository
final enhancedAnimalRepositoryProvider = Provider<EnhancedAnimalRepository>((
  ref,
) {
  return EnhancedAnimalRepository();
});

// Provider for animals list
final animalsProvider = StreamProvider<List<Animal>>((ref) {
  final repository = ref.watch(enhancedAnimalRepositoryProvider);
  return repository.watchAnimals();
});
