import 'package:flutter/material.dart';
import 'package:agribased/services/optimized_user_service.dart';

class UserServiceTestScreen extends StatelessWidget {
  const UserServiceTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UserService Test')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔍 Test OptimizedUserService', 
                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: () async {
                  // Test cache
                  OptimizedUserCache.clearCache();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cache cleared!')),
                  );
                },
                child: const Text('1. Clear Cache'),
              ),
              
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: () async {
                  // Test profile update
                  try {
                    await OptimizedUserService.updateProfile(
                      uid: 'T2cKaLJOVnQrIJveMqLqGKudzps1', // Your user ID
                      name: 'TEST NAME UPDATE',
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                child: const Text('2. Test Profile Update'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(height: 20),
              
              const Text('📊 What to check:'),
              const Text('• Profile header should update'),
              const Text('• Posts should update'),
              const Text('• Post creation should use new name'),
              const Text('• Cache should be updated'),
            ],
          ),
        ),
      ),
    );
  }
}
