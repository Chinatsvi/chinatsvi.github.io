import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/optimized_user_service.dart';
import '../../services/storage_router_service.dart';
import '../../services/profile_update_service.dart';
import '../../services/profile_picture_preloader.dart';
import '../../services/smart_moderation_service.dart';
import '../../widgets/safe_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/routes/app_routes.dart';
import '../../app/utils/formatters.dart';
import '../../services/firebase_storage_service.dart';
import '../../services/academy/academy_progress_service.dart';

List<dynamic> normalizeFirestoreList(dynamic value) {
  if (value is List) return value;
  if (value is String && value.trim().isNotEmpty) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
  return const <dynamic>[];
}

List<String> normalizeStringList(dynamic value) {
  return normalizeFirestoreList(value)
      .map((entry) => entry.toString().trim())
      .where((entry) => entry.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> normalizeMapList(dynamic value) {
  final rawList = normalizeFirestoreList(value);
  return rawList
      .whereType<Map>()
      .map((entry) => Map<String, dynamic>.from(entry))
      .toList();
}

class FarmerProfileEditScreen extends StatefulWidget {
  const FarmerProfileEditScreen({super.key});

  @override
  State<FarmerProfileEditScreen> createState() =>
      _FarmerProfileEditScreenState();
}

class _FarmerProfileEditScreenState extends State<FarmerProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController socialLinksController = TextEditingController();

  List<Map<String, TextEditingController>> educationControllers = [];
  List<Map<String, TextEditingController>> workControllers = [];

  bool isLoading = false;
  String? profilePicUrl;
  String? coverPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ---------------- LOAD PROFILE ----------------
  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    if (!doc.exists) return;
    final data = doc.data()!;

    nameController.text = (data['user_name'] ?? data['name'] ?? '').toString();
    locationController.text = Formatter.formatLocation(data['location']);
    phoneController.text = (data['phone'] ?? '').toString();
    bioController.text = (data['bio'] ?? '').toString();
    websiteController.text = (data['website'] ?? '').toString();

    final socialLinksData = normalizeStringList(
      data['socialLinks'] ?? data['social_links'],
    );
    socialLinksController.text = socialLinksData.join(', ');

    profilePicUrl = (data['profile_pic'] ?? '').toString();
    coverPhotoUrl = (data['cover_photo'] ?? '').toString();

    educationControllers.clear();
    final educationList = normalizeMapList(data['educationList'] ?? data['education']);
    for (final e in educationList) {
      final item = e is Map ? e : <String, dynamic>{};
      educationControllers.add({
        'degree': TextEditingController(text: (item['degree'] ?? '').toString()),
        'institution': TextEditingController(
          text: (item['institution'] ?? '').toString(),
        ),
        'description': TextEditingController(
          text: (item['description'] ?? '').toString(),
        ),
        'start': TextEditingController(text: (item['startDate'] ?? '').toString()),
        'end': TextEditingController(text: (item['endDate'] ?? '').toString()),
        'certificate': TextEditingController(text: (item['certificate'] ?? '').toString()),
      });
    }

    workControllers.clear();
    final workList = normalizeMapList(data['workList'] ?? data['work']);
    for (final w in workList) {
      final item = w is Map ? w : <String, dynamic>{};
      workControllers.add({
        'role': TextEditingController(text: (item['role'] ?? '').toString()),
        'company': TextEditingController(text: (item['company'] ?? '').toString()),
        'description': TextEditingController(
          text: (item['description'] ?? '').toString(),
        ),
        'start': TextEditingController(text: (item['startDate'] ?? '').toString()),
        'end': TextEditingController(text: (item['endDate'] ?? '').toString()),
      });
    }

    setState(() {});
  }

  // ---------------- IMAGE PICK & UPLOAD ----------------
  Future<void> _pickAndUploadImage(bool isProfile) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final file = File(pickedFile.path);

    try {
      final publicUrl = isProfile
          ? await StorageRouterService.instance.uploadProfilePicture(
              file: file,
              userId: uid,
            )
          : await StorageRouterService.instance.uploadCoverPhoto(
              file: file,
              userId: uid,
            );

      if (mounted) {
        setState(() {
          if (isProfile) {
            profilePicUrl = publicUrl;
          } else {
            coverPhotoUrl = publicUrl;
          }
        });

        await FirebaseFirestore.instance.collection('farmers').doc(uid).set({
          isProfile ? 'profile_pic' : 'cover_photo': publicUrl,
        }, SetOptions(merge: true));

        if (isProfile) {
          await OptimizedUserService.clearUserCache(uid);
          await ProfilePicturePreloader().refreshProfilePicture(uid);
        }

        unawaited(
          SmartModerationService.moderateContent(
            content: '',
            postId: uid,
            userId: uid,
            userName: nameController.text.trim().isNotEmpty
                ? nameController.text.trim()
                : 'Farmer',
            mediaUrls: [publicUrl],
            imageUrl: publicUrl,
            contentType: isProfile ? 'profile_picture' : 'cover_photo',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
      }
    }
  }

  // ---------------- COVER & PROFILE WIDGET ----------------
  Widget _buildCoverAndProfile() {
    return SizedBox(
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover
          Container(
            height: 180,
            width: double.infinity,
            color: Colors.grey[300],
            child: coverPhotoUrl != null
                ? SafeNetworkImage(imageUrl: coverPhotoUrl!, fit: BoxFit.cover)
                : const Center(
                    child: Icon(Icons.photo, size: 50, color: Colors.grey),
                  ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.green,
              onPressed: () => _pickAndUploadImage(false),
              child: const Icon(Icons.edit),
            ),
          ),
          Positioned(
            bottom: -55,
            left: 16,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () {
                    debugPrint('📸 Profile picture tapped!');
                    _pickAndUploadImage(true);
                  },
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: profilePicUrl != null
                        ? CachedNetworkImageProvider(profilePicUrl!)
                        : null,
                    child: profilePicUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: GestureDetector(
                    onTap: () {
                      debugPrint('📸 Edit button tapped!');
                      _pickAndUploadImage(true);
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DYNAMIC EDUCATION ----------------
  Widget _buildDynamicEducation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Education',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...educationControllers.map((e) {
          final index = educationControllers.indexOf(e);
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: e['degree'],
                      decoration: InputDecoration(
                        labelText: 'Degree ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () =>
                        setState(() => educationControllers.removeAt(index)),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: e['institution'],
                decoration: InputDecoration(
                  labelText: 'Institution ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: e['description'],
                decoration: InputDecoration(
                  labelText: 'Education Description ${index + 1}',
                  border: const OutlineInputBorder(),
                  counterText: '${e['description']!.text.length}/250',
                ),
                maxLength: 250,
                maxLines: 3,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return Text(
                        '$currentLength/250',
                        style: TextStyle(
                          color: currentLength > 200 ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: e['start'],
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, e['start']!),
                        ),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: e['end'],
                      decoration: InputDecoration(
                        labelText: 'End Date / Present',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, e['end']!),
                        ),
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              // Certificate Upload (Optional)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (e['certificate']?.text.isNotEmpty == true)
                      ? Colors.green.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (e['certificate']?.text.isNotEmpty == true)
                        ? Colors.green.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (e['certificate']?.text.isNotEmpty == true)
                          ? Icons.verified
                          : Icons.workspace_premium_outlined,
                      color: (e['certificate']?.text.isNotEmpty == true)
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (e['certificate']?.text.isNotEmpty == true)
                            ? 'Certificate Attached ✅'
                            : 'Upload Certificate / Diploma (Optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: (e['certificate']?.text.isNotEmpty == true)
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: (e['certificate']?.text.isNotEmpty == true)
                              ? Colors.green.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: (e['certificate']?.text.isNotEmpty == true)
                            ? Colors.green.shade800
                            : Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      icon: Icon(
                        (e['certificate']?.text.isNotEmpty == true)
                            ? Icons.refresh
                            : Icons.upload_file,
                        size: 16,
                      ),
                      label: Text(
                        (e['certificate']?.text.isNotEmpty == true)
                            ? 'Change'
                            : 'Upload',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickAndUploadEducationCertificate(index),
                    ),
                    if (e['certificate']?.text.isNotEmpty == true)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                        tooltip: 'Remove',
                        onPressed: () {
                          setState(() {
                            e['certificate']!.text = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: () => setState(() {
              educationControllers.add({
                'degree': TextEditingController(),
                'institution': TextEditingController(),
                'description': TextEditingController(),
                'start': TextEditingController(),
                'end': TextEditingController(),
                'certificate': TextEditingController(),
              });
            }),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadEducationCertificate(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Uploading certificate... Please wait')),
    );

    try {
      final file = File(picked.path);
      final storage = FirebaseStorageService();
      final url = await storage.uploadFile(
        bucket: 'certificates',
        file: file,
        folder: 'users/$uid/certificates',
      );

      if (url != null) {
        if (!mounted) return;
        setState(() {
          educationControllers[index]['certificate']!.text = url;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Certificate attached successfully! ✅')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to upload certificate: $e')),
      );
    }
  }

  // ---------------- DYNAMIC WORK ----------------
  Widget _buildDynamicWork() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...workControllers.map((w) {
          final index = workControllers.indexOf(w);
          return Column(
            children: [
              TextFormField(
                controller: w['role'],
                decoration: InputDecoration(
                  labelText: 'Role ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: w['company'],
                decoration: InputDecoration(
                  labelText: 'Company ${index + 1}',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: w['description'],
                decoration: InputDecoration(
                  labelText: 'Description ${index + 1}',
                  border: const OutlineInputBorder(),
                  counterText: '${w['description']!.text.length}/250',
                ),
                maxLength: 250,
                maxLines: 3,
                buildCounter:
                    (
                      context, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) {
                      return Text(
                        '$currentLength/250',
                        style: TextStyle(
                          color: currentLength > 200 ? Colors.red : Colors.grey,
                          fontSize: 12,
                        ),
                      );
                    },
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: w['start'],
                      decoration: InputDecoration(
                        labelText: 'Start Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, w['start']!),
                        ),
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: w['end'],
                      decoration: InputDecoration(
                        labelText: 'End Date / Present',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => _selectDate(context, w['end']!),
                        ),
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () =>
                    setState(() => workControllers.removeAt(index)),
              ),
              const SizedBox(height: 10),
            ],
          );
        }),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.green),
            onPressed: () => setState(() {
              workControllers.add({
                'role': TextEditingController(),
                'company': TextEditingController(),
                'description': TextEditingController(),
                'start': TextEditingController(),
                'end': TextEditingController(),
              });
            }),
          ),
        ),
      ],
    );
  }

  // ---------------- DATE PICKER ----------------
  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final dialogContext = context;
    if (!dialogContext.mounted) return;

    final bool? isPresent = await showDialog<bool>(
      context: dialogContext,
      builder: (BuildContext innerContext) {
        return AlertDialog(
          title: const Text('Select Date Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Choose Date'),
                leading: const Icon(Icons.calendar_today),
                onTap: () => Navigator.of(innerContext).pop(false),
              ),
              ListTile(
                title: const Text('Present'),
                leading: const Icon(Icons.work),
                onTap: () => Navigator.of(innerContext).pop(true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(innerContext).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (!mounted || !dialogContext.mounted) return;

    if (isPresent == true) {
      controller.text = 'Present';
    } else if (isPresent == false) {
      final DateTime? picked = await showDatePicker(
        context: dialogContext,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
      );
      if (!mounted || !dialogContext.mounted) return;
      if (picked != null) {
        controller.text = '${picked.day}/${picked.month}/${picked.year}';
      }
    }
  }

  List<Map<String, String>> _buildEducationList(Map<String, dynamic> currentData) {
    final fallbackData = normalizeMapList(currentData['educationList'] ?? currentData['education']);
    if (educationControllers.isEmpty && fallbackData.isNotEmpty) {
      return fallbackData.map((entry) {
        final item = entry is Map ? entry : <String, dynamic>{};
        return {
          'degree': (item['degree'] ?? '').toString(),
          'institution': (item['institution'] ?? '').toString(),
          'description': (item['description'] ?? '').toString(),
          'startDate': (item['startDate'] ?? '').toString(),
          'endDate': (item['endDate'] ?? '').toString(),
          'certificate': (item['certificate'] ?? '').toString(),
        };
      }).toList();
    }

    final list = <Map<String, String>>[];
    for (final entry in educationControllers) {
      final institution = entry['institution']?.text.trim() ?? '';
      if (institution.isEmpty && fallbackData.isNotEmpty) {
        final fallbackEntry = fallbackData.firstWhere(
          (item) => item is Map && (item['institution'] ?? '').toString().isNotEmpty,
          orElse: () => <String, dynamic>{},
        );
        if (fallbackEntry is Map) {
          list.add({
            'degree': (fallbackEntry['degree'] ?? entry['degree']?.text ?? '').toString(),
            'institution': (fallbackEntry['institution'] ?? '').toString(),
            'description': (fallbackEntry['description'] ?? entry['description']?.text ?? '').toString(),
            'startDate': (fallbackEntry['startDate'] ?? entry['start']?.text ?? '').toString(),
            'endDate': (fallbackEntry['endDate'] ?? entry['end']?.text ?? '').toString(),
            'certificate': (fallbackEntry['certificate'] ?? entry['certificate']?.text ?? '').toString(),
          });
          continue;
        }
      }

      if (institution.isNotEmpty || entry['degree']?.text.trim().isNotEmpty == true) {
        list.add({
          'degree': entry['degree']?.text.trim() ?? '',
          'institution': institution,
          'description': entry['description']?.text.trim() ?? '',
          'startDate': entry['start']?.text.trim() ?? '',
          'endDate': entry['end']?.text.trim() ?? '',
          'certificate': entry['certificate']?.text.trim() ?? '',
        });
      }
    }
    return list;
  }

  List<Map<String, String>> _buildWorkList(Map<String, dynamic> currentData) {
    final fallbackData = normalizeMapList(currentData['workList'] ?? currentData['work']);
    if (workControllers.isEmpty && fallbackData.isNotEmpty) {
      return fallbackData.map((entry) {
        final item = entry is Map ? entry : <String, dynamic>{};
        return {
          'role': (item['role'] ?? '').toString(),
          'company': (item['company'] ?? '').toString(),
          'description': (item['description'] ?? '').toString(),
          'startDate': (item['startDate'] ?? '').toString(),
          'endDate': (item['endDate'] ?? '').toString(),
        };
      }).toList();
    }

    final list = <Map<String, String>>[];
    for (final entry in workControllers) {
      final role = entry['role']?.text.trim() ?? '';
      final company = entry['company']?.text.trim() ?? '';
      if (role.isEmpty && company.isEmpty && fallbackData.isNotEmpty) {
        final fallbackEntry = fallbackData.firstWhere(
          (item) => item is Map && ((item['role'] ?? '').toString().isNotEmpty || (item['company'] ?? '').toString().isNotEmpty),
          orElse: () => <String, dynamic>{},
        );
        if (fallbackEntry is Map) {
          list.add({
            'role': (fallbackEntry['role'] ?? '').toString(),
            'company': (fallbackEntry['company'] ?? '').toString(),
            'description': (fallbackEntry['description'] ?? entry['description']?.text ?? '').toString(),
            'startDate': (fallbackEntry['startDate'] ?? entry['start']?.text ?? '').toString(),
            'endDate': (fallbackEntry['endDate'] ?? entry['end']?.text ?? '').toString(),
          });
          continue;
        }
      }

      if (role.isNotEmpty || company.isNotEmpty) {
        list.add({
          'role': role,
          'company': company,
          'description': entry['description']?.text.trim() ?? '',
          'startDate': entry['start']?.text.trim() ?? '',
          'endDate': entry['end']?.text.trim() ?? '',
        });
      }
    }
    return list;
  }

  List<String> _buildSocialLinks(Map<String, dynamic> currentData) {
    final input = socialLinksController.text.trim();
    if (input.isNotEmpty) {
      return input
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    return normalizeStringList(currentData['socialLinks'] ?? currentData['social_links']);
  }

  // ---------------- SAVE PROFILE ----------------
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not logged in');
      }

      debugPrint('💾 Starting profile save for user: $uid');

      final currentDoc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();

      final currentData = currentDoc.data() ?? {};
      final currentName = (currentData['user_name'] ?? '').toString();
      final currentAvatar = (currentData['profile_pic'] ?? '').toString();
      final newName = nameController.text.trim().isNotEmpty
          ? nameController.text.trim()
          : (currentData['user_name'] ?? currentData['name'] ?? '').toString();
      final newAvatar = (profilePicUrl ?? currentData['profile_pic'] ?? '').toString();

      if (newName.isEmpty) {
        throw Exception('Name is required');
      }

      String bioText = bioController.text.trim();
      if (bioText.isEmpty) {
        bioText = (currentData['bio'] ?? '').toString();
      }
      if (bioText.length > 350) bioText = bioText.substring(0, 350);

      final locationText = locationController.text.trim().isNotEmpty
          ? locationController.text.trim()
          : Formatter.formatLocation(currentData['location']);
      final phoneText = phoneController.text.trim().isNotEmpty
          ? phoneController.text.trim()
          : (currentData['phone'] ?? '').toString();
      final websiteText = websiteController.text.trim().isNotEmpty
          ? websiteController.text.trim()
          : (currentData['website'] ?? '').toString();

      final educationList = _buildEducationList(currentData);
      final workList = _buildWorkList(currentData);
      final socialLinksList = _buildSocialLinks(currentData);
      final coverUrl = (coverPhotoUrl ?? currentData['cover_photo'] ?? '').toString();

      debugPrint('💾 Saving profile data to Firestore...');

      await FirebaseFirestore.instance.collection('farmers').doc(uid).set({
        'user_name': newName,
        'profile_pic': newAvatar,
        'cover_photo': coverUrl,
        'location': locationText,
        'phone': phoneText,
        'bio': bioText,
        'educationList': educationList,
        'workList': workList,
        'website': websiteText,
        'socialLinks': socialLinksList,
        'updated_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Synchronize any uploaded education certificates to Academy awards
      for (final edu in educationList) {
        final certUrl = edu['certificate'] ?? '';
        final deg = edu['degree'] ?? 'Agricultural Certificate';
        final inst = edu['institution'] ?? 'Agricultural Institute';
        final desc = edu['description'] ?? '';
        if (certUrl.isNotEmpty) {
          try {
            await AcademyProgressService.instance.addExternalCertificate(
              userId: uid,
              courseTitle: deg.isNotEmpty ? deg : 'Agricultural Certificate',
              issuer: inst.isNotEmpty ? inst : 'Educational Institute',
              description: desc,
              certificateUrl: certUrl,
            );
          } catch (e) {
            debugPrint('⚠️ Error registering external certificate in Academy: $e');
          }
        }
      }

      debugPrint('💾 Profile data saved successfully');

      // Update user name and avatar across all posts and comments if changed
      final nameChanged = currentName != newName;
      final avatarChanged = newAvatar != currentAvatar;

      if (nameChanged || avatarChanged) {
        debugPrint('💾 Updating profile across posts and comments...');
        try {
          // Use our new OptimizedUserService with smart cache updates
          await OptimizedUserService.updateProfile(
            uid: uid,
            name: newName,
            profilePic: avatarChanged ? newAvatar : null,
          );

          // 🚀 Batch Update System - Update all posts and comments
          // This handles the gradual update across all content
          await ProfileUpdateService.instance.updateUserProfileAcrossPosts(
            userId: uid,
            newDisplayName: newName,
            newAvatarUrl: avatarChanged ? newAvatar : null,
          );

          debugPrint('💾 Profile updates across posts completed');
        } catch (e) {
          debugPrint('⚠️ Error updating profile across posts: $e');
          // Don't fail the save, just log the error
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to community screen instead of popping
        debugPrint('💾 Navigating to community screen...');
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil(AppRoutes.community, (route) => false);
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        String errorMessage = 'Failed to update profile';

        // Provide user-friendly error messages
        if (e.toString().contains('Name is required')) {
          errorMessage = 'Please enter your name';
        } else if (e.toString().contains('User not logged in')) {
          errorMessage = 'Please log in again';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your internet connection';
        } else if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please try again';
        } else {
          errorMessage = 'Failed to update profile: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Edit Farmer Profile'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.only(top: 70),
                  children: [
                    _buildCoverAndProfile(),
                    const SizedBox(height: 70),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'Enter your full name (required)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Name is required - please enter your name';
                        }
                        if (v.trim().length < 2) {
                          return 'Name must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: bioController,
                      decoration: const InputDecoration(
                        labelText: 'Short Bio (max 350 chars)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      maxLength: 350,
                    ),
                    const SizedBox(height: 20),
                    _buildDynamicEducation(),
                    const SizedBox(height: 20),
                    _buildDynamicWork(),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: websiteController,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: socialLinksController,
                      decoration: const InputDecoration(
                        labelText: 'Social Links (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Save Profile',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
