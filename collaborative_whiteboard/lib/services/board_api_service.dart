import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/drawing.dart';
import '../models/session.dart';
import '../services/config.dart';

class BoardApiService {
  static final BoardApiService instance = BoardApiService._internal();
  
  factory BoardApiService() => instance;
  
  BoardApiService._internal();
  
  /// Fetches board state by session ID
  Future<Map<String, dynamic>> getBoardBySessionId(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('${Config.apiUrl}/api/board/$sessionId'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('Failed to load board state: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching board state: $e');
      rethrow;
    }
  }
  
  /// Converts raw board data to DrawElements
  List<DrawElement> parseElementsFromJson(List<dynamic> elements) {
    return elements.map((element) => DrawElement.fromJson(element)).toList();
  }
}