import 'package:flutter/material.dart';

/// 🔥 DEPRECATED - DO NOT USE
/// AuthGate has been replaced by AppInitializer as the single entry point.
/// Using this widget will cause navigation conflicts.
/// 
/// AppInitializer is now the ONLY place that decides routing.
/// 
/// If you see this screen, the app was not properly initialized.
@Deprecated('Use AppInitializer instead. This widget is no longer maintained.')
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Error: AuthGate is deprecated.\nUse AppInitializer instead.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
