import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'config.dart';
import '../models/session.dart';
import '../models/whiteboard_model.dart';
import '../models/drawing.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  final http.Client _client = http.Client();
  String? _authToken;
  
  // Constructor
  factory ApiService() => instance;
  ApiService._internal();
  
  // Set auth token
  void setAuthToken(String? token) {
    _authToken = token;
  }
  
  // Get headers
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    
    return headers;
  }
  
  // Generic error handler
  dynamic _handleError(http.Response response) {
    debugPrint('API Error: ${response.statusCode} - ${response.body}');
    if (response.statusCode == 401) {
      // Handle unauthorized error
      throw Exception('Unauthorized');
    } else {
      // Handle other errors
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Unknown error');
    }
  }
  
  // User methods
  Future<Map<String, dynamic>> register(String email, String password, String displayName) async {
    try {
      final response = await _client.post(
        Uri.parse('${Config.usersEndpoint}/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName
        }),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Register error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('${Config.usersEndpoint}/login'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'password': password
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _authToken = data['token'];
        return data;
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('${Config.usersEndpoint}/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Get user profile error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateUserProfile(String userId, String displayName) async {
    try {
      final response = await _client.put(
        Uri.parse('${Config.usersEndpoint}/$userId'),
        headers: _getHeaders(),
        body: jsonEncode({
          'displayName': displayName
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Update user profile error: $e');
      rethrow;
    }
  }
  
  // Session methods
  Future<Map<String, dynamic>> createSession(String whiteboardId, String ownerId) async {
    try {
      final response = await _client.post(
        Uri.parse(Config.sessionsEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({
          'whiteboardId': whiteboardId,
          'ownerId': ownerId
        }),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Create session error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getSessionByCode(String code) async {
    try {
      final response = await _client.get(
        Uri.parse('${Config.sessionsEndpoint}/code/$code'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Get session by code error: $e');
      rethrow;
    }
  }
  
  Future<List<dynamic>> getUserSessions(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('${Config.sessionsEndpoint}/user/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Get user sessions error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> extendSession(String sessionId) async {
    try {
      final response = await _client.put(
        Uri.parse('${Config.sessionsEndpoint}/$sessionId/extend'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Extend session error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> endSession(String sessionId) async {
    try {
      final response = await _client.put(
        Uri.parse('${Config.sessionsEndpoint}/$sessionId/end'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('End session error: $e');
      rethrow;
    }
  }
  
  // Whiteboard methods
  Future<Map<String, dynamic>> createWhiteboard(String name, String ownerId) async {
    try {
      final response = await _client.post(
        Uri.parse(Config.whiteboardsEndpoint),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name,
          'ownerId': ownerId
        }),
      );
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Create whiteboard error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getWhiteboard(String id) async {
    try {
      final response = await _client.get(
        Uri.parse('${Config.whiteboardsEndpoint}/$id'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Get whiteboard error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> getUserWhiteboards(String userId) async {
    try {
      final response = await _client.get(
        Uri.parse('${Config.whiteboardsEndpoint}/user/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Get user whiteboards error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> updateWhiteboard(String id, String name) async {
    try {
      final response = await _client.put(
        Uri.parse('${Config.whiteboardsEndpoint}/$id'),
        headers: _getHeaders(),
        body: jsonEncode({
          'name': name
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Update whiteboard error: $e');
      rethrow;
    }
  }
  
  Future<List<dynamic>> addElements(String whiteboardId, List<DrawElement> elements, String userId) async {
    try {
      final elementData = elements.map((e) => e.toJson()).toList();
      
      final response = await _client.post(
        Uri.parse('${Config.whiteboardsEndpoint}/$whiteboardId/elements'),
        headers: _getHeaders(),
        body: jsonEncode({
          'elements': elementData,
          'userId': userId
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Add elements error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> deleteElements(String whiteboardId, List<String> elementIds) async {
    try {
      final response = await _client.delete(
        Uri.parse('${Config.whiteboardsEndpoint}/$whiteboardId/elements'),
        headers: _getHeaders(),
        body: jsonEncode({
          'elementIds': elementIds
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Delete elements error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> clearBoard(String whiteboardId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${Config.whiteboardsEndpoint}/$whiteboardId/elements/all'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Clear board error: $e');
      rethrow;
    }
  }
  
  Future<List<dynamic>> addCollaborator(String whiteboardId, String userId, String role) async {
    try {
      final response = await _client.post(
        Uri.parse('${Config.whiteboardsEndpoint}/$whiteboardId/collaborators'),
        headers: _getHeaders(),
        body: jsonEncode({
          'userId': userId,
          'role': role
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Add collaborator error: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> removeCollaborator(String whiteboardId, String userId) async {
    try {
      final response = await _client.delete(
        Uri.parse('${Config.whiteboardsEndpoint}/$whiteboardId/collaborators/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return _handleError(response);
      }
    } catch (e) {
      debugPrint('Remove collaborator error: $e');
      rethrow;
    }
  }
  
  void dispose() {
    _client.close();
  }
}