import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/app/routes/app_routes.dart';
import 'package:agribased/screens/welcome_screen.dart';

class FarmerAuthGateway extends StatelessWidget {
  const FarmerAuthGateway({super.key});

  Future<bool> _farmerProfileExists(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    return doc.exists;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // ✅ FIXED STREAM
      stream: FirebaseAuth.instance.idTokenChanges(),
      builder: (context, snapshot) {

        // 🔥 CRITICAL: WAIT until Firebase finishes restoring session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 🔥 EXTRA SAFETY (VERY IMPORTANT)
        if (!snapshot.hasData) {
          // But wait a bit before showing welcome (avoid flicker)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data!;

        return FutureBuilder<bool>(
          future: _farmerProfileExists(user.uid),
          builder: (context, profileSnapshot) {

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (profileSnapshot.data == false) {
              Future.microtask(() async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, AppRoutes.signup);
                }
              });

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // ✅ GO TO COMMUNITY
            Future.microtask(() {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.community,
              );
            });

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    );
  }
}