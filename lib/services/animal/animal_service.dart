// lib/service/animal/animal_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agribased/models/animal/animal.dart';
import 'package:agribased/models/animal/health_record.dart';
import 'package:agribased/models/animal/breeding_record.dart';
import 'package:agribased/models/animal/feeding_entry.dart';
import 'package:agribased/models/animal/growth_record.dart';
import 'package:agribased/models/animal/exit_record.dart';
import 'package:agribased/models/animal/vet_visit.dart';

class AnimalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _farmerId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated farmer');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _animalsColl() =>
      _db.collection('farmers').doc(_farmerId).collection('animals');

  DocumentReference<Map<String, dynamic>> _animalDoc(String animalId) =>
      _animalsColl().doc(animalId);

  // ---------- Animals ----------
  Future<List<Animal>> listAnimals() async {
    final snapshot = await _animalsColl()
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_animalFromDoc).toList();
  }

  Stream<List<Animal>> watchAnimals() {
    return _animalsColl()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_animalFromDoc).toList());
  }

  Future<Animal?> getAnimal(String id) async {
    final doc = await _animalDoc(id).get();
    if (!doc.exists) return null;
    return _animalFromDoc(doc);
  }

  Future<void> upsertAnimal(Animal animal) async {
    await _animalDoc(animal.id).set({
      'animalTags': animal.animalTags,
      'species': animal.species,
      'breed': animal.breed,
      'ageMonths': animal.ageMonths,
      'photoUrl': animal.photoUrl,
      'sex': animal.sex,
      'createdAt': animal.createdAt,
    }, SetOptions(merge: true));
  }

  Future<void> deleteAnimal(String id) async {
    // Optional: cascade delete subcollections (manual)
    // Health logs
    await _deleteAll(_animalDoc(id).collection('healthLogs'));
    await _deleteAll(_animalDoc(id).collection('breedingLogs'));
    await _deleteAll(_animalDoc(id).collection('feedingSchedule'));
    await _deleteAll(_animalDoc(id).collection('growthRecords'));
    await _deleteAll(_animalDoc(id).collection('exitRecords'));
    await _deleteAll(_animalDoc(id).collection('vetVisits'));
    await _animalDoc(id).delete();
  }

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
      createdAt: (d['createdAt'] as Timestamp).toDate(),
    );
  }

  // ---------- Health Logs ----------
  CollectionReference<Map<String, dynamic>> _healthLogs(String animalId) =>
      _animalDoc(animalId).collection('healthLogs');

  Future<List<HealthRecord>> listHealthLogs(String animalId) async {
    final snap = await _healthLogs(
      animalId,
    ).orderBy('date', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return HealthRecord(
        id: doc.id,
        animalId: animalId,
        date: (d['date'] as Timestamp).toDate(),
        type: d['type'] ?? '',
        product: d['product'],
        notes: d['notes'],
      );
    }).toList();
  }

  Stream<List<HealthRecord>> watchHealthLogs(String animalId) {
    return _healthLogs(animalId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return HealthRecord(
              id: doc.id,
              animalId: animalId,
              date: (d['date'] as Timestamp).toDate(),
              type: d['type'] ?? '',
              product: d['product'],
              notes: d['notes'],
            );
          }).toList(),
        );
  }

  Future<void> addHealthLog(HealthRecord record) async {
    await _healthLogs(record.animalId).doc(record.id).set({
      'date': record.date,
      'type': record.type,
      'product': record.product,
      'notes': record.notes,
    });
  }

  Future<void> deleteHealthLog(String animalId, String logId) async {
    await _healthLogs(animalId).doc(logId).delete();
  }

  // ---------- Breeding Logs ----------
  CollectionReference<Map<String, dynamic>> _breedingLogs(String animalId) =>
      _animalDoc(animalId).collection('breedingLogs');

  Future<List<BreedingRecord>> listBreedingLogs(String animalId) async {
    final snap = await _breedingLogs(
      animalId,
    ).orderBy('heatDate', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return BreedingRecord(
        id: doc.id,
        animalId: animalId,
        date: (d['date'] as Timestamp).toDate(),
        method: d['method'] as String,
        expectedDueDate: (d['expectedDueDate'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }

  Stream<List<BreedingRecord>> watchBreedingLogs(String animalId) {
    return _breedingLogs(animalId)
        .orderBy('heatDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return BreedingRecord(
              id: doc.id,
              animalId: animalId,
              date: (d['date'] as Timestamp).toDate(),
              method: d['method'] as String,
              expectedDueDate: (d['expectedDueDate'] as Timestamp?)?.toDate(),
            );
          }).toList(),
        );
  }

  Future<void> addBreedingLog(BreedingRecord record) async {
    await _breedingLogs(record.animalId).doc(record.id).set({
      'date': record.date,
      'method': record.method,
      'sireId': record.sireId,
      'sireName': record.sireName,
      'expectedDueDate': record.expectedDueDate,
      'notes': record.notes,
    });
  }

  Future<void> deleteBreedingLog(String animalId, String logId) async {
    await _breedingLogs(animalId).doc(logId).delete();
  }

  // ---------- Feeding Schedule ----------
  CollectionReference<Map<String, dynamic>> _feedingSchedule(String animalId) =>
      _animalDoc(animalId).collection('feedingSchedule');

  Future<List<FeedingEntry>> listFeedingEntries(String animalId) async {
    final snap = await _feedingSchedule(
      animalId,
    ).orderBy('date', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return FeedingEntry(
        id: doc.id,
        animalId: animalId,
        date: (d['date'] as Timestamp).toDate(),
        feedType: d['feedType'] ?? '',
        quantityKg: (d['quantityKg'] as num).toDouble(),
        cost: (d['cost'] as num).toDouble(),
        notes: d['notes'],
      );
    }).toList();
  }

  Stream<List<FeedingEntry>> watchFeedingEntries(String animalId) {
    return _feedingSchedule(animalId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return FeedingEntry(
              id: doc.id,
              animalId: animalId,
              date: (d['date'] as Timestamp).toDate(),
              feedType: d['feedType'] ?? '',
              quantityKg: (d['quantityKg'] as num).toDouble(),
              cost: (d['cost'] as num).toDouble(),
              notes: d['notes'],
            );
          }).toList(),
        );
  }

  Future<void> addFeedingEntry(FeedingEntry entry) async {
    await _feedingSchedule(entry.animalId).doc(entry.id).set({
      'date': entry.date,
      'feedType': entry.feedType,
      'quantityKg': entry.quantityKg,
      'cost': entry.cost,
      'notes': entry.notes,
    });
  }

  Future<void> deleteFeedingEntry(String animalId, String entryId) async {
    await _feedingSchedule(animalId).doc(entryId).delete();
  }

  // ---------- Growth Records ----------
  CollectionReference<Map<String, dynamic>> _growthRecords(String animalId) =>
      _animalDoc(animalId).collection('growthRecords');

  Future<List<GrowthRecord>> listGrowthRecords(String animalId) async {
    final snap = await _growthRecords(
      animalId,
    ).orderBy('date', descending: true).get();
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

  Stream<List<GrowthRecord>> watchGrowthRecords(String animalId) {
    return _growthRecords(animalId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return GrowthRecord(
              id: doc.id,
              animalId: animalId,
              date: (d['date'] as Timestamp).toDate(),
              weightKg: (d['weightKg'] as num).toDouble(),
            );
          }).toList(),
        );
  }

  Future<void> addGrowthRecord(GrowthRecord record) async {
    await _growthRecords(
      record.animalId,
    ).doc(record.id).set({'date': record.date, 'weightKg': record.weightKg});
  }

  Future<void> deleteGrowthRecord(String animalId, String recordId) async {
    await _growthRecords(animalId).doc(recordId).delete();
  }

  // ---------- Exit Records ----------
  CollectionReference<Map<String, dynamic>> _exitRecords(String animalId) =>
      _animalDoc(animalId).collection('exitRecords');

  Future<List<ExitRecord>> listExitRecords(String animalId) async {
    final snap = await _exitRecords(
      animalId,
    ).orderBy('date', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data();
      final dateValue = d['date'];
      return ExitRecord(
        id: doc.id,
        animalId: animalId,
        date: dateValue is Timestamp
            ? dateValue.toDate()
            : DateTime.parse(dateValue as String),
        reason: d['reason'] ?? '',
        quantity: (d['quantity'] as num?)?.toInt() ?? 1,
        salePrice: (d['salePrice'] as num?)?.toDouble(),
        notes: d['notes'],
      );
    }).toList();
  }

  Stream<List<ExitRecord>> watchExitRecords(String animalId) {
    return _exitRecords(animalId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return ExitRecord(
              id: doc.id,
              animalId: animalId,
              date: (d['date'] as Timestamp).toDate(),
              reason: d['reason'] ?? '',
              salePrice: (d['salePrice'] as num?)?.toDouble(),
              notes: d['notes'],
            );
          }).toList(),
        );
  }

  Future<void> addExitRecord(ExitRecord record) async {
    await _exitRecords(record.animalId).doc(record.id).set(record.toMap());
  }

  Future<void> deleteExitRecord(String animalId, String recordId) async {
    await _exitRecords(animalId).doc(recordId).delete();
  }

  // ---------- Vet Visits ----------
  CollectionReference<Map<String, dynamic>> _vetVisits(String animalId) =>
      _animalDoc(animalId).collection('vetVisits');

  Future<List<VetVisit>> listVetVisits(String animalId) async {
    final snap = await _vetVisits(
      animalId,
    ).orderBy('visitDate', descending: true).get();
    return snap.docs.map((doc) {
      final d = doc.data();
      return VetVisit(
        id: doc.id,
        animalId: animalId,
        visitDate: (d['visitDate'] as Timestamp).toDate(),
        vetName: d['vetName'] ?? '',
        notes: d['notes'],
      );
    }).toList();
  }

  Stream<List<VetVisit>> watchVetVisits(String animalId) {
    return _vetVisits(animalId)
        .orderBy('visitDate', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return VetVisit(
              id: doc.id,
              animalId: animalId,
              visitDate: (d['visitDate'] as Timestamp).toDate(),
              vetName: d['vetName'] ?? '',
              notes: d['notes'],
            );
          }).toList(),
        );
  }

  Future<void> addVetVisit(VetVisit visit) async {
    await _vetVisits(visit.animalId).doc(visit.id).set({
      'visitDate': visit.visitDate,
      'vetName': visit.vetName,
      'notes': visit.notes,
    });
  }

  Future<void> deleteVetVisit(String animalId, String visitId) async {
    await _vetVisits(animalId).doc(visitId).delete();
  }

  // ---------- Utility ----------
  Future<void> _deleteAll(
    CollectionReference<Map<String, dynamic>> coll,
  ) async {
    final batch = _db.batch();
    final snap = await coll.get();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
