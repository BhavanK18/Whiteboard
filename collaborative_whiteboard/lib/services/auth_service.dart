import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../services/session_manager.dart';
import '../models/whiteboard_user.dart';

class AuthService extends ChangeNotifier {
  String? _userId;
  String? _sessionToken;
  Map<String, dynamic>? _userData;

  bool get isSignedIn => _userId != null;
  String? get currentUserId => _userId;
  String? get displayName => _userData?['display_name'];
  String? get email => _userData?['email'];
  String? get photoUrl => _userData?['photo_url'];

  // Initialize from stored token if available
  Future<void> initializeFromStoredToken(String? token) async {
    if (token != null) {
      final userId = await DatabaseHelper.instance.getUserIdFromToken(token);
      if (userId != null) {
        _sessionToken = token;
        _userId = userId;
        _userData = await DatabaseHelper.instance.getUserById(userId);
        notifyListeners();
      }
    }
  }
  
  // Automatically sign in with a default user (for bypassing authentication)
  Future<void> setAutomaticSignIn() async {
    try {
      // Check if "guest" user exists, create it if not
      final userMap = await DatabaseHelper.instance.getUserByEmail("guest@example.com");
      String? userId = userMap?['id'];
      
      if (userId == null) {
        // Create a guest user if it doesn't exist
        userId = await DatabaseHelper.instance.createUser(
          "guest@example.com", 
          "guest_password", 
          "Guest User"
        );
      }
      
      if (userId != null) {
        // Sign in as the guest user
        await _signInWithUserId(userId);
        
        // Save the session token for persistence
        if (_sessionToken != null) {
          await SessionManager.saveAuthToken(_sessionToken!);
        }
      }
    } catch (e) {
      debugPrint('Error during automatic sign-in: $e');
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmail(String email, String password, String displayName) async {
    try {
      debugPrint('Starting sign up process for email: $email');
      
      // Check if user already exists
      final existingUser = await DatabaseHelper.instance.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('The email address is already in use by another account.');
      }
      
      // Create user
      final userId = await DatabaseHelper.instance.createUser(email, password, displayName);
      
      if (userId == null) {
        throw Exception('Failed to create user account.');
      }

      // Sign in the user after successful registration
      await _signInWithUserId(userId);
      
      return true;
    } catch (e) {
      debugPrint('Error during signup: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      debugPrint('Attempting to sign in user with email: $email');

      // Validate credentials
      final isValid = await DatabaseHelper.instance.validateUserPassword(email, password);
      
      if (!isValid) {
        throw Exception('Invalid email or password.');
      }

      // Get user data
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      
      if (user == null) {
        throw Exception('User not found.');
      }
      
      // Sign in
      await _signInWithUserId(user['id']);
      
      return true;
    } catch (e) {
      debugPrint('Error during sign in: $e');
      rethrow;
    }
  }

  // Get current user information
  Map<String, dynamic>? get userData => _userData;

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      // In a real app, you would send an email with a verification token
      // For this SQLite implementation, we'll just reset to a default password
      // that the user would be prompted to change on next login
      
      // First check if user exists
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      
      if (user == null) {
        throw Exception('No user found with this email address.');
      }
      
      // Reset to default password (in real app, this would be a random token)
      const newPassword = 'ChangeMeOnNextLogin123!'; 
      
      final success = await DatabaseHelper.instance.resetPassword(email, newPassword);
      
      if (!success) {
        throw Exception('Failed to reset password.');
      }
      
      // In a real app, you would send an email with the temporary password
      debugPrint('Password reset successful for $email. Email would be sent with temporary password.');
    } catch (e) {
      debugPrint('Error during password reset: $e');
      rethrow;
    }
  }
  
  // Sign out
  Future<void> signOut() async {
    try {
      if (_sessionToken != null) {
        await DatabaseHelper.instance.deleteSession(_sessionToken!);
      }
      _userId = null;
      _userData = null;
      _sessionToken = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during sign out: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoUrl}) async {
    try {
      if (_userId == null) {
        throw Exception('User not logged in.');
      }
      
      Map<String, dynamic> updates = {};
      if (displayName != null) updates['display_name'] = displayName;
      if (photoUrl != null) updates['photo_url'] = photoUrl;
      
      final success = await DatabaseHelper.instance.updateUserProfile(_userId!, updates);
      
      if (!success) {
        throw Exception('Failed to update profile.');
      }
      
      // Refresh user data
      _userData = await DatabaseHelper.instance.getUserById(_userId!);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  // Helper method to complete sign in process
  Future<void> _signInWithUserId(String userId) async {
    Map<String, dynamic>? userData;
    String? token;

    try {
      await DatabaseHelper.instance.updateUserLastLogin(userId);
      token = await DatabaseHelper.instance.createUserSession(
        userId,
        "web-device",
        "127.0.0.1",
      );
      userData = await DatabaseHelper.instance.getUserById(userId);
    } catch (e) {
      debugPrint('Error completing sign in via database: $e');
    }

    token ??= const Uuid().v4();
    userData ??= {
      'id': userId,
      'display_name': 'Guest User',
      'email': 'guest@example.com',
      'photo_url': null,
      'created_at': DateTime.now().toIso8601String(),
      'last_login': DateTime.now().toIso8601String(),
    };

    _userId = userId;
    _userData = userData;
    _sessionToken = token;

    notifyListeners();
  }

  // Get current user data as WhiteboardUser
  Future<WhiteboardUser?> getCurrentUserData() async {
    if (_userId == null) return null;

    try {
      if (_userData == null) {
        _userData = await DatabaseHelper.instance.getUserById(_userId!);
      }
      
      if (_userData != null) {
        return WhiteboardUser(
          id: _userId!,
          name: _userData!['display_name'] ?? 'User',
          email: _userData!['email'] ?? '',
          displayName: _userData!['display_name'] ?? 'User',
          photoURL: _userData!['photo_url'],
          isOnline: true,
          createdAt: DateTime.parse(_userData!['created_at'] ?? DateTime.now().toIso8601String()),
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Get session token (for storing in shared preferences)
  String? getSessionToken() => _sessionToken;
}