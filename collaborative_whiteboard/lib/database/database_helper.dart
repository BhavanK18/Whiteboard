import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

// Import web memory db
import '../database/web_memory_db.dart';
import '../models/whiteboard_user.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static final WebMemoryDB _webDb = WebMemoryDB();
  static final bool _isWeb = kIsWeb;

  DatabaseHelper._init();

  Future<Database?> get database async {
    if (_isWeb) {
      // For web, we don't need to initialize an SQLite database
      // We're using WebMemoryDB instead
      debugPrint('Web platform detected, using in-memory database instead of SQLite');
      return null;
    }
    
    if (_database != null) return _database!;
    
    try {
      _database = await _initDB('whiteboard.db');
      return _database!;
    } catch (e) {
      debugPrint('Error initializing database: $e');
      throw e;
    }
  }

  Future<Database> _initDB(String filePath) async {
    String path;
    
    // For non-web platforms
    try {
      // For mobile and desktop platforms
      final dbPath = await getDatabasesPath();
      path = join(dbPath, filePath);
    } catch (e) {
      // Fallback path
      path = filePath;
      debugPrint('Using fallback path for database: $path');
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Create users table
    await db.execute('''
    CREATE TABLE users(
      id TEXT PRIMARY KEY,
      email TEXT UNIQUE,
      password_hash TEXT,
      display_name TEXT,
      photo_url TEXT,
      created_at INTEGER,
      last_login INTEGER
    )
    ''');

    // Create whiteboards table
    await db.execute('''
    CREATE TABLE whiteboards(
      id TEXT PRIMARY KEY,
      owner_id TEXT,
      name TEXT,
      created_at INTEGER,
      updated_at INTEGER,
      FOREIGN KEY (owner_id) REFERENCES users (id)
    )
    ''');
    
    // Create collaborators table
    await db.execute('''
    CREATE TABLE collaborators(
      whiteboard_id TEXT,
      user_id TEXT,
      role TEXT,
      joined_at INTEGER,
      PRIMARY KEY (whiteboard_id, user_id),
      FOREIGN KEY (whiteboard_id) REFERENCES whiteboards (id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''');
    
    // Create elements table (for whiteboard elements)
    await db.execute('''
    CREATE TABLE elements(
      id TEXT PRIMARY KEY,
      whiteboard_id TEXT,
      user_id TEXT,
      type TEXT,
      properties TEXT,
      created_at INTEGER,
      updated_at INTEGER,
      FOREIGN KEY (whiteboard_id) REFERENCES whiteboards (id) ON DELETE CASCADE,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''');
    
    // Create sessions table (for authentication)
    await db.execute('''
    CREATE TABLE sessions(
      id TEXT PRIMARY KEY,
      user_id TEXT,
      token TEXT UNIQUE,
      expires_at INTEGER,
      created_at INTEGER,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''');
  }
  
  // USER OPERATIONS

  Future<String?> registerUser(String email, String passwordHash, String displayName) async {
    if (_isWeb) {
      return await _webDb.createUser(email, passwordHash, displayName);
    }
    
    final db = await instance.database;
    if (db == null) return null;

    // First check if user already exists
    final existingUserId = await getUserIdByEmail(email);
    if (existingUserId != null) {
      return existingUserId; // Return existing user ID
    }
    
    // Create a unique user ID
    final userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    
    final user = {
      'id': userId,
      'email': email.toLowerCase(),
      'password_hash': passwordHash,
      'display_name': displayName,
      'photo_url': null,
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'last_login': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await db.insert('users', user);
      return userId;
    } catch (e) {
      debugPrint('Error registering user: $e');
      return null;
    }
  }
  
  Future<String?> getUserIdByEmail(String email) async {
    if (_isWeb) {
      return await _webDb.getUserIdByEmail(email);
    }
    
    final db = await instance.database;
    if (db == null) return null;
    
    final results = await db.query(
      'users',
      columns: ['id'],
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      return null;
    }
    return results.first['id'] as String;
  }
  
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    if (_isWeb) {
      return await _webDb.getUserById(userId);
    }
    
    final db = await instance.database;
    if (db == null) return null;
    
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }
  
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    if (_isWeb) {
      // WebMemoryDB doesn't have updateUser yet
      return false;
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    try {
      await db.update(
        'users',
        {
          ...data,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      debugPrint('Error updating user: $e');
      return false;
    }
  }
  
  Future<bool> updateUserLoginTime(String userId) async {
    if (_isWeb) {
      // WebMemoryDB doesn't have updateUserLoginTime yet
      return true;
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    try {
      await db.update(
        'users',
        {'last_login': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [userId],
      );
      return true;
    } catch (e) {
      debugPrint('Error updating user login time: $e');
      return false;
    }
  }

  // WHITEBOARD OPERATIONS

  Future<String?> createWhiteboard(String ownerId, String name) async {
    if (_isWeb) {
      return await _webDb.createWhiteboard(ownerId, name);
    }
    
    final db = await instance.database;
    if (db == null) return null;

    // Create a unique whiteboard ID
    final whiteboardId = 'wb_${DateTime.now().millisecondsSinceEpoch}';
    
    final whiteboard = {
      'id': whiteboardId,
      'owner_id': ownerId,
      'name': name.trim(),
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await db.insert('whiteboards', whiteboard);
      
      // Add owner as a collaborator with admin role
      await addCollaborator(whiteboardId, ownerId, role: 'admin');
      
      return whiteboardId;
    } catch (e) {
      debugPrint('Error creating whiteboard: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getWhiteboardsForUser(String userId) async {
    if (_isWeb) {
      return await _webDb.getWhiteboardsForUser(userId);
    }
    
    final db = await instance.database;
    if (db == null) return [];
    
    // Get all whiteboards where the user is a collaborator
    final results = await db.rawQuery('''
      SELECT w.* FROM whiteboards w
      INNER JOIN collaborators c ON w.id = c.whiteboard_id
      WHERE c.user_id = ?
      ORDER BY w.updated_at DESC
    ''', [userId]);

    return results;
  }

  Future<Map<String, dynamic>?> getWhiteboard(String whiteboardId) async {
    if (_isWeb) {
      return await _webDb.getWhiteboard(whiteboardId);
    }
    
    final db = await instance.database;
    if (db == null) return null;
    
    final results = await db.query(
      'whiteboards',
      where: 'id = ?',
      whereArgs: [whiteboardId],
    );

    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }

  Future<bool> updateWhiteboard(String whiteboardId, String name) async {
    if (_isWeb) {
      return await _webDb.updateWhiteboard(whiteboardId, name);
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    try {
      await db.update(
        'whiteboards',
        {
          'name': name.trim(),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [whiteboardId],
      );
      return true;
    } catch (e) {
      debugPrint('Error updating whiteboard: $e');
      return false;
    }
  }

  Future<bool> deleteWhiteboard(String whiteboardId) async {
    if (_isWeb) {
      return await _webDb.deleteWhiteboard(whiteboardId);
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    try {
      // First delete all related records
      await db.delete('elements', where: 'whiteboard_id = ?', whereArgs: [whiteboardId]);
      await db.delete('collaborators', where: 'whiteboard_id = ?', whereArgs: [whiteboardId]);
      
      // Then delete the whiteboard itself
      await db.delete('whiteboards', where: 'id = ?', whereArgs: [whiteboardId]);
      return true;
    } catch (e) {
      debugPrint('Error deleting whiteboard: $e');
      return false;
    }
  }

  // COLLABORATOR OPERATIONS

  Future<bool> addCollaborator(String whiteboardId, String userId, {String role = 'editor'}) async {
    if (_isWeb) {
      return await _webDb.addCollaborator(whiteboardId, userId, role);
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    final collaborator = {
      'whiteboard_id': whiteboardId,
      'user_id': userId,
      'role': role, // admin, editor, viewer
      'joined_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await db.insert('collaborators', collaborator);
      return true;
    } catch (e) {
      debugPrint('Error adding collaborator: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getCollaborators(String whiteboardId) async {
    if (_isWeb) {
      return await _webDb.getCollaborators(whiteboardId);
    }
    
    final db = await instance.database;
    if (db == null) return [];
    
    // Join with users table to get collaborator details
    final results = await db.rawQuery('''
      SELECT c.role, c.joined_at, u.id, u.email, u.display_name, u.photo_url 
      FROM collaborators c
      INNER JOIN users u ON c.user_id = u.id
      WHERE c.whiteboard_id = ?
    ''', [whiteboardId]);

    return results;
  }

  Future<bool> removeCollaborator(String whiteboardId, String userId) async {
    if (_isWeb) {
      return await _webDb.removeCollaborator(whiteboardId, userId);
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    try {
      await db.delete(
        'collaborators',
        where: 'whiteboard_id = ? AND user_id = ?',
        whereArgs: [whiteboardId, userId],
      );
      return true;
    } catch (e) {
      debugPrint('Error removing collaborator: $e');
      return false;
    }
  }

  // WHITEBOARD ELEMENTS OPERATIONS

  Future<String?> addElement(String whiteboardId, String userId, String type, Map<String, dynamic> properties) async {
    if (_isWeb) {
      return await _webDb.addElement(whiteboardId, userId, type, properties);
    }
    
    final db = await instance.database;
    if (db == null) return null;

    // Create a unique element ID
    final elementId = 'elem_${DateTime.now().millisecondsSinceEpoch}_${userId.substring(0, 4)}';
    
    final element = {
      'id': elementId,
      'whiteboard_id': whiteboardId,
      'user_id': userId,
      'type': type, // line, circle, rectangle, text, etc.
      'properties': jsonEncode(properties), // JSON string of properties
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      await db.insert('elements', element);
      
      // Update the whiteboard's updated_at timestamp
      await db.update(
        'whiteboards',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [whiteboardId],
      );
      
      return elementId;
    } catch (e) {
      debugPrint('Error adding element: $e');
      return null;
    }
  }

  Future<bool> updateElement(String elementId, Map<String, dynamic> properties) async {
    if (_isWeb) {
      return await _webDb.updateElement(elementId, properties);
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    // Get the whiteboard ID for this element
    final element = await db.query(
      'elements',
      columns: ['whiteboard_id'],
      where: 'id = ?',
      whereArgs: [elementId],
    );
    
    if (element.isEmpty) return false;
    final whiteboardId = element.first['whiteboard_id'] as String;
    
    try {
      await db.update(
        'elements',
        {
          'properties': jsonEncode(properties),
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [elementId],
      );
      
      // Update the whiteboard's updated_at timestamp
      await db.update(
        'whiteboards',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [whiteboardId],
      );
      
      return true;
    } catch (e) {
      debugPrint('Error updating element: $e');
      return false;
    }
  }

  Future<bool> deleteElement(String elementId) async {
    if (_isWeb) {
      // We need to find the whiteboard ID first
      String? whiteboardId = await _webDb.getWhiteboardIdForElement(elementId);
      if (whiteboardId != null) {
        return await _webDb.deleteWhiteboardElement(whiteboardId, elementId);
      }
      return false;
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    // Get the whiteboard ID for this element
    final element = await db.query(
      'elements',
      columns: ['whiteboard_id'],
      where: 'id = ?',
      whereArgs: [elementId],
    );
    
    if (element.isEmpty) return false;
    final whiteboardId = element.first['whiteboard_id'] as String;
    
    try {
      await db.delete('elements', where: 'id = ?', whereArgs: [elementId]);
      
      // Update the whiteboard's updated_at timestamp
      await db.update(
        'whiteboards',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [whiteboardId],
      );
      
      return true;
    } catch (e) {
      debugPrint('Error deleting element: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getElements(String whiteboardId) async {
    if (_isWeb) {
      return await _webDb.getElements(whiteboardId);
    }
    
    final db = await instance.database;
    if (db == null) return [];
    
    final results = await db.query(
      'elements',
      where: 'whiteboard_id = ?',
      whereArgs: [whiteboardId],
      orderBy: 'created_at ASC',
    );

    // Parse the properties JSON string
    return results.map((element) {
      final Map<String, dynamic> parsedElement = {...element};
      parsedElement['properties'] = jsonDecode(element['properties'] as String);
      return parsedElement;
    }).toList();
  }
  
  // SESSION OPERATIONS (for authentication)
  
  Future<String?> createSession(String userId, String token, int expiresAt) async {
    if (_isWeb) {
      // This would be handled by _webDb
      return null;
    }
    
    final db = await instance.database;
    if (db == null) return null;
    
    // Create a session ID
    final sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';
    
    final session = {
      'id': sessionId,
      'user_id': userId,
      'token': token,
      'expires_at': expiresAt,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };
    
    try {
      await db.insert('sessions', session);
      return sessionId;
    } catch (e) {
      debugPrint('Error creating session: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getSessionByToken(String token) async {
    if (_isWeb) {
      // This would be handled by _webDb
      return null;
    }
    
    final db = await instance.database;
    if (db == null) return null;
    
    final results = await db.query(
      'sessions',
      where: 'token = ?',
      whereArgs: [token],
    );
    
    if (results.isEmpty) {
      return null;
    }
    return results.first;
  }
  
  Future<bool> deleteSession(String token) async {
    if (_isWeb) {
      // This would be handled by _webDb
      return true;
    }
    
    final db = await instance.database;
    if (db == null) return false;
    
    try {
      await db.delete('sessions', where: 'token = ?', whereArgs: [token]);
      return true;
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return false;
    }
  }
  
  Future<void> cleanupExpiredSessions() async {
    if (_isWeb) {
      return;
    }
    
    final db = await instance.database;
    if (db == null) return;
    
    final now = DateTime.now().millisecondsSinceEpoch;
    
    try {
      await db.delete('sessions', where: 'expires_at < ?', whereArgs: [now]);
    } catch (e) {
      debugPrint('Error cleaning up expired sessions: $e');
    }
  }
  
  Future<void> close() async {
    final db = await instance.database;
    if (db != null) db.close();
  }

  // Added missing methods needed for authentication and user management
  Future<String?> getUserIdFromToken(String token) async {
    if (_isWeb) {
      return _webDb.getUserIdFromToken(token);
    }
    
    final db = await database;
    if (db == null) return null;
    
    try {
      final results = await db.query(
        'sessions',
        columns: ['user_id'],
        where: 'token = ?',
        whereArgs: [token],
      );
      
      if (results.isNotEmpty) {
        return results.first['user_id'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user ID from token: $e');
      return null;
    }
  }
  
  Future<String?> createUser(String email, String password, String displayName) async {
    if (_isWeb) {
      return _webDb.createUser(email, password, displayName).then((_) => email);
    }
    
    final db = await database;
    if (db == null) return null;
    
    try {
      // Hash the password
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      final userId = const Uuid().v4();
      
      await db.insert('users', {
        'id': userId,
        'email': email,
        'password': hashedPassword,
        'display_name': displayName,
        'created_at': DateTime.now().toIso8601String(),
        'last_login': DateTime.now().toIso8601String(),
      });
      
      return userId; // Return the userId
    } catch (e) {
      debugPrint('Error creating user: $e');
      return null;
    }
  }
  
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    if (_isWeb) {
      return _webDb.getUserByEmail(email);
    }
    
    final db = await database;
    if (db == null) return null;
    
    try {
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      
      if (results.isNotEmpty) {
        return results.first;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user by email: $e');
      return null;
    }
  }
  
  Future<bool> validateUserPassword(String email, String password) async {
    if (_isWeb) {
      return _webDb.validateUserPassword(email, password);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      final hashedPassword = sha256.convert(utf8.encode(password)).toString();
      
      final results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, hashedPassword],
      );
      
      return results.isNotEmpty;
    } catch (e) {
      debugPrint('Error validating user password: $e');
      return false;
    }
  }
  
  Future<bool> resetPassword(String email, String newPassword) async {
    if (_isWeb) {
      return _webDb.resetPassword(email, newPassword);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      final hashedPassword = sha256.convert(utf8.encode(newPassword)).toString();
      
      final count = await db.update(
        'users',
        {'password': hashedPassword},
        where: 'email = ?',
        whereArgs: [email],
      );
      
      return count > 0;
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return false;
    }
  }
  
  Future<bool> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    if (_isWeb) {
      return _webDb.updateUserProfile(userId, updates);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      final count = await db.update(
        'users',
        updates,
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return count > 0;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }
  
  Future<bool> updateUserLastLogin(String userId) async {
    if (_isWeb) {
      return _webDb.updateUserLastLogin(userId);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      final count = await db.update(
        'users',
        {'last_login': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [userId],
      );
      
      return count > 0;
    } catch (e) {
      debugPrint('Error updating user last login: $e');
      return false;
    }
  }
  
  Future<String?> createUserSession(String userId, String deviceInfo, String ipAddress) async {
    if (_isWeb) {
      return _webDb.createSession(userId);
    }
    
    final db = await database;
    if (db == null) return null;
    
    try {
      final token = const Uuid().v4();
      final expiry = DateTime.now().add(const Duration(days: 7)).toIso8601String();
      
      await db.insert('sessions', {
        'token': token,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at': expiry,
        'device_info': deviceInfo,
        'ip_address': ipAddress,
      });
      
      return token;
    } catch (e) {
      debugPrint('Error creating session: $e');
      return null;
    }
  }
  
  // Methods for whiteboard elements
  Future<bool> saveElement(String whiteboardId, Map<String, dynamic> element) async {
    if (_isWeb) {
      return _webDb.saveElement(whiteboardId, element);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      await db.insert('whiteboard_elements', {
        'id': element['id'],
        'whiteboard_id': whiteboardId,
        'data': jsonEncode(element),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error saving element: $e');
      return false;
    }
  }
  
  Future<bool> deleteWhiteboardElement(String whiteboardId, String elementId) async {
    if (_isWeb) {
      return _webDb.deleteElement(whiteboardId, elementId);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      final count = await db.delete(
        'whiteboard_elements',
        where: 'whiteboard_id = ? AND id = ?',
        whereArgs: [whiteboardId, elementId],
      );
      
      return count > 0;
    } catch (e) {
      debugPrint('Error deleting element: $e');
      return false;
    }
  }
  
  Future<bool> clearElements(String whiteboardId) async {
    if (_isWeb) {
      return _webDb.clearElements(whiteboardId);
    }
    
    final db = await database;
    if (db == null) return false;
    
    try {
      final count = await db.delete(
        'whiteboard_elements',
        where: 'whiteboard_id = ?',
        whereArgs: [whiteboardId],
      );
      
      return true; // Even if count is 0, still consider this a success
    } catch (e) {
      debugPrint('Error clearing elements: $e');
      return false;
    }
  }
}