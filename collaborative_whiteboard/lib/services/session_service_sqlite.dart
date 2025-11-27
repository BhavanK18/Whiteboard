import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../models/session_model.dart';
import '../models/whiteboard_model.dart';
import '../models/whiteboard_user.dart';
import 'base_session_service.dart';

class SessionServiceSQLite extends BaseSessionService {
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
  
  // Implementation of missing required methods
  @override
  void setCurrentUser(WhiteboardUser user) {
    _currentUser = user;
    notifyListeners();
  }
  
  @override
  Future<void> setCurrentWhiteboard(String whiteboardId) async {
    try {
      final whiteboard = await WhiteboardModel.load(whiteboardId);
      if (whiteboard != null) {
        _currentWhiteboard = whiteboard;
        await fetchCollaborators(whiteboardId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting current whiteboard: $e');
    }
  }
  
  @override
  Future<bool> updateWhiteboard(String whiteboardId, String name) async {
    try {
      // Find the whiteboard
      final whiteboard = await WhiteboardModel.load(whiteboardId);
      if (whiteboard == null) return false;
      
      final success = await whiteboard.updateName(name);
      
      if (success) {
        // Update the whiteboard in the list too
        final index = _myWhiteboards.indexWhere((wb) => wb.id == whiteboardId);
        if (index >= 0) {
          _myWhiteboards[index].name = name;
        }
        
        // Update current whiteboard if it's the same one
        if (_currentWhiteboard?.id == whiteboardId) {
          _currentWhiteboard!.name = name;
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error updating whiteboard: $e');
      return false;
    }
  }
  
  // Fetch whiteboards where the user is a collaborator
  Future<void> fetchMyWhiteboards(String userId) async {
    try {
      final whiteboardsData = await DatabaseHelper.instance.getWhiteboardsForUser(userId);
      
      _myWhiteboards = await Future.wait(
        whiteboardsData.map((wb) async {
          return WhiteboardModel(
            id: wb['id'],
            name: wb['name'],
            ownerId: wb['owner_id'],
            createdAt: DateTime.fromMillisecondsSinceEpoch(wb['created_at']),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(wb['updated_at']),
          );
        }),
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching my whiteboards: $e');
    }
  }
  
  // Create a new whiteboard
  Future<WhiteboardModel?> createWhiteboard(String userId, String name) async {
    try {
      final newWhiteboard = await WhiteboardModel.create(userId, name);
      
      if (newWhiteboard != null) {
        _myWhiteboards.add(newWhiteboard);
        notifyListeners();
      }
      
      return newWhiteboard;
    } catch (e) {
      debugPrint('Error creating whiteboard: $e');
      return null;
    }
  }
  
  // Delete a whiteboard
  Future<bool> deleteWhiteboard(String whiteboardId) async {
    try {
      final success = await DatabaseHelper.instance.deleteWhiteboard(whiteboardId);
      
      if (success) {
        _myWhiteboards.removeWhere((wb) => wb.id == whiteboardId);
        
        // If the current whiteboard was deleted, clear it
        if (_currentWhiteboard?.id == whiteboardId) {
          _currentWhiteboard = null;
          _currentWhiteboardCollaborators = [];
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error deleting whiteboard: $e');
      return false;
    }
  }
  
  // Open a whiteboard
  Future<bool> openWhiteboard(String whiteboardId, WhiteboardUser currentUser) async {
    try {
      final whiteboard = await WhiteboardModel.load(whiteboardId);
      
      if (whiteboard != null) {
        _currentWhiteboard = whiteboard;
        _currentUser = currentUser;
        
        // Load collaborators
        await fetchCollaborators(whiteboardId);
        
        notifyListeners();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error opening whiteboard: $e');
      return false;
    }
  }
  
  // Close the current whiteboard
  void closeCurrentWhiteboard() {
    _currentWhiteboard = null;
    _currentWhiteboardCollaborators = [];
    notifyListeners();
  }
  
  // Fetch collaborators for the current whiteboard
  Future<void> fetchCollaborators([String? whiteboardId]) async {
    final boardId = whiteboardId ?? _currentWhiteboard?.id;
    if (boardId == null) return;
    
    try {
      if (_currentWhiteboard != null && boardId == _currentWhiteboard!.id) {
        await _currentWhiteboard!.loadCollaborators();
        _currentWhiteboardCollaborators = _currentWhiteboard!.collaborators;
      } else {
        // Load the whiteboard first if it's not the current one
        final whiteboard = await WhiteboardModel.load(boardId);
        if (whiteboard != null) {
          await whiteboard.loadCollaborators();
          _currentWhiteboardCollaborators = whiteboard.collaborators;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching collaborators: $e');
    }
  }
  
  // Add a collaborator to the current whiteboard
  Future<bool> addCollaborator(String email, {String role = 'editor'}) async {
    if (_currentWhiteboard == null) return false;
    
    try {
      // First find the user with this email
      final user = await DatabaseHelper.instance.getUserByEmail(email);
      
      if (user == null) {
        return false;
      }
      
      // Add the user as a collaborator
      final success = await _currentWhiteboard!.addCollaborator(user['id'], role: role);
      
      if (success) {
        await fetchCollaborators();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error adding collaborator: $e');
      return false;
    }
  }
  
  // Remove a collaborator from the current whiteboard
  Future<bool> removeCollaborator(String userId) async {
    if (_currentWhiteboard == null) return false;
    
    try {
      final success = await _currentWhiteboard!.removeCollaborator(userId);
      
      if (success) {
        await fetchCollaborators();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error removing collaborator: $e');
      return false;
    }
  }
  
  // Rename the current whiteboard
  Future<bool> renameCurrentWhiteboard(String newName) async {
    if (_currentWhiteboard == null) return false;
    
    try {
      final success = await _currentWhiteboard!.updateName(newName);
      
      if (success) {
        // Update the whiteboard in the list too
        final index = _myWhiteboards.indexWhere((wb) => wb.id == _currentWhiteboard!.id);
        if (index >= 0) {
          _myWhiteboards[index].name = newName;
        }
        
        notifyListeners();
      }
      
      return success;
    } catch (e) {
      debugPrint('Error renaming whiteboard: $e');
      return false;
    }
  }
  
  // Compatibility methods for dashboard_screen.dart
  
  Future<void> fetchMySessions() async {
    try {
      final userId = _currentUser?.id;
      if (userId == null) return;
      
      await fetchMyWhiteboards(userId);
      
      // Convert whiteboards to sessions
      _mySessions = _myWhiteboards.map((wb) {
        // Generate a simple session code
        final sessionCode = wb.id.substring(0, 6).toUpperCase();
        
        return WhiteboardSession(
          id: wb.id,
          name: wb.name,
          creatorId: wb.ownerId,
          creatorName: 'Owner', // We may not have this info in SQLite
          createdAt: wb.createdAt,
          participants: [], // We'll need to load these separately if needed
          isPublic: true, // Assuming all whiteboards are public for now
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
      // In a real app, you might have a separate query for public whiteboards
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
        creatorId: whiteboard.ownerId,
        creatorName: 'Creator', // We may not have this info in SQLite
        createdAt: whiteboard.createdAt,
        participants: [], // We'll need to load these separately if needed
        isPublic: isPublic,
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
      rethrow;
    }
  }
  
  Future<void> joinSession(String sessionId) async {
    try {
      // In SQLite implementation, joining is just opening the whiteboard
      final userId = _currentUser?.id ?? 'guest';
      final currentUser = WhiteboardUser(
        id: userId,
        name: 'Guest',
        email: 'guest@example.com',
        createdAt: DateTime.now(),
      );
      
      await openWhiteboard(sessionId, currentUser);
    } catch (e) {
      debugPrint('Error joining session: $e');
      rethrow;
    }
  }
  
  Future<bool> isSessionValid(String sessionId) async {
    try {
      // Check if the whiteboard exists
      final whiteboard = await WhiteboardModel.load(sessionId);
      return whiteboard != null;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      return false;
    }
  }
  
  Future<void> deleteSession(String sessionId) async {
    try {
      final success = await deleteWhiteboard(sessionId);
      
      if (success) {
        _mySessions.removeWhere((s) => s.id == sessionId);
        _publicSessions.removeWhere((s) => s.id == sessionId);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }
  
  // For compatibility with whiteboard_screen.dart
  void leaveSession() {
    closeCurrentWhiteboard();
  }
}