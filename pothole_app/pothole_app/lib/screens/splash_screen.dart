import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../routes/routes.dart';
import '../api/api_manager.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check for stored token and validate it
    String? token;
    bool isTokenValid = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('jwt_token');

      if (token != null) {
        // Validate token by making a test API call
        ApiManager.instance.setToken(token);
        try {
          await ApiManager.instance.getProfile();
          isTokenValid = true;
        } catch (e) {
          // Token is invalid, remove it
          await prefs.remove('jwt_token');
          token = null;
          ApiManager.instance.setToken('');
        }
      }
    } catch (e) {
      // SharedPreferences not available, proceed without token
      token = null;
    }

    // Navigate to appropriate screen
    if (mounted) {
      Get.offAllNamed(isTokenValid ? Routes.root : Routes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0046FF), Color(0xFF00C07F)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.visibility,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pothole Detector',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0046FF),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0046FF)),
            ),
          ],
        ),
      ),
    );
  }
}
