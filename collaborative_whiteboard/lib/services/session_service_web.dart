import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../models/session_model.dart';
import '../models/whiteboard_model.dart';
import '../models/whiteboard_user.dart';
import 'base_session_service.dart';

class SessionServiceWeb extends BaseSessionService {
  List<WhiteboardModel> _myWhiteboards = [];
  WhiteboardModel? _currentWhiteboard;
  WhiteboardUser? _currentUser;
  List<Map<String, dynamic>> _currentWhiteboardCollaborators = [];
  
  // For compatibility with dashboard_screen.dart
  List<WhiteboardSession> _mySessions = [];
  List<WhiteboardSession> _publicSessions = [];
  
  List<WhiteboardModel> get myWhiteboards => List.unmodifiable(_myWhiteboards);
  WhiteboardModel? get currentWhiteboard => _currentWhiteboard;
  WhiteboardUser? get currentUser => _currentUser;
  List<Map<String, dynamic>> get currentWhiteboardCollaborators => 
      List.unmodifiable(_currentWhiteboardCollaborators);
      
  // Compatibility getters for dashboard_screen.dart
  List<WhiteboardSession> get mySessions => List.unmodifiable(_mySessions);
  List<WhiteboardSession> get publicSessions => List.unmodifiable(_publicSessions);
  
  // Implementation of SessionModel getter
  @override
  SessionModel? get currentSession => null; // Default implementation
  
  // Fetch whiteboards where the user is a collaborator
  Future<void> fetchMyWhiteboards(String userId) async {
    try {
      final whiteboardsData = await DatabaseHelper.instance.getWhiteboardsForUser(userId);
      
      _myWhiteboards = whiteboardsData.map((wb) {
        return WhiteboardModel(
          id: wb['id'],
          name: wb['name'],
          ownerId: wb['owner_id'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(wb['created_at']),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(wb['updated_at']),
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching whiteboards: $e');
    }
  }
  
  // Set the current whiteboard
  Future<void> setCurrentWhiteboard(String whiteboardId) async {
    try {
      // Find whiteboard in myWhiteboards
      final whiteboard = _myWhiteboards.firstWhere(
        (wb) => wb.id == whiteboardId,
        orElse: () => throw Exception('Whiteboard not found'),
      );
      
      _currentWhiteboard = whiteboard;
      
      // Fetch collaborators for this whiteboard
      await fetchCollaborators(whiteboardId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting current whiteboard: $e');
    }
  }
  
  // Fetch collaborators for a whiteboard
  Future<void> fetchCollaborators(String whiteboardId) async {
    try {
      _currentWhiteboardCollaborators = await DatabaseHelper.instance.getCollaborators(whiteboardId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching collaborators: $e');
    }
  }
  
  // Set the current user
  void setCurrentUser(WhiteboardUser user) {
    _currentUser = user;
    notifyListeners();
  }
  
  // Create a new whiteboard
  Future<WhiteboardModel?> createWhiteboard(String userId, String name) async {
    try {
      final whiteboardId = await DatabaseHelper.instance.createWhiteboard(userId, name);
      
      if (whiteboardId == null) {
        return null;
      }
      
      final whiteboard = WhiteboardModel(
        id: whiteboardId,
        name: name,
        ownerId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      _myWhiteboards.add(whiteboard);
      notifyListeners();
      
      return whiteboard;
    } catch (e) {
      debugPrint('Error creating whiteboard: $e');
      return null;
    }
  }
  
  // Update a whiteboard
  Future<bool> updateWhiteboard(String whiteboardId, String name) async {
    try {
      final success = await DatabaseHelper.instance.updateWhiteboard(whiteboardId, name);
      
      if (success) {
        // Update the whiteboard in our list
        final index = _myWhiteboards.indexWhere((wb) => wb.id == whiteboardId);
        if (index != -1) {
          _myWhiteboards[index] = _myWhiteboards[index].copyWith(
            name: name,
            updatedAt: DateTime.now(),
          );
        }
        
        // Update current whiteboard if it's the one being updated
        if (_currentWhiteboard?.id == whiteboardId) {
          _currentWhiteboard = _currentWhiteboard!.copyWith(
            name: name,
            updatedAt: DateTime.now(),
          );
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error updating whiteboard: $e');
      return false;
    }
  }
  
  // Delete a whiteboard
  Future<bool> deleteWhiteboard(String whiteboardId) async {
    try {
      final success = await DatabaseHelper.instance.deleteWhiteboard(whiteboardId);
      
      if (success) {
        // Remove the whiteboard from our list
        _myWhiteboards.removeWhere((wb) => wb.id == whiteboardId);
        
        // Clear current whiteboard if it's the one being deleted
        if (_currentWhiteboard?.id == whiteboardId) {
          _currentWhiteboard = null;
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error deleting whiteboard: $e');
      return false;
    }
  }
  
  // Methods for dashboard_screen.dart
  Future<void> fetchMySessions() async {
    try {
      if (_currentUser == null) return;
      
      // Convert whiteboards to sessions format
      await fetchMyWhiteboards(_currentUser!.id);
      
      _mySessions = _myWhiteboards.map((whiteboard) {
        // Generate a simple session code
        final sessionCode = whiteboard.id.substring(0, 6).toUpperCase();
        
        return WhiteboardSession(
          id: whiteboard.id,
          name: whiteboard.name,
          creatorId: whiteboard.ownerId,
          creatorName: _currentUser?.displayName ?? 'Unknown',
          participants: const [],
          isPublic: true,
          createdAt: whiteboard.createdAt,
          sessionCode: sessionCode,
          inviteLink: 'http://localhost:3000/join/$sessionCode',
        );
      }).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching my sessions: $e');
    }
  }
  
  Future<void> fetchPublicSessions() async {
    try {
      // For now, we'll treat all whiteboards as public
      _publicSessions = _mySessions;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching public sessions: $e');
    }
  }
  
  Future<WhiteboardSession> createSession(String name, bool isPublic) async {
    try {
      final userId = _currentUser?.id ?? 'guest';
      final whiteboard = await createWhiteboard(userId, name);
      
      if (whiteboard == null) {
        throw Exception('Failed to create whiteboard');
      }
      
      // Generate a simple session code (in real app, should be unique)
      final sessionCode = whiteboard.id.substring(0, 6).toUpperCase();
      
      final session = WhiteboardSession(
        id: whiteboard.id,
        name: whiteboard.name,
        creatorId: userId,
        creatorName: _currentUser?.displayName ?? 'Guest',
        participants: const [],
        isPublic: isPublic,
        createdAt: whiteboard.createdAt,
        sessionCode: sessionCode,
        inviteLink: 'http://localhost:3000/join/$sessionCode',
      );
      
      _mySessions.add(session);
      if (isPublic) {
        _publicSessions.add(session);
      }
      
      notifyListeners();
      return session;
    } catch (e) {
      debugPrint('Error creating session: $e');
      throw Exception('Failed to create session: $e');
    }
  }
  
  Future<void> joinSession(String sessionId) async {
    try {
      if (_currentUser == null) throw Exception('User not logged in');
      
      // In real app, you would make an API call to join the session
      final session = _publicSessions.firstWhere(
        (s) => s.id == sessionId,
        orElse: () => throw Exception('Session not found'),
      );
      
      // Set the current whiteboard to this session's whiteboard
      await setCurrentWhiteboard(sessionId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error joining session: $e');
      throw Exception('Failed to join session: $e');
    }
  }
  
  Future<bool> isSessionValid(String sessionId) async {
    try {
      // Check if session exists in public or my sessions
      final exists = _publicSessions.any((s) => s.id == sessionId) ||
                     _mySessions.any((s) => s.id == sessionId);
      
      return exists;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }
  
  Future<void> deleteSession(String sessionId) async {
    try {
      // Remove from public and my sessions
      _publicSessions.removeWhere((s) => s.id == sessionId);
      _mySessions.removeWhere((s) => s.id == sessionId);
      
      // Also delete the whiteboard (since sessions are just whiteboards)
      await deleteWhiteboard(sessionId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
      throw Exception('Failed to delete session: $e');
    }
  }
}