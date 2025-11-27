import 'package:flutter/material.dart';
import '../models/whiteboard_model.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import 'package:uuid/uuid.dart';

class WhiteboardFactory {
  static final _uuid = Uuid();
  
  // Create a new whiteboard
  static Future<WhiteboardModel> createWhiteboard({
    required String name,
    required String ownerId,
    String? ownerName,
  }) async {
    final whiteboardId = _uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final whiteboard = WhiteboardModel(
      id: whiteboardId,
      name: name,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
    );
    
    // Save the whiteboard to the database
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'whiteboards',
      {
        'id': whiteboard.id,
        'owner_id': whiteboard.ownerId,
        'name': whiteboard.name,
        'created_at': whiteboard.createdAt,
        'updated_at': whiteboard.updatedAt,
      },
    );
    
    // Add the owner as a collaborator with admin role
    await db.insert(
      'collaborators',
      {
        'whiteboard_id': whiteboard.id,
        'user_id': whiteboard.ownerId,
        'role': 'admin',
        'joined_at': now,
      },
    );
    
    return whiteboard;
  }
  
  // Create a copy of an existing whiteboard
  static Future<WhiteboardModel> duplicateWhiteboard({
    required WhiteboardModel original,
    required String newName,
    required String ownerId,
  }) async {
    // Create a new whiteboard
    final newWhiteboard = await createWhiteboard(
      name: newName,
      ownerId: ownerId,
    );
    
    // Copy all elements from the original whiteboard
    final db = await DatabaseHelper.instance.database;
    final elements = await db.query(
      'elements',
      where: 'whiteboard_id = ?',
      whereArgs: [original.id],
    );
    
    for (final element in elements) {
      await db.insert(
        'elements',
        {
          'id': _uuid.v4(),
          'whiteboard_id': newWhiteboard.id,
          'user_id': ownerId,
          'type': element['type'],
          'properties': element['properties'],
          'created_at': DateTime.now().millisecondsSinceEpoch,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
      );
    }
    
    return newWhiteboard;
  }
  
  // Add a collaborator to a whiteboard
  static Future<void> addCollaborator({
    required String whiteboardId,
    required String userId,
    String role = 'editor',
  }) async {
    final db = await DatabaseHelper.instance.database;
    
    await db.insert(
      'collaborators',
      {
        'whiteboard_id': whiteboardId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  
  // Get all whiteboards a user has access to
  static Future<List<WhiteboardModel>> getUserWhiteboards(String userId) async {
    final db = await DatabaseHelper.instance.database;
    
    // Query for whiteboards where the user is a collaborator
    final List<Map<String, dynamic>> collaboratorWhiteboards = await db.rawQuery('''
      SELECT w.* FROM whiteboards w
      INNER JOIN collaborators c ON w.id = c.whiteboard_id
      WHERE c.user_id = ?
      ORDER BY w.updated_at DESC
    ''', [userId]);
    
    return collaboratorWhiteboards.map((map) => WhiteboardModel.fromMap(map)).toList();
  }
  
  // Get all collaborators for a whiteboard
  static Future<List<WhiteboardUser>> getCollaborators(String whiteboardId) async {
    final db = await DatabaseHelper.instance.database;
    
    final List<Map<String, dynamic>> collaborators = await db.rawQuery('''
      SELECT u.*, c.role FROM users u
      INNER JOIN collaborators c ON u.id = c.user_id
      WHERE c.whiteboard_id = ?
    ''', [whiteboardId]);
    
    return collaborators.map((map) {
      return WhiteboardUser(
        id: map['id'],
        email: map['email'],
        displayName: map['display_name'],
        photoUrl: map['photo_url'],
        role: map['role'],
      );
    }).toList();
  }
}