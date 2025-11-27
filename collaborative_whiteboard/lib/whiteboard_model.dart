import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'whiteboard_screen.dart';

class WhiteboardModel extends ChangeNotifier {
  Database? _database;
  final String _tableName = 'drawing_points';
  List<DrawingPoint?> _drawingPoints = [];

  List<DrawingPoint?> get drawingPoints => _drawingPoints;

  WhiteboardModel() {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'whiteboard.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE $_tableName('
          'id TEXT PRIMARY KEY, '
          'data TEXT'
          ')',
        );
      },
    );

    // Load existing drawing points from the database
    await loadDrawing();
  }

  Future<void> loadDrawing() async {
    if (_database == null) await _initDatabase();

    final List<Map<String, dynamic>> maps = await _database!.query(_tableName);
    
    _drawingPoints = maps.map((map) {
      final data = jsonDecode(map['data']);
      return DrawingPoint.fromMap(data);
    }).toList();
    
    notifyListeners();
  }

  Future<void> syncDrawing(List<DrawingPoint?> points) async {
    if (_database == null) await _initDatabase();

    // Merge the new points with existing points
    for (var point in points) {
      if (point == null) continue;

      // Check if the point already exists in our list
      final existingIndex = _drawingPoints.indexWhere(
        (p) => p?.id == point.id
      );

      if (existingIndex >= 0) {
        // Update existing point
        _drawingPoints[existingIndex] = point;
      } else {
        // Add new point
        _drawingPoints.add(point);
      }

      // Save to database
      await _database!.insert(
        _tableName,
        {'id': point.id, 'data': jsonEncode(point.toMap())},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    notifyListeners();
  }

  Future<void> clearDrawing() async {
    if (_database == null) await _initDatabase();
    
    // Clear database
    await _database!.delete(_tableName);
    
    // Clear memory
    _drawingPoints.clear();
    
    notifyListeners();
  }

  // Optional: Add methods to export/import the drawing
  Future<String> exportDrawing() async {
    final List<Map<String, dynamic>> exportData = [];
    
    for (var point in _drawingPoints) {
      if (point != null) {
        exportData.add(point.toMap());
      }
    }
    
    return jsonEncode(exportData);
  }

  Future<void> importDrawing(String jsonData) async {
    if (_database == null) await _initDatabase();
    
    // Clear existing data
    await clearDrawing();
    
    final List<dynamic> decodedData = jsonDecode(jsonData);
    final List<DrawingPoint> points = decodedData
      .map((data) => DrawingPoint.fromMap(data))
      .toList();
    
    // Save imported points
    await syncDrawing(points);
  }
}