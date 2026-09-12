import 'package:flutter/material.dart';
import 'verification_request_screen.dart'; // ✅ import your request screen

class VerificationIntroScreen extends StatelessWidget {
  const VerificationIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Badge'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Icon(Icons.verified, color: Colors.green, size: 80),
            ),
            const SizedBox(height: 16),

            const Text(
              'Why get verified?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            const Text(
              'A green verification badge shows that your farming account is authentic and trusted. '
              'Verified farmers gain more visibility, trust from buyers, and credibility when sharing advice.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            const Text(
              'Benefits:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _benefit('Green tick next to your name'),
            _benefit('More trust from other farmers'),
            _benefit('Priority visibility in the app'),
            _benefit('Access to premium features'),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.all(14),
                ),
                onPressed: () {
                  // ✅ Navigate directly to the request screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VerificationRequestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward, color: Colors.white),
                label: const Text(
                  'Apply for Verification',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _benefit(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}