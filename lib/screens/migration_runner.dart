import 'package:flutter/material.dart';
import 'package:agribased/utils/comment_field_migration.dart';

class MigrationRunner extends StatelessWidget {
  const MigrationRunner({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Run Migration'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            print('Starting migration...');
            await CommentFieldMigration.migrateAllComments();
            print('Migration completed!');
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Migration completed! Check console for details.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          child: const Text('Run Comment Migration'),
        ),
      ),
    );
  }
}
