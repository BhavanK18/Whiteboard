import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import 'login_screen_new.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _initialized = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    try {
      // Add a slight delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));
      
      if (!mounted) return;
      
      // Skip authentication and create a dummy user
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.setAutomaticSignIn();
      
      // Mark as initialized
      setState(() {
        _initialized = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
      // Navigate to appropriate screen if initialization is complete
    if (_initialized) {
      // Use Future.microtask to avoid build-time navigation
      Future.microtask(() {
        // Display a quick message about auto-login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bypassing login - Auto-signed in as Guest User'))
        );
        
        // Always go directly to dashboard, bypassing authentication check
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      });
    }    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.draw,
                size: 60,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'Collaborative Whiteboard',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            // Using SQLite database instead of Firebase
            const SizedBox(height: 32),
            // Error message or loading indicator
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Error: $_errorMessage',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              )
            else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}