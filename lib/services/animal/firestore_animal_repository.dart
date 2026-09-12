// lib/service/animal/firestore_animal_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/breeding_record.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/models/animal/vet_visit.dart';
import 'package:agribased/models/animal/activity_log_record.dart';
import 'package:agribased/models/animal/milk_production_record.dart';
import 'package:agribased/models/poultry/poultry_feed_entry.dart';
import 'package:agribased/models/poultry/poultry_production_record.dart';
import 'package:agribased/models/poultry/poultry_batch.dart';
import 'package:agribased/models/poultry/poultry_mortality_record.dart';
import 'animal_repository_interface.dart';

class FirestoreAnimalRepository implements AnimalRepository {
  // Singleton instance
  static final FirestoreAnimalRepository _instance =
      FirestoreAnimalRepository._internal();
  factory FirestoreAnimalRepository() => _instance;
  FirestoreAnimalRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _farmerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('No authenticated farmer');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _animals =>
      _db.collection('farmers').doc(_farmerId).collection('animals');

  CollectionReference<Map<String, dynamic>> _poultryFeedEntries(
    String batchId,
  ) =>
      _db.collection('poultry_batches').doc(batchId).collection('feed_entries');

  CollectionReference<Map<String, dynamic>> _poultryMortalityRecords(
    String batchId,
  ) => _db
      .collection('poultry_batches')
      .doc(batchId)
      .collection('mortality_records');

  DocumentReference<Map<String, dynamic>> _animalDoc(String id) =>
      _animals.doc(id);

  // Poultry batch operations
  @override
  Future<void> addPoultryBatch(PoultryBatch batch) async {
    try {
      await _db.collection('poultry_batches').doc(batch.id).set(batch.toMap());
    } catch (e) {
      throw Exception('Failed to add poultry batch: $e');
    }
  }

  @override
  Future<void> addPoultryFeedEntry(PoultryFeedEntry entry) async {
    try {
      await _poultryFeedEntries(entry.batchId).add(entry.toMap());
    } catch (e) {
      throw Exception('Failed to add poultry feed entry: $e');
    }
  }

  @override
  Future<void> updatePoultryFeedEntry(PoultryFeedEntry entry) async {
    try {
      await _poultryFeedEntries(
        entry.batchId,
      ).doc(entry.id).update(entry.toMap());
    } catch (e) {
      throw Exception('Failed to update poultry feed entry: $e');
    }
  }

  @override
  Future<void> deletePoultryFeedEntry(String id) async {
    try {
      // First get the entry to get the batchId
      final querySnapshot = await _db
          .collectionGroup('feed_entries')
          .where(FieldPath.documentId, isEqualTo: id)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final batchId = doc.reference.parent.parent?.id;
        if (batchId != null) {
          await _poultryFeedEntries(batchId).doc(id).delete();
        } else {
          throw Exception('Could not determine batch for feed entry');
        }
      } else {
        throw Exception('Feed entry not found');
      }
    } catch (e) {
      throw Exception('Failed to delete poultry feed entry: $e');
    }
  }

  CollectionReference<Map<String, dynamic>> _poultryProductionRecords(
    String batchId,
  ) => _db
      .collection('poultryBatches')
      .doc(batchId)
      .collection('productionRecords');

  // ---------- Poultry Mortality Records ----------
  @override
  Future<void> addPoultryMortalityRecord(PoultryMortalityRecord record) async {
    try {
      await _poultryMortalityRecords(
        record.batchId,
      ).doc(record.id).set(record.toMap());
    } catch (e) {
      throw Exception('Failed to add poultry mortality record: $e');
    }
  }

  // ---------- Poultry Feed Entries ----------
  @override
  Future<List<PoultryFeedEntry>> listPoultryFeedEntries(String batchId) async {
    try {
      final snapshot = await _poultryFeedEntries(
        batchId,
      ).orderBy('date', descending: true).get();
      return snapshot.docs
          .map((doc) => PoultryFeedEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch poultry feed entries: $e');
    }
  }

  // ---------- Animals ----------
  @override
  Future<List<Animal>> listAnimals() async {
    final snap = await _animals.get();
    return snap.docs.map((doc) {
      final d = doc.data();
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
        purpose: d['purpose'] as String?,
        initialFlockSize: (d['initialFlockSize'] as num?)?.toInt(),
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
    }).toList();
  }

  @override
  Future<Animal?> getAnimal(String id) async {
    final doc = await _animalDoc(id).get();
    if (!doc.exists) return null;
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
      purpose: d['purpose'] as String?,
      initialFlockSize: (d['initialFlockSize'] as num?)?.toInt(),
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

  @override
  Future<void> addAnimal(Animal animal) => upsertAnimal(animal);

  @override
  Future<void> updateAnimal(Animal animal) => upsertAnimal(animal);

  Future<void> upsertAnimal(Animal animal) async {
    await _animalDoc(animal.id).set({
      'animalTags': animal.animalTags,
      'species': animal.species,
      'breed': animal.breed,
      'ageMonths': animal.ageMonths,
      'photoUrl': animal.photoUrl,
      'sex': animal.sex,
      'maleCount': animal.maleCount,
      'femaleCount': animal.femaleCount,
      'targetWeightKg': animal.targetWeightKg,
      'purpose': animal.purpose,
      'initialFlockSize': animal.initialFlockSize,
      'totalCount': animal.totalCount,
      'totalCost': animal.totalCost,
      'currency': animal.currency,
      'notes': animal.notes,
      'createdAt': animal.createdAt,
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteAnimal(String id) async {
    await _animalDoc(id).delete();
  }

  // ---------- Health Logs ----------
  @override
  Future<List<HealthRecord>> listHealthRecords(String animalId) async {
    try {
      final snap = await _animalDoc(animalId).collection('healthLogs').get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            // Handle both old and new data formats
            if (data.containsKey('cost') && data.containsKey('deleted')) {
              return HealthRecord.fromMap({
                ...data,
                'id': doc.id,
                'animalId': animalId,
              });
            } else {
              // Legacy data format - create with defaults
              return HealthRecord(
                id: doc.id,
                animalId: animalId,
                date: (data['date'] as Timestamp).toDate(),
                type: data['type'] as String? ?? 'Unknown',
                product: data['product'] as String?,
                notes: data['notes'] as String?,
                cost: data['cost'] != null
                    ? (data['cost'] as num).toDouble()
                    : null,
                deleted: false, // Default for legacy data
              );
            }
          })
          .where((record) => !record.deleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addHealthRecord(HealthRecord record) async {
    await _animalDoc(
      record.animalId,
    ).collection('healthLogs').doc(record.id).set(record.toMap());
  }

  // ---------- Breeding Logs ----------
  @override
  Future<List<BreedingRecord>> listBreedingRecords(String animalId) async {
    try {
      final snap = await _animalDoc(animalId).collection('breedingLogs').get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            // Handle both old and new data formats
            if (data.containsKey('cost') && data.containsKey('deleted')) {
              return BreedingRecord.fromMap({
                ...data,
                'id': doc.id,
                'animalId': animalId,
              });
            } else {
              // Legacy data format - create with defaults
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
                cost: data['cost'] != null
                    ? (data['cost'] as num).toDouble()
                    : null,
                deleted: false, // Default for legacy data
              );
            }
          })
          .where((record) => !record.deleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addBreedingRecord(BreedingRecord record) async {
    await _animalDoc(
      record.animalId,
    ).collection('breedingLogs').doc(record.id).set(record.toMap());
  }

  // ---------- Feeding Entries ----------
  @override
  Future<List<FeedingEntry>> listFeedingEntries(String animalId) async {
    try {
      final snap = await _animalDoc(
        animalId,
      ).collection('feedingSchedule').get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            // Handle both old and new data formats
            if (data.containsKey('deleted')) {
              return FeedingEntry.fromMap({
                ...data,
                'id': doc.id,
                'animalId': animalId,
              });
            } else {
              // Legacy data format - create with defaults
              return FeedingEntry(
                id: doc.id,
                animalId: animalId,
                date: (data['date'] as Timestamp).toDate(),
                feedType: data['feedType'] as String? ?? 'Unknown',
                quantityKg: (data['quantityKg'] as num?)?.toDouble() ?? 0.0,
                cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
                notes: data['notes'] as String?,
                deleted: false, // Default for legacy data
                growthRecordId: data['growthRecordId'] as String?,
                healthRecordId: data['healthRecordId'] as String?,
                breedingRecordId: data['breedingRecordId'] as String?,
                aiTips: data['aiTips'] != null
                    ? List<String>.from(data['aiTips'] as List)
                    : null,
              );
            }
          })
          .where((entry) => !entry.deleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addFeedingEntry(FeedingEntry entry) async {
    await _animalDoc(
      entry.animalId,
    ).collection('feedingSchedule').doc(entry.id).set(entry.toMap());
  }

  // ---------- Growth Records ----------
  @override
  Future<List<GrowthRecord>> listGrowthRecords(String animalId) async {
    final snap = await _animalDoc(animalId).collection('growthRecords').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return GrowthRecord(
        id: doc.id,
        animalId: animalId,
        date: (d['date'] as Timestamp).toDate(),
        weightKg: (d['weightKg'] as num).toDouble(),
      );
    }).toList();
  }

  @override
  Future<void> addGrowthRecord(GrowthRecord record) async {
    await _animalDoc(record.animalId)
        .collection('growthRecords')
        .doc(record.id)
        .set({'date': record.date, 'weightKg': record.weightKg});
  }

  // ---------- Exit Records ----------
  @override
  Future<List<ExitRecord>> listExitRecords(String animalId) async {
    final snap = await _animalDoc(animalId).collection('exitRecords').get();
    return snap.docs.map((doc) {
      final d = doc.data();
      final dateValue = d['date'];
      return ExitRecord(
        id: doc.id,
        animalId: animalId,
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
    }).toList();
  }

  @override
  Future<void> addExitRecord(ExitRecord record) async {
    await _animalDoc(
      record.animalId,
    ).collection('exitRecords').doc(record.id).set(record.toMap());
  }

  // ---------- Vet Visits ----------
  @override
  Future<List<VetVisit>> listVetVisits(String animalId) async {
    try {
      final snap = await _animalDoc(animalId).collection('vetVisits').get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            // Handle both old and new data formats
            if (data.containsKey('cost') && data.containsKey('deleted')) {
              return VetVisit.fromMap({
                ...data,
                'id': doc.id,
                'animalId': animalId,
              });
            } else {
              // Legacy data format - create with defaults
              return VetVisit(
                id: doc.id,
                animalId: animalId,
                visitDate: (data['visitDate'] as Timestamp).toDate(),
                vetName: data['vetName'] as String? ?? 'Unknown',
                notes: data['notes'] as String?,
                cost: data['cost'] != null
                    ? (data['cost'] as num).toDouble()
                    : null,
                deleted: false, // Default for legacy data
              );
            }
          })
          .where((visit) => !visit.deleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addVetVisit(VetVisit visit) async {
    await _animalDoc(
      visit.animalId,
    ).collection('vetVisits').doc(visit.id).set(visit.toMap());
  }

  @override
  Future<void> updateVetVisit(VetVisit visit) async {
    await _animalDoc(
      visit.animalId,
    ).collection('vetVisits').doc(visit.id).update(visit.toMap());
  }

  @override
  Future<void> deleteVetVisit(String id) async {
    // Note: This method is provided for interface completeness
    // In practice, we use soft delete via updateVetVisit with deleted flag
    throw UnimplementedError(
      'Use updateVetVisit with deleted flag for soft delete',
    );
  }

  @override
  Future<List<ActivityLogRecord>> listActivityLogs(String animalId) async {
    try {
      final snap = await _animalDoc(animalId).collection('activityLogs').get();
      return snap.docs
          .map((doc) {
            final data = doc.data();
            return ActivityLogRecord.fromMap({
              ...data,
              'id': doc.id,
              'animalId': animalId,
            });
          })
          .where((record) => !record.deleted)
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addActivityLog(ActivityLogRecord record) async {
    await _animalDoc(record.animalId)
        .collection('activityLogs')
        .doc(record.id)
        .set(record.toMap());
  }

  @override
  Future<void> updateActivityLog(ActivityLogRecord record) async {
    await _animalDoc(record.animalId)
        .collection('activityLogs')
        .doc(record.id)
        .update(record.toMap());
  }

  @override
  Future<void> updateHealthRecord(HealthRecord record) async {
    await _animalDoc(
      record.animalId,
    ).collection('healthLogs').doc(record.id).update(record.toMap());
  }

  @override
  Future<void> updateFeedingEntry(FeedingEntry entry) async {
    await _animalDoc(
      entry.animalId,
    ).collection('feedingSchedule').doc(entry.id).update(entry.toMap());
  }

  @override
  Future<void> updateBreedingRecord(BreedingRecord record) async {
    await _animalDoc(
      record.animalId,
    ).collection('breedingLogs').doc(record.id).update(record.toMap());
  }

  // ---------- Poultry Production Records ----------
  @override
  Future<List<PoultryProductionRecord>> listPoultryProductionRecords(
    String batchId,
  ) async {
    final snap = await _db
        .collection('poultryBatches')
        .doc(batchId)
        .collection('productionRecords')
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return PoultryProductionRecord(
        id: doc.id,
        batchId: batchId,
        date: (data['date'] as Timestamp).toDate(),
        eggsCollected: data['eggsCollected'] as int? ?? 0,
      );
    }).toList();
  }

  @override
  Future<List<PoultryMortalityRecord>> listPoultryMortalityRecords(
    String batchId,
  ) async {
    final snap = await _db
        .collection('poultryBatches')
        .doc(batchId)
        .collection('mortalityRecords')
        .orderBy('date', descending: true)
        .get();

    return snap.docs.map((doc) {
      final data = doc.data();
      return PoultryMortalityRecord(
        id: doc.id,
        batchId: batchId,
        date: (data['date'] as Timestamp).toDate(),
        deaths: data['deaths'] as int? ?? 0,
        notes: data['notes'] as String?,
      );
    }).toList();
  }

  // ---------- Milk Production Records ----------
  @override
  Future<List<MilkProductionRecord>> listMilkProductionRecords(
    String animalId,
  ) async {
    try {
      final snap = await _animalDoc(animalId)
          .collection('milkProduction')
          .orderBy('date', descending: true)
          .get();
      return snap.docs
          .map((doc) => MilkProductionRecord.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> addMilkProductionRecord(MilkProductionRecord record) async {
    try {
      await _animalDoc(record.animalId)
          .collection('milkProduction')
          .doc(record.id)
          .set(record.toMap());
    } catch (e) {
      throw Exception('Failed to add milk production record: $e');
    }
  }

  @override
  Future<void> updateMilkProductionRecord(MilkProductionRecord record) async {
    try {
      await _animalDoc(record.animalId)
          .collection('milkProduction')
          .doc(record.id)
          .update(record.toMap());
    } catch (e) {
      throw Exception('Failed to update milk production record: $e');
    }
  }

  @override
  Future<void> deleteMilkProductionRecord(String animalId, String recordId) async {
    try {
      await _animalDoc(animalId)
          .collection('milkProduction')
          .doc(recordId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete milk production record: $e');
    }
  }

  // ---------- Poultry Production Records ----------
  @override
  Future<void> addPoultryProductionRecord(
    PoultryProductionRecord record,
  ) async {
    try {
      await _poultryProductionRecords(
        record.batchId,
      ).doc(record.id).set(record.toMap());
    } catch (e) {
      throw Exception('Failed to add poultry production record: $e');
    }
  }
}
