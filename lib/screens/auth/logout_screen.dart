import 'package:flutter/material.dart';
import '../../controllers/auth_controller.dart';
import '../../services/auth_state_storage.dart';
import '../../services/secure_auth_service.dart';
import 'package:agribased/app/routes/app_routes.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    // Clear stored auth state
    await AuthStateStorage().clearLoginState();
    await SecureAuthService().clearAuthData();  // Clear stored password
    await AuthController.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Out'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/farmer_logout.png',
            fit: BoxFit.cover,
          ),
          Center(
            child: ElevatedButton(
              onPressed: () => _logout(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Confirm Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}
