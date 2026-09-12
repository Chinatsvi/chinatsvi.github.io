import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

class DemoSeeder {
  static final Random _random = Random();

  // Pools of sample data for realism
  static final List<String> firstNames = [
    'Tendai',
    'Nomsa',
    'Sipho',
    'Kwame',
    'Amina',
    'Blessing',
    'Lerato',
    'Thabo',
    'Zanele',
    'Joseph',
  ];

  static final List<String> lastNames = [
    'Moyo',
    'Dlamini',
    'Nkosi',
    'Chirwa',
    'Okoro',
    'Ncube',
    'Baloyi',
    'Maseko',
    'Khumalo',
    'Mutiso',
  ];

  static final List<String> bios = [
    'Passionate about sustainable farming and community growth.',
    'Focused on organic produce and fair trade.',
    'Dedicated to improving crop yields for smallholder farmers.',
    'Loves sharing farming knowledge with the community.',
    'Committed to climate-smart agriculture practices.',
  ];

  static final List<String> works = [
    'Maize Farmer',
    'Vegetable Grower',
    'Livestock Keeper',
    'Organic Producer',
    'Agroforestry Specialist',
  ];

  static final List<String> educations = [
    'Diploma in Agriculture',
    'Certificate in Organic Farming',
    'BSc in Crop Science',
    'High School Graduate',
    'Community Farming Training',
  ];

  static final List<String> locations = [
    'Harare, Zimbabwe',
    'Lusaka, Zambia',
    'Nairobi, Kenya',
    'Johannesburg, South Africa',
    'Lilongwe, Malawi',
  ];

  static String _randomName() {
    final first = firstNames[_random.nextInt(firstNames.length)];
    final last = lastNames[_random.nextInt(lastNames.length)];
    return '$first $last';
  }

  static String _randomFrom(List<String> list) =>
      list[_random.nextInt(list.length)];

  /// Seeds demo farmers, posts, cooperatives, messages, and marketplace items
  static Future<bool> seedDemoFarmersAndPosts() async {
    try {
      // 1. Create or Sign In Demo Users
      List<Map<String, String>> demoUsersData = List.generate(5, (i) {
        return {
          'email': 'demo${i + 1}@example.com',
          'password': '123456',
          'user_name': _randomName(),
          'profilePic':
              'https://picsum.photos/200?random=${_random.nextInt(1000)}',
          'phone': '+26370000000${i + 1}',
          'bio': _randomFrom(bios),
          'work': _randomFrom(works),
          'education': _randomFrom(educations),
          'location': _randomFrom(locations),
        };
      });

      Map<String, String> uidMap = {};

      for (var user in demoUsersData) {
        try {
          UserCredential userCredential;
          try {
            userCredential = await FirebaseAuth.instance
                .signInWithEmailAndPassword(
                  email: user['email']!,
                  password: user['password']!,
                );
          } catch (_) {
            userCredential = await FirebaseAuth.instance
                .createUserWithEmailAndPassword(
                  email: user['email']!,
                  password: user['password']!,
                );
          }

          String uid = userCredential.user!.uid;
          uidMap[user['email']!] = uid;

          await FirebaseFirestore.instance.collection('farmers').doc(uid).set({
            'user_name': user['user_name'],
            'profile_pic': user['profilePic'],
            'phone': user['phone'],
            'bio': user['bio'],
            'work': user['work'],
            'education': user['education'],
            'location': user['location'],
            'followers': [],
            'following': [],
            'totalSales': _random.nextInt(50),
            'created_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          developer.log(
            'Demo farmer ready: ${user['user_name']} (UID: $uid)',
            name: 'DemoSeeder',
          );
        } catch (e) {
          developer.log(
            'Error creating/signing demo user ${user['email']}',
            name: 'DemoSeeder',
            error: e,
          );
        }
      }

      final List<String> allUIDs = uidMap.values.toList();
      if (allUIDs.isEmpty) {
        developer.log(
          'No demo users available, skipping seeding.',
          name: 'DemoSeeder',
        );
        return false;
      }

      // 2. Generate Demo Posts
      List<String> samplePostTexts = [
        'Check your crops today!',
        'Market prices updated!',
        'Remember to water vegetables.',
        'Time to harvest maize.',
        'Use organic fertilizer for better yield.',
      ];

      for (int i = 0; i < 20; i++) {
        final uid = allUIDs[_random.nextInt(allUIDs.length)];
        final farmerDoc = await FirebaseFirestore.instance
            .collection('farmers')
            .doc(uid)
            .get();
        final farmerData = farmerDoc.data();

        final authorName = farmerData?['user_name'] ?? 'Unknown Farmer';
        final authorAvatar = farmerData?['profile_pic'] ?? '';

        await FirebaseFirestore.instance.collection('posts').add({
          'authorId': uid,
          'authorName': authorName,
          'authorAvatar': authorAvatar,
          'content': samplePostTexts[_random.nextInt(samplePostTexts.length)],
          'content_type': 'text',
          'media': [],
          'created_at': FieldValue.serverTimestamp(),
          'status': 'active',
          'likes': [],
          'hashtags': [],
          'analytics': {
            'viewsCount': 0,
            'commentsCount': 0,
            'sharesCount': 0,
            'reactionsCount': 0,
            'savesCount': 0,
          },
        });
      }
      developer.log('Generated 20 demo posts.', name: 'DemoSeeder');

      // 3. Generate Demo Cooperatives
      List<String> coopNames = [
        'Maize Cooperative',
        'Vegetable Cooperative',
        'Sorghum Farmers',
        'Organic Farming Group',
        'Livestock Cooperative',
      ];

      if (allUIDs.length > 1) {
        for (String name in coopNames) {
          int memberCount = 2 + _random.nextInt(allUIDs.length - 1);
          List<String> members = List.from(allUIDs)..shuffle(_random);
          members = members.take(memberCount).toList();

          await FirebaseFirestore.instance.collection('cooperative').add({
            'name': name,
            'members': members,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        developer.log('Generated demo cooperatives.', name: 'DemoSeeder');
      }

      // 4. Generate Demo Messages
      List<String> sampleMessages = [
        'Hello! How is your farm today?',
        'Good morning, have you checked your crops?',
        'Let’s meet at the market tomorrow.',
        'Can you share your fertilizer tips?',
        'Harvest looks good this season!',
      ];

      for (int i = 0; i < 10; i++) {
        if (allUIDs.length < 2) break;
        String sender = allUIDs[_random.nextInt(allUIDs.length)];
        String receiver = allUIDs[_random.nextInt(allUIDs.length)];
        if (sender == receiver) continue;

        String chatId = sender.hashCode <= receiver.hashCode
            ? '$sender-$receiver'
            : '$receiver-$sender';

        await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .add({
              'senderId': sender,
              'text': sampleMessages[_random.nextInt(sampleMessages.length)],
              'timestamp': FieldValue.serverTimestamp(),
            });
      }
      developer.log('Generated 10 demo messages.', name: 'DemoSeeder');

      // 5. Generate Demo Marketplace Items
      List<String> sampleProductTitles = [
        'Maize Seeds',
        'Organic Fertilizer',
        'Vegetable Seeds',
        'Millet',
        'Farm Tools',
      ];

      for (int i = 0; i < 10; i++) {
        final sellerId = allUIDs[_random.nextInt(allUIDs.length)];
        await FirebaseFirestore.instance.collection('marketplace').add({
          'sellerId': sellerId,
          'title':
              sampleProductTitles[_random.nextInt(sampleProductTitles.length)],
          'price': (5 + _random.nextInt(20)).toDouble(),
          'images': [
            'https://picsum.photos/200?random=${_random.nextInt(1000)}',
          ],
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
      developer.log('Generated 10 marketplace items.', name: 'DemoSeeder');

      developer.log(
        'Fully populated demo data setup complete!',
        name: 'DemoSeeder',
      );
      return true;
    } catch (e) {
      developer.log('Seeder failed', name: 'DemoSeeder', error: e);
      return false;
    }
  }
}
