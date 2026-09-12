import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agribased/screens/profile/farmer_model.dart';

class FarmerService {
  final _firestore = FirebaseFirestore.instance;

  Future<void> saveFarmerProfile(FarmerModel farmer) async {
    await _firestore.collection('farmers').doc(farmer.id).set({
      'name': farmer.name,
      'bio': farmer.bio,
      'location': farmer.location,
      'work': farmer.workList.map((w) => w.toMap()).toList(),
      'education': farmer.educationList.map((e) => e.toMap()).toList(),
      'crops': farmer.crops,
      'followers': farmer.followers,
      'following': farmer.following,
      'posts': farmer.posts,
      'profile_pic': farmer.profilePic,
      'cover_photo': farmer.coverPhoto,
      'isSeller': farmer.isSeller,
      'products': farmer.products,
      'rating': farmer.rating,
      'totalSales': farmer.totalSales,
      'phone': farmer.phone,
      'whatsapp': farmer.whatsapp,
      'accountType': farmer.accountType,
      'email': farmer.email,
      'farmType': farmer.farmType,
      'website': farmer.website,
      'socialLinks': farmer.socialLinks,
      'cooperative': farmer.cooperative,
      'status': farmer.status,
      'created_at': farmer.createdAt ?? FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}