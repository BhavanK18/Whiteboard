import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';

class WhiteboardModel extends ChangeNotifier {
  final String id;
  String name;
  final String ownerId;
  final DateTime createdAt;
  DateTime updatedAt;
  List<Map<String, dynamic>> _collaborators = [];
  List<Map<String, dynamic>> _elements = [];
  bool _isLoaded = false;

  WhiteboardModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // Add a copyWith method to create a new instance with updated values
  WhiteboardModel copyWith({
    String? name,
    DateTime? updatedAt,
  }) {
    return WhiteboardModel(
      id: this.id,
      name: name ?? this.name,
      ownerId: this.ownerId,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<Map<String, dynamic>> get collaborators => _collaborators;
  List<Map<String, dynamic>> get elements => _elements;
  bool get isLoaded => _isLoaded;

  // Create a new whiteboard in the database
  static Future<WhiteboardModel?> create(String ownerId, String name) async {
    final whiteboardId = await DatabaseHelper.instance.createWhiteboard(ownerId, name);
    
    if (whiteboardId == null) {
      return null;
    }
    
    final whiteboard = await DatabaseHelper.instance.getWhiteboard(whiteboardId);
    
    if (whiteboard == null) {
      return null;
    }
    
    return WhiteboardModel(
      id: whiteboard['id'],
      name: whiteboard['name'],
      ownerId: whiteboard['owner_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(whiteboard['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(whiteboard['updated_at']),
    );
  }

  // Load an existing whiteboard from the database
  static Future<WhiteboardModel?> load(String whiteboardId) async {
    final whiteboard = await DatabaseHelper.instance.getWhiteboard(whiteboardId);
    
    if (whiteboard == null) {
      return null;
    }
    
    final model = WhiteboardModel(
      id: whiteboard['id'],
      name: whiteboard['name'],
      ownerId: whiteboard['owner_id'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(whiteboard['created_at']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(whiteboard['updated_at']),
    );
    
    // Load collaborators and elements
    await model.loadCollaborators();
    await model.loadElements();
    
    return model;
  }

  // Update the whiteboard name
  Future<bool> updateName(String newName) async {
    final success = await DatabaseHelper.instance.updateWhiteboard(id, newName);
    
    if (success) {
      name = newName;
      updatedAt = DateTime.now();
      notifyListeners();
    }
    
    return success;
  }

  // Delete the whiteboard
  Future<bool> delete() async {
    return await DatabaseHelper.instance.deleteWhiteboard(id);
  }

  // Load collaborators from the database
  Future<void> loadCollaborators() async {
    _collaborators = await DatabaseHelper.instance.getCollaborators(id);
    _isLoaded = true;
    notifyListeners();
  }

  // Load elements from the database
  Future<void> loadElements() async {
    _elements = await DatabaseHelper.instance.getElements(id);
    notifyListeners();
  }

  // Add a collaborator to the whiteboard
  Future<bool> addCollaborator(String userId, {String role = 'editor'}) async {
    final success = await DatabaseHelper.instance.addCollaborator(id, userId, role: role);
    
    if (success) {
      await loadCollaborators();
    }
    
    return success;
  }

  // Remove a collaborator from the whiteboard
  Future<bool> removeCollaborator(String userId) async {
    final success = await DatabaseHelper.instance.removeCollaborator(id, userId);
    
    if (success) {
      await loadCollaborators();
    }
    
    return success;
  }

  // Add an element to the whiteboard
  Future<String?> addElement(String userId, String type, Map<String, dynamic> properties) async {
    final elementId = await DatabaseHelper.instance.addElement(id, userId, type, properties);
    
    if (elementId != null) {
      await loadElements();
      updatedAt = DateTime.now();
    }
    
    return elementId;
  }

  // Update an element on the whiteboard
  Future<bool> updateElement(String elementId, Map<String, dynamic> properties) async {
    final success = await DatabaseHelper.instance.updateElement(elementId, properties);
    
    if (success) {
      await loadElements();
      updatedAt = DateTime.now();
    }
    
    return success;
  }

  // Delete an element from the whiteboard
  Future<bool> deleteElement(String elementId) async {
    final success = await DatabaseHelper.instance.deleteElement(elementId);
    
    if (success) {
      await loadElements();
      updatedAt = DateTime.now();
    }
    
    return success;
  }
}