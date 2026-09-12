import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanHistoryScreen extends StatelessWidget {
  const PlanHistoryScreen({super.key});

  Future<void> deletePlan(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection('plan_book')
        .doc(docId)
        .delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Plan deleted')));
  }

  void editPlan(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final notes = data['notes'] ?? '';
    final controller = TextEditingController(text: notes);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Notes'),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('plan_book')
                    .doc(doc.id)
                    .update({'notes': controller.text});
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Plan updated')));
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String buildTitle(Map<String, dynamic> data) {
    if (data.containsKey('notes')) return data['notes'];
    if (data.containsKey('activity_type'))
      return 'Activity: ${data['activity_type']}';
    if (data.containsKey('budget_item'))
      return 'Budget: ${data['budget_item']}';
    if (data.containsKey('inventory_item'))
      return 'Inventory: ${data['inventory_item']}';
    return 'Unnamed Plan';
  }

  String buildSubtitle(Map<String, dynamic> data) {
    final timestamp = data['timestamp'];
    final date = timestamp != null
        ? timestamp.toString().split('T').first
        : 'Unknown date';

    if (data.containsKey('activity_date')) {
      final actDate =
          data['activity_date']?.toString().split('T').first ?? 'not set';
      return 'Activity Date: $actDate';
    }

    if (data.containsKey('amount')) {
      return 'Amount: ${data['amount']}';
    }

    if (data.containsKey('quantity')) {
      return 'Quantity: ${data['quantity']}';
    }

    return 'Saved on $date';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan History'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('plan_book')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No plans found'));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.menu_book, color: Colors.blue),
                  title: Text(buildTitle(data)),
                  subtitle: Text(buildSubtitle(data)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') editPlan(context, doc);
                      if (value == 'delete') deletePlan(context, doc.id);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
