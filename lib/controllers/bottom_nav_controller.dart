import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import 'package:agribased/services/marketplace/firebase_marketplace_service_impl.dart';
import '../screens/dashboard_tool_screen.dart';
import '../screens/marketplace/marketplace_home_page.dart';
import '../screens/profile/farmer_profile_screen.dart';
import '../widgets/tractor_loading.dart';

class BottomNavController extends StatefulWidget {
  const BottomNavController({super.key});

  @override
  State<BottomNavController> createState() => _BottomNavControllerState();
}

class _BottomNavControllerState extends State<BottomNavController> {
  int currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = true;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _initializeScreens();
  }

  void _initializeScreens() {
    final currentUser = _auth.currentUser;
    final userId = currentUser?.uid ?? 'unknown';

    _screens = [
      const HomeScreen(),
      // Chat screen will be replaced with actual chat when needed
      // Using a placeholder for now since we need chatId and otherUserId
      const Scaffold(
        body: Center(child: Text('Select a chat to start messaging')),
      ),
      const DashboardToolScreen(),
      MarketplaceHomePage(
        marketplaceService: FirebaseMarketplaceService.instance,
      ),
      FarmerProfileScreen(userId: userId, currentUserId: userId),
    ];

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: TractorLoading()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgriBase Farmer Community'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Marketplace',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
