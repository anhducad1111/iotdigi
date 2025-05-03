import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'ocr_screen.dart';
import 'sensor_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  
  final List<Widget> _screens = [
    const OcrScreen(),
    const SensorScreen(),
    const StatsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    try {
      await Provider.of<AuthService>(context, listen: false).logout();
      if (!mounted) return;

      // Clear all routes and navigate to login
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false, // Remove all existing routes
      );
    } catch (e) {
      if (!mounted) return;
      
      // Show error if logout fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đăng xuất: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTitle(int index) {
    switch (index) {
      case 0:
        return 'Chụp chỉ số nước';
      case 1:
        return 'Cảm biến';
      case 2:
        return 'Thống kê';
      default:
        return 'IoT Digi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(_selectedIndex)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: WillPopScope(
        // Prevent back navigation when authenticated
        onWillPop: () async => false,
        child: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Chỉ số',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sensors),
            label: 'Cảm biến',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Thống kê',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}