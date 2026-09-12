// lib/services/cctv_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addCameraToFarmer(
  String farmerId,
  String name,
  String streamUrl,
) async {
  if (name.isEmpty || streamUrl.isEmpty) {
    throw Exception("Camera name and stream URL are required.");
  }

  if (!(streamUrl.startsWith("rtsp://") ||
      streamUrl.startsWith("http://") ||
      streamUrl.startsWith("https://"))) {
    throw Exception(
      "Invalid stream URL. Must start with rtsp:// or http(s)://",
    );
  }

  // Generate a unique ID for the camera
  final cameraId = FirebaseFirestore.instance.collection('farmers').doc().id;

  final newCamera = {
    "id": cameraId, // Add required id field
    "name": name,
    "streamUrl": streamUrl,
    "isActive": true, // Add isActive field
    "lastActive": Timestamp.now(), // Add lastActive field
  };

  await FirebaseFirestore.instance.collection('farmers').doc(farmerId).update({
    "cameras": FieldValue.arrayUnion([newCamera]),
  });
}
