// A simple in-memory database for web platform
import 'dart:math';
import 'package:flutter/foundation.dart';

class WebMemoryDB {
  static final WebMemoryDB _instance = WebMemoryDB._internal();
  factory WebMemoryDB() => _instance;
  
  WebMemoryDB._internal();
  
  // In-memory storage
  final Map<String, Map<String, dynamic>> _users = {};
  final Map<String, Map<String, dynamic>> _whiteboards = {};
  final Map<String, List<Map<String, dynamic>>> _collaborators = {};
  final Map<String, List<Map<String, dynamic>>> _elements = {};
  final Map<String, Map<String, dynamic>> _sessions = {};
  
  // Generate a simple random ID
  String _generateId() {
    final random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(20, (index) => chars[random.nextInt(chars.length)]).join();
  }
  
  // User methods
  Future<String?> createUser(String email, String passwordHash, String displayName) async {
    try {
      final userId = _generateId();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      _users[userId] = {
        'id': userId,
        'email': email,
        'password_hash': passwordHash,
        'display_name': displayName,
        'created_at': now,
        'last_login': now,
      };
      
      return userId;
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }
  
  Future<String?> getUserIdByEmail(String email) async {
    try {
      final user = _users.entries.firstWhere(
        (entry) => entry.value['email'] == email,
        orElse: () => MapEntry('', {}),
      );
      
      return user.key.isNotEmpty ? user.key : null;
    } catch (e) {
      debugPrint('Error getting user ID by email: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    return _users[userId];
  }
  
  // Whiteboard methods
  Future<String?> createWhiteboard(String userId, String name) async {
    try {
      final whiteboardId = _generateId();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      _whiteboards[whiteboardId] = {
        'id': whiteboardId,
        'owner_id': userId,
        'name': name,
        'created_at': now,
        'updated_at': now,
      };
      
      // Add the creator as a collaborator
      _collaborators[whiteboardId] = [{
        'whiteboard_id': whiteboardId,
        'user_id': userId,
        'role': 'owner',
        'joined_at': now,
      }];
      
      // Initialize empty elements list
      _elements[whiteboardId] = [];
      
      return whiteboardId;
    } catch (e) {
      debugPrint('Error creating whiteboard: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getWhiteboardsForUser(String userId) async {
    try {
      final whiteboards = <Map<String, dynamic>>[];
      
      // Get whiteboards owned by the user
      final ownedWhiteboards = _whiteboards.values
          .where((wb) => wb['owner_id'] == userId)
          .toList();
      
      whiteboards.addAll(ownedWhiteboards);
      
      // Get whiteboards where the user is a collaborator
      for (final entry in _collaborators.entries) {
        final whiteboardId = entry.key;
        final collaboratorsList = entry.value;
        
        if (collaboratorsList.any((collab) => collab['user_id'] == userId)) {
          if (!whiteboards.any((wb) => wb['id'] == whiteboardId)) {
            final whiteboard = _whiteboards[whiteboardId];
            if (whiteboard != null) {
              whiteboards.add(whiteboard);
            }
          }
        }
      }
      
      return whiteboards;
    } catch (e) {
      debugPrint('Error getting whiteboards for user: $e');
      return [];
    }
  }
  
  Future<bool> deleteWhiteboard(String whiteboardId) async {
    try {
      _whiteboards.remove(whiteboardId);
      _collaborators.remove(whiteboardId);
      _elements.remove(whiteboardId);
      return true;
    } catch (e) {
      debugPrint('Error deleting whiteboard: $e');
      return false;
    }
  }
  
  Future<bool> updateWhiteboard(String whiteboardId, String name) async {
    try {
      final whiteboard = _whiteboards[whiteboardId];
      if (whiteboard != null) {
        whiteboard['name'] = name;
        whiteboard['updated_at'] = DateTime.now().millisecondsSinceEpoch;
        _whiteboards[whiteboardId] = whiteboard;
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating whiteboard: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getWhiteboard(String whiteboardId) async {
    return _whiteboards[whiteboardId];
  }
  
  // Collaborators methods
  Future<List<Map<String, dynamic>>> getCollaborators(String whiteboardId) async {
    return _collaborators[whiteboardId] ?? [];
  }
  
  Future<bool> addCollaborator(String whiteboardId, String userId, String role) async {
    try {
      final collaboratorsList = _collaborators[whiteboardId] ?? [];
      
      // Check if user is already a collaborator
      if (collaboratorsList.any((collab) => collab['user_id'] == userId)) {
        return true;
      }
      
      collaboratorsList.add({
        'whiteboard_id': whiteboardId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().millisecondsSinceEpoch,
      });
      
      _collaborators[whiteboardId] = collaboratorsList;
      return true;
    } catch (e) {
      debugPrint('Error adding collaborator: $e');
      return false;
    }
  }
  
  Future<bool> removeCollaborator(String whiteboardId, String userId) async {
    try {
      final collaboratorsList = _collaborators[whiteboardId] ?? [];
      
      _collaborators[whiteboardId] = collaboratorsList
          .where((collab) => collab['user_id'] != userId)
          .toList();
      
      return true;
    } catch (e) {
      debugPrint('Error removing collaborator: $e');
      return false;
    }
  }
  
  // Elements methods
  Future<String?> addElement(String whiteboardId, String userId, String type, Map<String, dynamic> properties) async {
    try {
      final elementId = _generateId();
      final now = DateTime.now().millisecondsSinceEpoch;
      
      final element = {
        'id': elementId,
        'whiteboard_id': whiteboardId,
        'user_id': userId,
        'type': type,
        'properties': properties,
        'created_at': now,
        'updated_at': now,
      };
      
      final elementsList = _elements[whiteboardId] ?? [];
      elementsList.add(element);
      _elements[whiteboardId] = elementsList;
      
      return elementId;
    } catch (e) {
      debugPrint('Error adding element: $e');
      return null;
    }
  }
  
  Future<List<Map<String, dynamic>>> getElements(String whiteboardId) async {
    return _elements[whiteboardId] ?? [];
  }
  
  Future<bool> updateElement(String elementId, Map<String, dynamic> properties) async {
    try {
      for (final entry in _elements.entries) {
        final elementsList = entry.value;
        final index = elementsList.indexWhere((elem) => elem['id'] == elementId);
        
        if (index != -1) {
          elementsList[index]['properties'] = properties;
          elementsList[index]['updated_at'] = DateTime.now().millisecondsSinceEpoch;
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error updating element: $e');
      return false;
    }
  }
  
  Future<bool> deleteElement(String elementId) async {
    try {
      for (final entry in _elements.entries) {
        final whiteboardId = entry.key;
        final elementsList = entry.value;
        
        final newList = elementsList.where((elem) => elem['id'] != elementId).toList();
        
        if (newList.length != elementsList.length) {
          _elements[whiteboardId] = newList;
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error deleting element: $e');
      return false;
    }
  }
  
  // Session methods
  Future<String?> createSession(String userId, String token, int expiresAt) async {
    try {
      final sessionId = _generateId();
      
      _sessions[sessionId] = {
        'id': sessionId,
        'user_id': userId,
        'token': token,
        'expires_at': expiresAt,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      return sessionId;
    } catch (e) {
      debugPrint('Error creating session: $e');
      return null;
    }
  }
  
  Future<String?> getUserIdFromToken(String token) async {
    try {
      final session = _sessions.values.firstWhere(
        (s) => s['token'] == token && s['expires_at'] > DateTime.now().millisecondsSinceEpoch,
        orElse: () => {},
      );
      
      return session['user_id'] as String?;
    } catch (e) {
      debugPrint('Error getting user ID from token: $e');
      return null;
    }
  }
}