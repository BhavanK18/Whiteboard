import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/drawing.dart';
import '../models/session.dart';
import '../models/whiteboard_model.dart';
import '../models/whiteboard_user.dart' as model;

class WhiteboardServiceSQLite extends ChangeNotifier {
  final List<DrawElement> _elements = [];
  final List<DrawElement> _undoStack = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  double _currentFontSize = 16.0;
  DrawingToolType _currentTool = DrawingToolType.pen;
  DrawElement? _selectedElement;
  WhiteboardModel? _currentWhiteboard;
  model.WhiteboardUser? _currentUser;
  double _scale = 1.0;
  Offset _panOffset = Offset.zero;

  List<DrawElement> get elements => List.unmodifiable(_elements);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  double get currentFontSize => _currentFontSize;
  DrawingToolType get currentTool => _currentTool;
  DrawElement? get selectedElement => _selectedElement;
  double get scale => _scale;
  Offset get panOffset => _panOffset;
  WhiteboardModel? get currentWhiteboard => _currentWhiteboard;

  void setCurrentTool(DrawingToolType tool) {
    _currentTool = tool;
    if (tool != DrawingToolType.select) {
      _selectedElement = null;
    }
    notifyListeners();
  }

  void setCurrentColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setCurrentStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  void setCurrentFontSize(double size) {
    _currentFontSize = size;
    notifyListeners();
  }

  void setScale(double newScale) {
    _scale = newScale.clamp(0.5, 3.0);
    notifyListeners();
  }

  void setPanOffset(Offset offset) {
    _panOffset = offset;
    notifyListeners();
  }

  void translatePanOffset(Offset delta) {
    _panOffset += delta;
    notifyListeners();
  }

  void resetView() {
    _scale = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }

  void setCurrentUser(model.WhiteboardUser user) {
    _currentUser = user;
  }

  Future<void> joinWhiteboard(String whiteboardId, model.WhiteboardUser user) async {
    _currentUser = user;
    _currentWhiteboard = await WhiteboardModel.load(whiteboardId);
    
    // Load initial data
    if (_currentWhiteboard != null) {
      await _fetchWhiteboardData();
    }
  }

  Future<void> _fetchWhiteboardData() async {
    if (_currentWhiteboard == null) return;
    
    try {
      // Load elements from the database
      await _currentWhiteboard!.loadElements();
      
      // Convert database elements to DrawElement objects
      _elements.clear();
      for (var dbElement in _currentWhiteboard!.elements) {
        final type = dbElement['type'] as String;
        final props = dbElement['properties'] as Map<String, dynamic>;
        
        DrawElement? element;
        switch (type) {
          case 'PathElement':
            element = PathElement.fromJson(props);
            break;
          case 'LineElement':
            element = LineElement.fromJson(props);
            break;
          case 'CircleElement':
            element = CircleElement.fromJson(props);
            break;
          case 'RectangleElement':
            element = RectangleElement.fromJson(props);
            break;
          case 'TextElement':
            element = TextElement.fromJson(props);
            break;
        }
        
        if (element != null) {
          element.id = dbElement['id'];
          _elements.add(element);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching whiteboard data: $e');
    }
  }

  Future<void> _saveWhiteboardData() async {
    if (_currentWhiteboard == null || _currentUser == null) return;

    try {
      // We'll first delete any elements that were removed
      final existingIds = _elements.map((e) => e.id).whereType<String>().toSet();
      final dbElementIds = _currentWhiteboard!.elements.map((e) => e['id'] as String).toSet();
      
      // Find elements that need to be deleted
      final idsToDelete = dbElementIds.difference(existingIds);
      for (var id in idsToDelete) {
        await _currentWhiteboard!.deleteElement(id);
      }
      
      // Now add or update elements
      for (var element in _elements) {
        if (element.id == null) {
          // New element, add it
          final elementId = await _currentWhiteboard!.addElement(
            _currentUser!.id,
            element.runtimeType.toString(),
            element.toJson(),
          );
          if (elementId != null) {
            element.id = elementId;
          }
        } else {
          // Existing element, update it
          await _currentWhiteboard!.updateElement(
            element.id!,
            element.toJson(),
          );
        }
      }
      
      // Reload elements from database to sync
      await _currentWhiteboard!.loadElements();
    } catch (e) {
      debugPrint('Error saving whiteboard data: $e');
    }
  }

  void addPathPoint(Offset point, List<Offset> points) {
    if (_currentTool != DrawingToolType.pen && _currentTool != DrawingToolType.eraser) return;

    if (points.isEmpty) {
      points.add(point);
      return;
    }

    points.add(point);
    notifyListeners();
  }

  void finalizePath(List<Offset> points) {
    if (points.length < 2) return;

    final color = _currentTool == DrawingToolType.eraser ? Colors.white : _currentColor;
    final strokeWidth = _currentTool == DrawingToolType.eraser ? 20.0 : _currentStrokeWidth;

    final pathElement = PathElement(
      color: color,
      strokeWidth: strokeWidth,
      points: List.from(points),
    );

    _elements.add(pathElement);
    _undoStack.clear();
    
    _saveWhiteboardData();
    notifyListeners();
  }

  void startLine(Offset start) {
    if (_currentTool != DrawingToolType.line) return;

    final lineElement = LineElement(
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      start: start,
      end: start,
    );

    _elements.add(lineElement);
    _undoStack.clear();
    notifyListeners();
  }

  void updateLine(Offset end) {
    if (_elements.isEmpty || _currentTool != DrawingToolType.line) return;

    final lastElement = _elements.last;
    if (lastElement is LineElement) {
      lastElement.end = end;
      notifyListeners();
    }
  }

  void finalizeLine() {
    if (_elements.isEmpty || _currentTool != DrawingToolType.line) return;

    final lastElement = _elements.last;
    if (lastElement is LineElement) {
      if ((lastElement.start - lastElement.end).distance < 5) {
        // Remove too short lines
        _elements.removeLast();
      } else {
        _saveWhiteboardData();
      }
    }
    notifyListeners();
  }

  void startCircle(Offset center) {
    if (_currentTool != DrawingToolType.circle) return;

    final circleElement = CircleElement(
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      center: center,
      radius: 0,
    );

    _elements.add(circleElement);
    _undoStack.clear();
    notifyListeners();
  }

  void updateCircle(Offset point) {
    if (_elements.isEmpty || _currentTool != DrawingToolType.circle) return;

    final lastElement = _elements.last;
    if (lastElement is CircleElement) {
      lastElement.radius = (point - lastElement.center).distance;
      notifyListeners();
    }
  }

  void finalizeCircle() {
    if (_elements.isEmpty || _currentTool != DrawingToolType.circle) return;

    final lastElement = _elements.last;
    if (lastElement is CircleElement) {
      if (lastElement.radius < 5) {
        // Remove too small circles
        _elements.removeLast();
      } else {
        _saveWhiteboardData();
      }
    }
    notifyListeners();
  }

  void addText(Offset position, String text) {
    if (_currentTool != DrawingToolType.text || text.isEmpty) return;

    final textElement = TextElement(
      color: _currentColor,
      fontSize: _currentFontSize,
      position: position,
      text: text,
      strokeWidth: _currentStrokeWidth,
    );

    _elements.add(textElement);
    _undoStack.clear();
    _saveWhiteboardData();
    notifyListeners();
  }

  void startRectangle(Offset topLeft) {
    if (_currentTool != DrawingToolType.rectangle) return;

    final rectangleElement = RectangleElement(
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      topLeft: topLeft,
      bottomRight: topLeft,
    );

    _elements.add(rectangleElement);
    _undoStack.clear();
    notifyListeners();
  }

  void updateRectangle(Offset bottomRight) {
    if (_elements.isEmpty || _currentTool != DrawingToolType.rectangle) return;

    final lastElement = _elements.last;
    if (lastElement is RectangleElement) {
      lastElement.bottomRight = bottomRight;
      notifyListeners();
    }
  }

  void finalizeRectangle() {
    if (_elements.isEmpty || _currentTool != DrawingToolType.rectangle) return;

    final lastElement = _elements.last;
    if (lastElement is RectangleElement) {
      final width = (lastElement.bottomRight.dx - lastElement.topLeft.dx).abs();
      final height = (lastElement.bottomRight.dy - lastElement.topLeft.dy).abs();
      
      if (width < 5 || height < 5) {
        // Remove too small rectangles
        _elements.removeLast();
      } else {
        // Normalize rectangle coordinates
        final topLeft = Offset(
          min(lastElement.topLeft.dx, lastElement.bottomRight.dx),
          min(lastElement.topLeft.dy, lastElement.bottomRight.dy),
        );
        final bottomRight = Offset(
          max(lastElement.topLeft.dx, lastElement.bottomRight.dx),
          max(lastElement.topLeft.dy, lastElement.bottomRight.dy),
        );
        
        lastElement.topLeft = topLeft;
        lastElement.bottomRight = bottomRight;
        
        _saveWhiteboardData();
      }
    }
    notifyListeners();
  }

  double min(double a, double b) => a < b ? a : b;
  double max(double a, double b) => a > b ? a : b;

  void selectElementAt(Offset position) {
    if (_currentTool != DrawingToolType.select) return;

    _selectedElement = null;
    
    // Check in reverse order (top-most elements first)
    for (int i = _elements.length - 1; i >= 0; i--) {
      final element = _elements[i];
      if (element.contains(position)) {
        _selectedElement = element;
        break;
      }
    }
    
    notifyListeners();
  }

  void moveSelectedElement(Offset delta) {
    if (_selectedElement == null) return;
    
    _selectedElement!.move(delta);
    notifyListeners();
  }

  void deleteSelectedElement() {
    if (_selectedElement == null) return;
    
    _elements.remove(_selectedElement);
    _selectedElement = null;
    _saveWhiteboardData();
    notifyListeners();
  }

  void undo() {
    if (_elements.isEmpty) return;
    
    _undoStack.add(_elements.removeLast());
    _saveWhiteboardData();
    notifyListeners();
  }

  void redo() {
    if (_undoStack.isEmpty) return;
    
    _elements.add(_undoStack.removeLast());
    _saveWhiteboardData();
    notifyListeners();
  }

  void clearWhiteboard() {
    _elements.clear();
    _undoStack.clear();
    _selectedElement = null;
    _saveWhiteboardData();
    notifyListeners();
  }

  void closeWhiteboard() {
    _currentWhiteboard = null;
    _elements.clear();
    _undoStack.clear();
    _selectedElement = null;
    notifyListeners();
  }
  
  // Add methods to work with SQLite whiteboards
  Future<List<WhiteboardModel>> getUserWhiteboards(String userId) async {
    final whiteboards = await DatabaseHelper.instance.getWhiteboardsForUser(userId);
    
    return Future.wait(
      whiteboards.map((wb) async {
        return WhiteboardModel(
          id: wb['id'],
          name: wb['name'],
          ownerId: wb['owner_id'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(wb['created_at']),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(wb['updated_at']),
        );
      }),
    );
  }
  
  Future<WhiteboardModel?> createWhiteboard(String userId, String name) async {
    return await WhiteboardModel.create(userId, name);
  }
  
  Future<void> openWhiteboard(String whiteboardId, model.WhiteboardUser user) async {
    _currentUser = user;
    _currentWhiteboard = await WhiteboardModel.load(whiteboardId);
    
    if (_currentWhiteboard != null) {
      await _fetchWhiteboardData();
    }
  }
  
  Future<bool> deleteWhiteboard(String whiteboardId) async {
    final whiteboard = await WhiteboardModel.load(whiteboardId);
    if (whiteboard == null) return false;
    
    final success = await whiteboard.delete();
    
    if (success && _currentWhiteboard?.id == whiteboardId) {
      closeWhiteboard();
    }
    
    return success;
  }
  
  Future<bool> renameWhiteboard(String whiteboardId, String newName) async {
    final whiteboard = await WhiteboardModel.load(whiteboardId);
    if (whiteboard == null) return false;
    
    final success = await whiteboard.updateName(newName);
    
    if (success && _currentWhiteboard?.id == whiteboardId) {
      _currentWhiteboard!.name = newName;
      notifyListeners();
    }
    
    return success;
  }
  
  void finalizeElementMove() {
    if (_selectedElement == null) return;
    _saveWhiteboardData();
  }
}