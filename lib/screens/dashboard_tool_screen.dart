import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/feature_button.dart';
import '../../services/cache/profile_cache_service.dart';
import '../../services/secure_auth_service.dart';
import 'books/guidebook_screen.dart';
import 'image_diagnosis/diagnosis_chat_screen.dart';
import 'academy/academy_screen.dart';
import 'crop/crop_management_screen.dart';
import 'crop_calendar/crop_calendar_screen.dart';
import 'farm_works_screen.dart';
import 'animal/animal_management_screen.dart';
import 'jobs/jobs_screen.dart';
import 'profile/farmer_model.dart';

class DashboardToolScreen extends StatefulWidget {
  const DashboardToolScreen({super.key});

  @override
  State<DashboardToolScreen> createState() => _DashboardToolScreenState();
}

class _DashboardToolScreenState extends State<DashboardToolScreen> {
  late Future<Map<String, dynamic>?> _farmerDataFuture;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _farmerDataFuture = _getFarmerData();
    // Listen to auth changes - when internet returns and Firebase reconnects,
    // refresh to fetch fresh data from Firestore
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        debugPrint('🔥 [DASHBOARD] Auth reconnected, refreshing data...');
        setState(() {
          _farmerDataFuture = _getFarmerData();
        });
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _getFarmerData() async {
    // Get stored user ID - we need this regardless of online/offline
    final secureAuth = SecureAuthService();
    final storedUserId = await secureAuth.getStoredUserId();

    // Try Firebase first (when online)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          // Cache for offline use
          await ProfileCacheService.cacheProfile(user.uid, doc.data()!);
          // Include userId in the returned data
          final data = Map<String, dynamic>.from(doc.data()!);
          data['_userId'] = user.uid;
          return data;
        }
      } catch (e) {
        debugPrint('⚠️ [DASHBOARD] Firestore error: $e');
      }
    }

    // Fallback to cached profile for offline mode
    if (storedUserId != null) {
      try {
        final cachedProfile = await Future<Map<String, dynamic>?>.sync(
          () => ProfileCacheService.getCachedProfile(storedUserId),
        ).timeout(const Duration(seconds: 2));
        if (cachedProfile != null) {
          debugPrint('✅ [DASHBOARD] Using cached profile for offline mode');
          // Include userId in the returned data
          final data = Map<String, dynamic>.from(cachedProfile);
          data['_userId'] = storedUserId;
          return data;
        }
      } catch (e) {
        debugPrint('⚠️ [DASHBOARD] Cache error: $e');
      }

      // 🔥 CRITICAL: Even if cache is empty, return minimal data so tools show
      // The user is logged in (we have storedUserId), just show tools
      debugPrint(
        '✅ [DASHBOARD] No cache but userId exists - showing tools with defaults',
      );
      return {'_userId': storedUserId, 'name': 'Farmer', 'user_name': 'Farmer'};
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _farmerDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final farmerData = snapshot.data;
        if (farmerData == null) {
          return const Scaffold(
            body: Center(child: Text("No farmer logged in")),
          );
        }

        // Get userId from the data (works for both online and offline)
        final userId = farmerData['_userId'] as String?;

        if (userId == null) {
          return const Scaffold(
            body: Center(child: Text("No farmer logged in")),
          );
        }

        final farmer = FarmerModel.fromMap(farmerData, userId);

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.green.shade700,
            title: Text(
              'Farm Tools - ${farmer.name}',
              style: const TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            automaticallyImplyLeading: false,
          ),
          body: GridView.count(
            crossAxisCount: 2,
            padding: const EdgeInsets.all(12),
            children: [
              FeatureButton(
                icon: Icons.book,
                label: 'Guidebook',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => GuidebookScreen()),
                  );
                },
              ),
              // ✅ Farmer Talk button with human avatar icon
              FeatureButton(
                icon: Icons.person,
                label: 'Farmer Talk',
                color: Colors.green.shade700,
                onTap: () async {
                  final sender = FirebaseAuth.instance.currentUser?.uid ?? '';
                  final chatId = const Uuid().v4();

                  // Create chat session in Firestore
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .set({
                        'chat_id': chatId,
                        'sender': sender,
                        'type': 'diagnosis',
                        'timestamp': FieldValue.serverTimestamp(),
                        'last_message': '',
                      });

                  // Navigate directly to chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          DiagnosisChatScreen(chatId: chatId, sender: sender),
                    ),
                  );
                },
              ),
              // ✅ Animal Mgnt button using livestock.png asset
              FeatureButton(
                customIcon: Image.asset(
                  "assets/icon/livestock.png",
                  width: 36,
                  height: 36,
                  color: Colors.green, // tint to match theme
                ),
                label: 'Animal Mgnt',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnimalManagementScreen(),
                    ),
                  );
                },
              ),
              FeatureButton(
                icon: Icons.school_rounded,
                label: 'Farming Academy',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AcademyScreen(),
                    ),
                  );
                },
              ),
              FeatureButton(
                icon: Icons.calendar_month,
                label: 'Farm Calendar',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CropCalendarScreen(),
                    ),
                  );
                },
              ),
              FeatureButton(
                customIcon: Icon(
                  Icons.agriculture,
                  size: 30,
                  color: Colors.green.shade700,
                ),
                label: 'Farm Works',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FarmWorksScreen(),
                    ),
                  );
                },
              ),
              FeatureButton(
                icon: Icons.work,
                label: 'Jobs',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const JobsScreen()),
                  );
                },
              ),
              FeatureButton(
                icon: Icons.spa,
                label: 'Crop Mgmt',
                color: Colors.green.shade700,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CropManagementScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
