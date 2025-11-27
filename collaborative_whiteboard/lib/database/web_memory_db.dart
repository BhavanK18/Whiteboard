// This file implements an in-memory database for web platform
// It simulates database operations when running on the web platform

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:uuid/uuid.dart';

class WebMemoryDB {
  static final WebMemoryDB _instance = WebMemoryDB._internal();

  factory WebMemoryDB() {
    return _instance;
  }

  WebMemoryDB._internal();

  // In-memory storage
  final Map<String, Map<String, dynamic>> _whiteboards = {};
  final Map<String, List<Map<String, dynamic>>> _elements = {};
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _sessions = {};
  final Map<String, List<Map<String, dynamic>>> _collaborators = {};

  // Save a whiteboard
  Future<bool> saveWhiteboard(Map<String, dynamic> whiteboard) async {
    try {
      final id = whiteboard['id'];
      _whiteboards[id] = whiteboard;
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error saving whiteboard: $e');
      return false;
    }
  }

  // Get a whiteboard
  Future<Map<String, dynamic>?> getWhiteboard(String whiteboardId) async {
    try {
      await _loadData();
      return _whiteboards[whiteboardId];
    } catch (e) {
      debugPrint('Error getting whiteboard: $e');
      return null;
    }
  }

  // Delete a whiteboard
  Future<bool> deleteWhiteboard(String whiteboardId) async {
    try {
      _whiteboards.remove(whiteboardId);
      _elements.remove(whiteboardId);
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error deleting whiteboard: $e');
      return false;
    }
  }

  // Save a drawing element
  Future<bool> saveElement(String whiteboardId, Map<String, dynamic> element) async {
    try {
      if (!_elements.containsKey(whiteboardId)) {
        _elements[whiteboardId] = [];
      }
      
      // Check for duplicates
      final index = _elements[whiteboardId]!.indexWhere((e) => e['id'] == element['id']);
      if (index >= 0) {
        // Replace existing element
        _elements[whiteboardId]![index] = element;
      } else {
        // Add new element
        _elements[whiteboardId]!.add(element);
      }
      
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error saving element: $e');
      return false;
    }
  }

  // Update a drawing element
  Future<bool> updateElement(String whiteboardId, Map<String, dynamic> element) async {
    try {
      if (!_elements.containsKey(whiteboardId)) {
        return false;
      }
      
      final index = _elements[whiteboardId]!.indexWhere((e) => e['id'] == element['id']);
      if (index < 0) {
        return false;
      }
      
      _elements[whiteboardId]![index] = element;
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error updating element: $e');
      return false;
    }
  }

  // Delete a drawing element
  // This is the actual method used by DatabaseHelper
  Future<bool> deleteWhiteboardElement(String whiteboardId, String elementId) async {
    try {
      if (!_elements.containsKey(whiteboardId)) {
        return false;
      }
      
      final beforeLength = _elements[whiteboardId]!.length;
      _elements[whiteboardId]!.removeWhere((e) => e['id'] == elementId);
      
      if (_elements[whiteboardId]!.length == beforeLength) {
        // Element wasn't found
        return false;
      }
      
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error deleting element: $e');
      return false;
    }
  }
  
  // Helper method to find whiteboard ID for an element
  Future<String?> getWhiteboardIdForElement(String elementId) async {
    try {
      await _loadData();
      
      for (final entry in _elements.entries) {
        for (final element in entry.value) {
          if (element['id'] == elementId) {
            return entry.key;
          }
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error finding whiteboard for element: $e');
      return null;
    }
  }

  // Clear all elements from a whiteboard
  Future<bool> clearElements(String whiteboardId) async {
    try {
      _elements[whiteboardId] = [];
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error clearing elements: $e');
      return false;
    }
  }

  // Get all drawing elements for a whiteboard
  Future<List<Map<String, dynamic>>> getElements(String whiteboardId) async {
    try {
      await _loadData();
      return _elements[whiteboardId] ?? [];
    } catch (e) {
      debugPrint('Error getting elements: $e');
      return [];
    }
  }

  // User-related methods
  Future<String?> createUser(String email, String passwordHash, String displayName) async {
    try {
      await _loadData();
      
      // Check if user already exists
      if (_users.values.any((user) => user['email'] == email)) {
        return null;
      }
      
      final userId = const Uuid().v4();
      _users[userId] = {
        'id': userId,
        'email': email,
        'password_hash': passwordHash,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
        'last_login': DateTime.now().toIso8601String()
      };
      
      await _persistData();
      return userId;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      await _loadData();
      return _users.values.firstWhere(
        (user) => user['email'] == email,
        orElse: () => {},
      );
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }
  
  Future<String?> getUserIdByEmail(String email) async {
    try {
      final user = await getUserByEmail(email);
      return user?['id'];
    } catch (e) {
      debugPrint('Error getting user ID by email: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      await _loadData();
      return _users[userId];
    } catch (e) {
      debugPrint('Error getting user by ID: $e');
      return null;
    }
  }
  
  Future<bool> validateUserPassword(String email, String passwordHash) async {
    try {
      final user = await getUserByEmail(email);
      return user != null && user['password_hash'] == passwordHash;
    } catch (e) {
      debugPrint('Error validating user password: $e');
      return false;
    }
  }
  
  Future<bool> resetPassword(String email, String newPasswordHash) async {
    try {
      final user = await getUserByEmail(email);
      if (user == null) return false;
      
      final userId = user['id'];
      _users[userId]?['password_hash'] = newPasswordHash;
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return false;
    }
  }
  
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      await _loadData();
      if (!_users.containsKey(userId)) return false;
      
      _users[userId]!.addAll(updates);
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
  
  Future<bool> updateUserLastLogin(String userId) async {
    try {
      await _loadData();
      if (!_users.containsKey(userId)) return false;
      
      _users[userId]!['last_login'] = DateTime.now().toIso8601String();
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error updating user last login: $e');
      return false;
    }
  }
  
  // Session management
  Future<String?> createSession(String userId) async {
    try {
      await _loadData();
      if (!_users.containsKey(userId)) return null;
      
      final sessionId = const Uuid().v4();
      _sessions[sessionId] = {
        'id': sessionId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String()
      };
      
      await _persistData();
      return sessionId;
    } catch (e) {
      debugPrint('Error creating session: $e');
      return null;
    }
  }
  
  Future<String?> getUserIdFromToken(String token) async {
    try {
      await _loadData();
      final session = _sessions[token];
      if (session == null) return null;
      
      final expiresAt = DateTime.parse(session['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) {
        _sessions.remove(token); // Remove expired session
        await _persistData();
        return null;
      }
      
      return session['user_id'];
    } catch (e) {
      debugPrint('Error getting user ID from token: $e');
      return null;
    }
  }
  
  // Whiteboard management
  Future<String?> createWhiteboard(String ownerId, String name) async {
    try {
      await _loadData();
      
      final whiteboardId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      _whiteboards[whiteboardId] = {
        'id': whiteboardId,
        'name': name,
        'owner_id': ownerId,
        'created_at': now,
        'updated_at': now
      };
      
      // Initialize empty elements list
      _elements[whiteboardId] = [];
      
      // Add owner as collaborator
      _collaborators[whiteboardId] = [{
        'whiteboard_id': whiteboardId,
        'user_id': ownerId,
        'role': 'owner',
        'joined_at': now
      }];
      
      await _persistData();
      return whiteboardId;
    } catch (e) {
      debugPrint('Error creating whiteboard: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getWhiteboardsForUser(String userId) async {
    try {
      await _loadData();
      
      // Get all collaborator records for the user
      final allCollabs = <String>[];
      _collaborators.forEach((whiteboardId, collabs) {
        if (collabs.any((c) => c['user_id'] == userId)) {
          allCollabs.add(whiteboardId);
        }
      });
      
      // Get whiteboards data
      final result = <Map<String, dynamic>>[];
      for (final wbId in allCollabs) {
        if (_whiteboards.containsKey(wbId)) {
          result.add(_whiteboards[wbId]!);
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('Error getting whiteboards for user: $e');
      return [];
    }
  }
  
  Future<bool> updateWhiteboard(String whiteboardId, String name) async {
    try {
      await _loadData();
      
      if (!_whiteboards.containsKey(whiteboardId)) return false;
      
      _whiteboards[whiteboardId]!['name'] = name;
      _whiteboards[whiteboardId]!['updated_at'] = DateTime.now().millisecondsSinceEpoch;
      
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error updating whiteboard: $e');
      return false;
    }
  }
  
  // Collaborator management
  Future<bool> addCollaborator(String whiteboardId, String userId, String role) async {
    try {
      await _loadData();
      
      if (!_whiteboards.containsKey(whiteboardId)) return false;
      
      // Initialize collaborators list if it doesn't exist
      _collaborators[whiteboardId] ??= [];
      
      // Check if user is already a collaborator
      if (_collaborators[whiteboardId]!.any((c) => c['user_id'] == userId)) {
        // Update role if already a collaborator
        final index = _collaborators[whiteboardId]!.indexWhere((c) => c['user_id'] == userId);
        _collaborators[whiteboardId]![index]['role'] = role;
      } else {
        // Add new collaborator
        _collaborators[whiteboardId]!.add({
          'whiteboard_id': whiteboardId,
          'user_id': userId,
          'role': role,
          'joined_at': DateTime.now().millisecondsSinceEpoch
        });
      }
      
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error adding collaborator: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getCollaborators(String whiteboardId) async {
    try {
      await _loadData();
      
      if (!_whiteboards.containsKey(whiteboardId)) return [];
      
      return _collaborators[whiteboardId] ?? [];
    } catch (e) {
      debugPrint('Error getting collaborators: $e');
      return [];
    }
  }
  
  Future<bool> removeCollaborator(String whiteboardId, String userId) async {
    try {
      await _loadData();
      
      if (!_whiteboards.containsKey(whiteboardId)) return false;
      if (!_collaborators.containsKey(whiteboardId)) return false;
      
      _collaborators[whiteboardId]!.removeWhere((c) => c['user_id'] == userId);
      
      await _persistData();
      return true;
    } catch (e) {
      debugPrint('Error removing collaborator: $e');
      return false;
    }
  }
  
  // Element management
  Future<String?> addElement(String whiteboardId, String userId, String type, Map<String, dynamic> properties) async {
    try {
      await _loadData();
      
      if (!_whiteboards.containsKey(whiteboardId)) return null;
      
      // Initialize elements list if it doesn't exist
      _elements[whiteboardId] ??= [];
      
      final elementId = const Uuid().v4();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      _elements[whiteboardId]!.add({
        'id': elementId,
        'whiteboard_id': whiteboardId,
        'created_by': userId,
        'type': type,
        'properties': properties,
        'created_at': now,
        'updated_at': now
      });
      
      await _persistData();
      return elementId;
    } catch (e) {
      debugPrint('Error adding element: $e');
      return null;
    }
  }
  
  Future<bool> deleteElement(String whiteboardId, String elementId) async {
    try {
      await _loadData();
      
      if (!_elements.containsKey(whiteboardId)) return false;
      
      final originalLength = _elements[whiteboardId]!.length;
      _elements[whiteboardId]!.removeWhere((e) => e['id'] == elementId);
      
      final deleted = _elements[whiteboardId]!.length < originalLength;
      
      if (deleted) {
        await _persistData();
      }
      
      return deleted;
    } catch (e) {
      debugPrint('Error deleting element: $e');
      return false;
    }
  }

  // Persist data to local storage
  Future<void> _persistData() async {
    if (!kIsWeb) return; // Only persist on web
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store whiteboards
      final whiteboardsJson = jsonEncode(_whiteboards);
      await prefs.setString('whiteboards', whiteboardsJson);
      
      // Store elements (may need to limit size)
      final elementsJson = jsonEncode(_elements);
      await prefs.setString('elements', elementsJson);
      
      // Store users
      final usersJson = jsonEncode(_users);
      await prefs.setString('users', usersJson);
      
      // Store sessions
      final sessionsJson = jsonEncode(_sessions);
      await prefs.setString('sessions', sessionsJson);
      
      // Store collaborators
      final collaboratorsJson = jsonEncode(_collaborators);
      await prefs.setString('collaborators', collaboratorsJson);
    } catch (e) {
      debugPrint('Error persisting data: $e');
    }
  }

  // Load data from local storage
  Future<void> _loadData() async {
    if (!kIsWeb) return; // Only load on web
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load whiteboards
      final whiteboardsJson = prefs.getString('whiteboards');
      if (whiteboardsJson != null) {
        final decoded = jsonDecode(whiteboardsJson) as Map<String, dynamic>;
        _whiteboards.clear();
        decoded.forEach((key, value) {
          _whiteboards[key] = value as Map<String, dynamic>;
        });
      }
      
      // Load elements
      final elementsJson = prefs.getString('elements');
      if (elementsJson != null) {
        final decoded = jsonDecode(elementsJson) as Map<String, dynamic>;
        _elements.clear();
        decoded.forEach((key, value) {
          _elements[key] = (value as List).map((e) => e as Map<String, dynamic>).toList();
        });
      }
      
      // Load users
      final usersJson = prefs.getString('users');
      if (usersJson != null) {
        final decoded = jsonDecode(usersJson) as Map<String, dynamic>;
        _users.clear();
        decoded.forEach((key, value) {
          _users[key] = value as Map<String, dynamic>;
        });
      }
      
      // Load sessions
      final sessionsJson = prefs.getString('sessions');
      if (sessionsJson != null) {
        final decoded = jsonDecode(sessionsJson) as Map<String, dynamic>;
        _sessions.clear();
        decoded.forEach((key, value) {
          _sessions[key] = value as Map<String, dynamic>;
        });
      }
      
      // Load collaborators
      final collaboratorsJson = prefs.getString('collaborators');
      if (collaboratorsJson != null) {
        final decoded = jsonDecode(collaboratorsJson) as Map<String, dynamic>;
        _collaborators.clear();
        decoded.forEach((key, value) {
          _collaborators[key] = (value as List).map((e) => e as Map<String, dynamic>).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }
}