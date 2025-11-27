import 'package:flutter/material.dart';
import '../models/session.dart';
import '../models/session_model.dart';
import '../models/whiteboard_model.dart';
import '../models/whiteboard_user.dart';

// This abstract class defines the interface that both web and mobile implementations will follow
abstract class BaseSessionService extends ChangeNotifier {
  // Whiteboards
  List<WhiteboardModel> get myWhiteboards;
  WhiteboardModel? get currentWhiteboard;
  List<Map<String, dynamic>> get currentWhiteboardCollaborators;
  
  // Sessions (for dashboard_screen.dart)
  List<WhiteboardSession> get mySessions;
  List<WhiteboardSession> get publicSessions;
  
  // User
  WhiteboardUser? get currentUser;
  
  // Additional properties
  SessionModel? get currentSession;
  
  // Methods
  Future<void> fetchMyWhiteboards(String userId);
  Future<void> setCurrentWhiteboard(String whiteboardId);
  Future<void> fetchCollaborators(String whiteboardId);
  void setCurrentUser(WhiteboardUser user);
  Future<WhiteboardModel?> createWhiteboard(String userId, String name);
  Future<bool> updateWhiteboard(String whiteboardId, String name);
  Future<List<WhiteboardModel>> getWhiteboards() => Future.value(myWhiteboards);
  Future<bool> joinWhiteboard(String id) => Future.value(false);
  Future<bool> deleteWhiteboard(String whiteboardId);
  
  // For dashboard_screen.dart
  Future<void> fetchMySessions();
  Future<void> fetchPublicSessions();
  Future<WhiteboardSession> createSession(String name, bool isPublic);
  Future<void> joinSession(String sessionId);
  Future<bool> isSessionValid(String sessionId);
  Future<void> deleteSession(String sessionId);
}