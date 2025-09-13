// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import '../core/services/simplified_sync_service.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize simplified sync service (not EnhancedSyncService)
      await SimplifiedSyncService.instance.initialize();

      // Wait a moment for splash effect
      await Future.delayed(Duration(seconds: 2));

      // Navigate to dashboard
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } catch (e) {
      print('Initialization error: $e');
      // Still navigate to dashboard even if sync fails
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_pharmacy,
              size: 64,
              color: Colors.white,
            ),
            SizedBox(height: 16),
            Text(
              'PharmAssist Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}