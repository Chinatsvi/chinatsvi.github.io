import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const _historyGreen = Color(0xFF2E7D32);

class FarmCalculatorRecord {
  final String id;
  final String calculatorType;
  final String title;
  final Map<String, String> inputs;
  final String result;
  final String? details;
  final DateTime createdAt;

  const FarmCalculatorRecord({
    required this.id,
    required this.calculatorType,
    required this.title,
    required this.inputs,
    required this.result,
    required this.details,
    required this.createdAt,
  });

  factory FarmCalculatorRecord.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};
    final rawInputs = data['inputs'];
    final inputs = rawInputs is Map
        ? rawInputs.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          )
        : <String, String>{};
    final timestamp = data['createdAt'];
    return FarmCalculatorRecord(
      id: document.id,
      calculatorType: data['calculatorType']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Farm record',
      inputs: inputs,
      result: data['result']?.toString() ?? '',
      details: data['details']?.toString(),
      createdAt: timestamp is Timestamp ? timestamp.toDate() : DateTime.now(),
    );
  }
}

class FarmCalculatorHistoryService {
  FarmCalculatorHistoryService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> _records(String uid) =>
      _firestore
          .collection('farmers')
          .doc(uid)
          .collection('farm_calculator_records');

  static Stream<List<FarmCalculatorRecord>> watch(String calculatorType) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _records(uid)
        .where('calculatorType', isEqualTo: calculatorType)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(FarmCalculatorRecord.fromDocument).toList(),
        );
  }

  static Future<void> save({
    required String calculatorType,
    required String title,
    required Map<String, String> inputs,
    required String result,
    String? details,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _records(uid).add({
      'calculatorType': calculatorType,
      'title': title,
      'inputs': inputs,
      'result': result,
      'details': details,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> delete(String recordId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _records(uid).doc(recordId).delete();
  }
}

class FarmCalculatorHistory extends StatelessWidget {
  final String calculatorType;

  const FarmCalculatorHistory({super.key, required this.calculatorType});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FarmCalculatorRecord>>(
      stream: FarmCalculatorHistoryService.watch(calculatorType),
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <FarmCalculatorRecord>[];
        if (records.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Saved records',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _historyGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Long press a record to delete it.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ...records.map((record) => _RecordCard(record: record)),
          ],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  final FarmCalculatorRecord record;

  const _RecordCard({required this.record});

  Future<void> _showDeleteMenu(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.red),
          title: const Text('Delete this record'),
          subtitle: const Text('This only removes it from your account.'),
          onTap: () async {
            Navigator.pop(sheetContext);
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete record?'),
                content: const Text(
                  'This saved calculation cannot be recovered.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              await FarmCalculatorHistoryService.delete(record.id);
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('d MMM yyyy, h:mm a').format(record.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade100),
      ),
      child: InkWell(
        onLongPress: () => _showDeleteMenu(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_note, color: _historyGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      record.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _historyGreen,
                      ),
                    ),
                  ),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                record.result,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (record.details?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  record.details!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: record.inputs.entries
                    .map(
                      (entry) => Text(
                        '${entry.key}: ${entry.value}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
