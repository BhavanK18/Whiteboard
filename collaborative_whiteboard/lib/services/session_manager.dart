import 'package:shared_preferences/shared_preferences.dart';
import 'session_api_service.dart';

class SessionManager {
  static const String _tokenKey = 'auth_token';
  static const String _activeSessionIdKey = 'active_session_id';
  static const String _activeSessionCodeKey = 'active_session_code';
  static const String _activeSessionNameKey = 'active_session_name';
  
  // Save auth token
  static Future<bool> saveAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_tokenKey, token);
  }
  
  // Get auth token
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }
  
  // Clear auth token
  static Future<bool> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.remove(_tokenKey);
  }

  // Save active session
  static Future<void> saveActiveSession({
    required String sessionId,
    required String sessionCode,
    required String sessionName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeSessionIdKey, sessionId);
    await prefs.setString(_activeSessionCodeKey, sessionCode);
    await prefs.setString(_activeSessionNameKey, sessionName);
  }

  // Get active session
  static Future<Map<String, String>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionId = prefs.getString(_activeSessionIdKey);
    final sessionCode = prefs.getString(_activeSessionCodeKey);
    final sessionName = prefs.getString(_activeSessionNameKey);

    if (sessionId != null && sessionCode != null && sessionName != null) {
      return {
        'sessionId': sessionId,
        'sessionCode': sessionCode,
        'sessionName': sessionName,
      };
    }
    return null;
  }

  // Clear active session
  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionIdKey);
    await prefs.remove(_activeSessionCodeKey);
    await prefs.remove(_activeSessionNameKey);
  }

  // Deactivate and clear active session
  static Future<void> deactivateAndClearSession() async {
    final activeSession = await getActiveSession();
    if (activeSession != null) {
      final sessionId = activeSession['sessionId'];
      if (sessionId != null) {
        // Deactivate on backend
        await SessionApiService.deactivateSession(sessionId);
      }
    }
    // Clear from local storage
    await clearActiveSession();
  }
}
