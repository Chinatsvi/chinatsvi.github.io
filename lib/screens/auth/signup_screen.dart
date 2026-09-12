import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:agribased/app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../services/storage_router_service.dart';
import '../../services/smart_moderation_service.dart';
import '../profile/farmer_profile_edit_screen.dart';

class SignUpScreen extends StatefulWidget {
  final bool showAuthButtons;
  const SignUpScreen({super.key, this.showAuthButtons = true});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _authController = AuthController();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  // Phone signup removed per request; phone field no longer collected here.
  final TextEditingController workController = TextEditingController();
  final TextEditingController educationController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController socialLinksController = TextEditingController();

  List<Map<String, TextEditingController>> educationControllers = [];
  List<Map<String, TextEditingController>> workControllers = [];

  bool isLoading = false;
  bool _obscurePassword = true;
  File? _profilePicFile;
  File? _coverPhotoFile;
  String? _profilePicUrl;
  String? _coverPhotoUrl;

  /// Note: we intentionally do not call an unsupported fetchSignInMethodsForEmail API.
  /// Signup flow relies on catching `email-already-in-use` from the create call.

  /// Check if farmer profile exists in Firestore
  Future<bool> _farmerProfileExists(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Error checking farmer profile: $e');
      return false;
    }
  }

  /// Smart sign up with email - checks if account exists first
  Future<void> _smartSignUp() async {
    if (_formKey.currentState?.validate() != true || !mounted) return;

    setState(() => isLoading = true);

    try {
      // Attempt to create user and save profile. If the email already exists,
      // the underlying create call will throw and we'll handle it below.
      await _signUpAndSaveProfile();
    } catch (e) {
      if (!mounted) return;

      // Check if error indicates existing account
      if (e.toString().contains('email-already-in-use') ||
          e.toString().contains('account-exists-with-different-credential')) {
        await _tryLoginExisting();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign up failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage(bool isProfile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      final f = File(picked.path);
      if (isProfile) {
        _profilePicFile = f;
      } else {
        _coverPhotoFile = f;
      }
    });
  }

  Widget _buildCoverAndProfile() {
    return SizedBox(
      height: 250,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Cover with overlayed title
          Container(
            height: 180,
            width: double.infinity,
            color: Colors.grey[300],
            child: Stack(
              fit: StackFit.expand,
              children: [
                _coverPhotoFile != null
                    ? Image.file(_coverPhotoFile!, fit: BoxFit.cover)
                    : (_coverPhotoUrl != null
                        ? Image.network(_coverPhotoUrl!, fit: BoxFit.cover)
                        : const Center(
                            child: Icon(
                              Icons.photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                          )),
                // Title overlay at top of cover
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: Text(
                      'Create your farming account 🌾',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black45,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.green,
              onPressed: () => _pickImage(false),
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
                  onTap: () => _pickImage(true),
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profilePicFile != null
                        ? FileImage(_profilePicFile!) as ImageProvider
                        : (_profilePicUrl != null
                              ? NetworkImage(_profilePicUrl!)
                              : null),
                    child: _profilePicFile == null && _profilePicUrl == null
                        ? const Icon(Icons.person, size: 50, color: Colors.grey)
                        : null,
                  ),
                ),
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: GestureDetector(
                    onTap: () => _pickImage(true),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
              const SizedBox(height: 10),
            ],
          );
        }).toList(),
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
              });
            }),
          ),
        ),
      ],
    );
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
        }).toList(),
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
    final bool? isPresent = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Date Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Choose Date'),
                leading: const Icon(Icons.calendar_today),
                onTap: () => Navigator.of(context).pop(false),
              ),
              ListTile(
                title: const Text('Present'),
                leading: const Icon(Icons.work),
                onTap: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    if (isPresent == true) {
      controller.text = 'Present';
    } else if (isPresent == false) {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(1950),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        controller.text = '${picked.day}/${picked.month}/${picked.year}';
      }
    }
  }

  /// Sign up then upload images and save profile fields to Firestore
  Future<void> _signUpAndSaveProfile() async {
    if (_formKey.currentState?.validate() != true || !mounted) return;
    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      final user = await _authController.signUpWithEmail(
        userName: nameController.text.trim(),
        email: email,
        password: password,
        location: locationController.text.trim(),
        bio: bioController.text.trim(),
        phone: '',
        work: workController.text.trim(),
        education: educationController.text.trim(),
      );

      if (user == null) throw Exception('Failed to create user');

      final uid = user.uid;

      // Upload images if picked
      if (_profilePicFile != null) {
        try {
          _profilePicUrl = await StorageRouterService.instance
              .uploadProfilePicture(file: _profilePicFile!, userId: uid);
        } catch (e) {
          debugPrint('Profile image upload failed: $e');
        }
      }

      if (_coverPhotoFile != null) {
        try {
          _coverPhotoUrl = await StorageRouterService.instance.uploadCoverPhoto(
            file: _coverPhotoFile!,
            userId: uid,
          );
        } catch (e) {
          debugPrint('Cover upload failed: $e');
        }
      }

      // Build education/work lists from dynamic controllers
      List<Map<String, String>> educationList = [];
      for (var e in educationControllers) {
        if (e['institution']!.text.trim().isNotEmpty) {
          educationList.add({
            'degree': e['degree']!.text.trim(),
            'institution': e['institution']!.text.trim(),
            'description': e['description']!.text.trim(),
            'startDate': e['start']!.text.trim(),
            'endDate': e['end']!.text.trim(),
          });
        }
      }

      List<Map<String, String>> workList = [];
      for (var w in workControllers) {
        if (w['role']!.text.trim().isNotEmpty) {
          workList.add({
            'role': w['role']!.text.trim(),
            'company': w['company']!.text.trim(),
            'description': w['description']!.text.trim(),
            'startDate': w['start']!.text.trim(),
            'endDate': w['end']!.text.trim(),
          });
        }
      }

      // Save additional profile fields to Firestore (merge)
      final dataToSave = {
        'user_name': nameController.text.trim(),
        'location': locationController.text.trim(),
        'bio': bioController.text.trim(),
        // phone removed from signup form
        'website': websiteController.text.trim(),
        'socialLinks': socialLinksController.text.trim().isNotEmpty
            ? socialLinksController.text
                  .trim()
                  .split(',')
                  .map((s) => s.trim())
                  .toList()
            : [],
        'educationList': educationList,
        'workList': workList,
        if (_profilePicUrl != null) 'profile_pic': _profilePicUrl,
        if (_coverPhotoUrl != null) 'cover_photo': _coverPhotoUrl,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('farmers')
          .doc(uid)
          .set(dataToSave, SetOptions(merge: true));

      final farmerName = nameController.text.trim().isNotEmpty
          ? nameController.text.trim()
          : 'Farmer';

      if (_profilePicUrl != null && _profilePicUrl!.isNotEmpty) {
        unawaited(
          SmartModerationService.moderateContent(
            content: '',
            postId: uid,
            userId: uid,
            userName: farmerName,
            mediaUrls: [_profilePicUrl!],
            imageUrl: _profilePicUrl,
            contentType: 'profile_picture',
          ),
        );
      }

      if (_coverPhotoUrl != null && _coverPhotoUrl!.isNotEmpty) {
        unawaited(
          SmartModerationService.moderateContent(
            content: '',
            postId: uid,
            userId: uid,
            userName: farmerName,
            mediaUrls: [_coverPhotoUrl!],
            imageUrl: _coverPhotoUrl,
            contentType: 'cover_photo',
          ),
        );
      }

      // Navigate to community
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.community);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Try to login with existing account
  Future<void> _tryLoginExisting() async {
    try {
      final user = await _authController.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user == null || !mounted) return;

      // Check if farmer profile exists
      final hasProfile = await _farmerProfileExists(user.uid);
      if (!mounted) return;

      if (hasProfile) {
        // Account exists and has profile - still go to profile edit for signup flow
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
        );
      } else {
        // Account exists but no profile - go to profile edit
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account exists but login failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Smart sign up with Google - checks if account exists first
  Future<void> _smartSignUpWithGoogle() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final user = await _authController.signUpWithGoogle();
      if (user == null || !mounted) return;

      // Autofill controllers
      if (nameController.text.isEmpty) {
        nameController.text = user.displayName ?? '';
      }
      if (emailController.text.isEmpty) {
        emailController.text = user.email ?? '';
      }

      // Check if farmer profile exists
      final hasProfile = await _farmerProfileExists(user.uid);
      if (!mounted) return;

      if (hasProfile) {
        // Account exists and has profile - still go to profile edit for signup flow
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
        );
      } else {
        // Account exists but no profile - go to profile edit
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const FarmerProfileEditScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-Up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    locationController.dispose();
    bioController.dispose();
    workController.dispose();
    educationController.dispose();
    websiteController.dispose();
    socialLinksController.dispose();

    for (var e in educationControllers) {
      e.values.forEach((c) => c.dispose());
    }
    for (var w in workControllers) {
      w.values.forEach((c) => c.dispose());
    }
    _animCtrl.dispose();
    super.dispose();
  }

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Farmer Sign Up'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: FadeTransition(
            opacity: _fadeIn,
            child: ListView(
              children: [
                const SizedBox(height: 20),
                // Cover and profile upload
                _buildCoverAndProfile(),
                const SizedBox(height: 40),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    hintText: 'Enter your full name (required)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty)
                      return 'Name is required';
                    if (v.trim().length < 2)
                      return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Email
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    filled: true,
                    fillColor: Colors.green[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your email' : null,
                ),
                const SizedBox(height: 15),

                // Password
                TextFormField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: Colors.green[50],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  validator: (v) => v == null || v.length < 6
                      ? 'At least 6 characters'
                      : null,
                ),
                const SizedBox(height: 15),

                // Location
                TextFormField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 15),

                // Bio
                TextFormField(
                  controller: bioController,
                  decoration: const InputDecoration(
                    labelText: 'Short Bio (max 350 chars)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  maxLength: 350,
                ),
                const SizedBox(height: 15),

                // Phone field removed

                // Work
                // Work dynamic list
                _buildDynamicWork(),
                const SizedBox(height: 15),

                // Education
                _buildDynamicEducation(),
                const SizedBox(height: 15),

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
                const SizedBox(height: 25),

                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : (widget.showAuthButtons
                        ? Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _smartSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 6,
                                  ),
                                  child: const Text('Sign Up with Email'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _smartSignUpWithGoogle,
                                  icon: const Icon(Icons.login),
                                  label: const Text('Sign Up with Google'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 6,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _signUpAndSaveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 6,
                              ),
                              child: const Text('Save'),
                            ),
                          )),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
