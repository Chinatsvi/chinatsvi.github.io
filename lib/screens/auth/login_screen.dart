import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/routes/app_routes.dart';
import '../../controllers/auth_controller.dart';
import '../../services/secure_auth_service.dart';
import '../../services/auth_state_storage.dart';
import '../../services/cache/profile_cache_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool isLoading = false;
  final AuthController _authController = AuthController();
  final SecureAuthService _secureAuth = SecureAuthService();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeIn;

  /// Check if farmer profile exists
  Future<bool> _farmerProfileExists(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('farmers')
        .doc(uid)
        .get();
    return doc.exists;
  }

  /// Login with Email & Password
  Future<void> _login() async {
    if (_formKey.currentState?.validate() != true || !mounted) return;
    setState(() => isLoading = true);

    try {
      final user = await _authController.signInWithEmail(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (user == null || !mounted) return;

      final exists = await _farmerProfileExists(user.uid);
      if (!mounted) return;

      if (exists) {
        // Save login state for next app startup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('was_logged_in', true);
        await prefs.setString('cached_user_id', user.uid);
        
        // Verify save worked
        final verifyLoggedIn = prefs.getBool('was_logged_in');
        final verifyUserId = prefs.getString('cached_user_id');
        print('✅ [LOGIN] Saved login state for user: ${user.uid}');
        print('✅ [LOGIN] Verify saved: logged_in=$verifyLoggedIn, uid=$verifyUserId');

        // Save email/password for auto re-login
        await _secureAuth.saveLoginCredentials(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        // Save secure credentials for offline access
        await _secureAuth.saveAuthCredentials(user);
        print('✅ [LOGIN] Saved secure credentials for offline access');

        // Save to AuthStateStorage for community screen cache
        final storage = AuthStateStorage();
        await storage.init();
        await storage.saveLoginState(user.uid);
        final farmerDoc = await FirebaseFirestore.instance.collection('farmers').doc(user.uid).get();
        if (farmerDoc.exists) {
          final data = farmerDoc.data() ?? {};
          await storage.saveCachedProfile(
            uid: user.uid,
            userName: data['user_name'] ?? data['name'],
            profilePic: data['profile_pic'] ?? data['profile_image_url'],
          );
          // 🔥 Cache full profile to Hive for offline dashboard/tools support
          await ProfileCacheService.cacheProfile(user.uid, data);
          print('✅ [LOGIN] Cached full profile to Hive for offline use');
        }

        // 🔥 DIAGNOSTIC: Print UID after login
        print("🔥 UID AFTER LOGIN: ${FirebaseAuth.instance.currentUser?.uid}");

        // Firebase Auth handles persistence automatically
        Navigator.pushReplacementNamed(context, AppRoutes.community);
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No farmer profile found. Please complete your profile first.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  /// Google Login
  Future<void> _loginWithGoogle() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      final user = await _authController.signInWithGoogle();
      if (user == null || !mounted) return;

      final exists = await _farmerProfileExists(user.uid);
      if (!mounted) return;

      if (exists) {
        // Save login state for next app startup
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('was_logged_in', true);
        await prefs.setString('cached_user_id', user.uid);
        
        // Verify save worked
        final verifyLoggedIn = prefs.getBool('was_logged_in');
        final verifyUserId = prefs.getString('cached_user_id');
        print('✅ [LOGIN] Saved login state for user: ${user.uid}');
        print('✅ [LOGIN] Verify saved: logged_in=$verifyLoggedIn, uid=$verifyUserId');

        // 🔥 Google login - save user email for identification
        // We need email to know which user to restore
        if (user.email != null && user.email!.isNotEmpty) {
          await _secureAuth.saveLoginCredentials(
            user.email!,
            'GOOGLE_OAUTH', // Marker for Google auth
          );
          print('✅ [LOGIN] Saved Google login marker for: ${user.email}');
        }

        // Save secure credentials for offline access
        await _secureAuth.saveAuthCredentials(user);
        print('✅ [LOGIN] Saved secure credentials for offline access');

        // Save to AuthStateStorage for community screen cache
        final storage = AuthStateStorage();
        await storage.init();
        await storage.saveLoginState(user.uid);
        final farmerDoc = await FirebaseFirestore.instance.collection('farmers').doc(user.uid).get();
        if (farmerDoc.exists) {
          final data = farmerDoc.data() ?? {};
          await storage.saveCachedProfile(
            uid: user.uid,
            userName: data['user_name'] ?? data['name'],
            profilePic: data['profile_pic'] ?? data['profile_image_url'],
          );
          // 🔥 Cache full profile to Hive for offline dashboard/tools support
          await ProfileCacheService.cacheProfile(user.uid, data);
          print('✅ [LOGIN] Cached full profile to Hive for offline use');
        }

        // 🔥 DIAGNOSTIC: Print UID after Google login
        print("🔥 UID AFTER GOOGLE LOGIN: ${FirebaseAuth.instance.currentUser?.uid}");
        
        // Firebase Auth handles persistence automatically
        Navigator.pushReplacementNamed(context, AppRoutes.community);
      } else {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No farmer profile found. Please complete your profile first.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Google login failed: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }



  void _goToSignUp() {
    Navigator.pushReplacementNamed(context, AppRoutes.signup);
  }

  void _goToForgotPassword() {
    Navigator.pushNamed(context, AppRoutes.forgotPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Farmer Login'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // full-screen background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/login_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // warm overlay to improve contrast
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          // main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: ListView(
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        'Welcome back, Farmer 🌾',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),

                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v?.isEmpty != false ? 'Enter your email' : null,
                      ),
                      const SizedBox(height: 15),

                      TextFormField(
                        controller: passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Colors.white),
                        validator: (v) => v?.isEmpty != false ? 'Enter your password' : null,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _goToForgotPassword,
                          child: const Text(
                            'Forgot password?',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[700],
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 6,
                                    ),
                                    child: const Text('Login with Email', style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _loginWithGoogle,
                                    icon: const Icon(Icons.login),
                                    label: const Text('Login with Google'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 6,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('No account yet?', style: TextStyle(color: Colors.white)),
                          TextButton(
                            onPressed: _goToSignUp,
                            child: const Text('Sign Up', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeIn = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    WidgetsBinding.instance.addPostFrameCallback((_) => _animCtrl.forward());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
