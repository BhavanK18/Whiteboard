import 'dart:convert';
import 'package:http/http.dart' as http;

class SessionApiService {
  // Update this to your backend URL
  static const String baseUrl = 'http://localhost:3000/api/sessions';

  // Create a new session
  static Future<Map<String, dynamic>> createSession({
    required String sessionName,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionName': sessionName,
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'sessionCode': data['sessionCode'],
          'inviteLink': data['inviteLink'],
          'userRole': data['userRole'],
          'createdBy': data['createdBy'],
          'sessionName': data['sessionName'],
          'createdAt': data['createdAt'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Join an existing session
  static Future<Map<String, dynamic>> joinSession({
    required String sessionCode,
    String? userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/join'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionCode': sessionCode,
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'sessionCode': data['sessionCode'],
          'inviteLink': data['inviteLink'],
          'userRole': data['userRole'],
          'createdBy': data['createdBy'],
          'sessionName': data['sessionName'],
          'boardData': data['boardData'],
          'participants': data['participants'],
          'userName': data['userName'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to join session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get session by sessionId
  static Future<Map<String, dynamic>> getSession(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'sessionId': data['sessionId'],
          'sessionCode': data['sessionCode'],
          'sessionName': data['sessionName'],
          'createdBy': data['createdBy'],
          'createdAt': data['createdAt'],
          'participants': data['participants'],
          'boardData': data['boardData'],
          'inviteLink': data['inviteLink'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Session not found',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get all sessions for a user
  static Future<Map<String, dynamic>> getUserSessions(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'sessions': data['sessions'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to get sessions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Delete a session
  static Future<Map<String, dynamic>> deleteSession({
    required String sessionId,
    required String userId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$sessionId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to delete session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Deactivate a session (called on close/disconnect)
  static Future<Map<String, dynamic>> deactivateSession(String sessionId) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$sessionId/deactivate'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to deactivate session',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
