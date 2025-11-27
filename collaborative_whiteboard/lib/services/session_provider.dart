// Provider wrapper to resolve ambiguity between different SessionService implementations
import 'package:flutter/foundation.dart';
import 'base_session_service.dart';
import 'session_service_sqlite.dart';
import 'session_service_web.dart';
import '../models/whiteboard_model.dart';
import '../models/session_model.dart';

// Export the base service interface
export 'base_session_service.dart';
export 'session_service_sqlite.dart';
export 'session_service_web.dart';

// SessionProvider class that manages the session service implementation
class SessionProvider extends ChangeNotifier {
  final BaseSessionService _sessionService;
  
  SessionProvider() : _sessionService = createSessionService();
  
  BaseSessionService get service => _sessionService;
  
  WhiteboardModel? get currentWhiteboard => _sessionService.currentWhiteboard;
  
  SessionModel? get currentSession => _sessionService.currentSession;
  
  Future<List<WhiteboardModel>> getWhiteboards() => _sessionService.getWhiteboards();
  
  Future<bool> createWhiteboard(String name) {
    // We need to get the user ID first
    final userId = _sessionService.currentUser?.id ?? 'anonymous';
    return _sessionService.createWhiteboard(userId, name).then((whiteboard) => whiteboard != null);
  }
  
  Future<bool> joinWhiteboard(String id) => _sessionService.joinWhiteboard(id);
  
  void notifyChanges() {
    notifyListeners();
  }
}

// This allows us to use different implementations on different platforms
// while keeping a consistent API
BaseSessionService createSessionService() {
  if (kIsWeb) {
    return SessionServiceWeb();
  }
  return SessionServiceSQLite();
}