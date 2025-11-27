import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/drawing.dart';
import '../models/session.dart';
import '../models/whiteboard_model.dart';

class WhiteboardService extends ChangeNotifier {
  final List<DrawElement> _elements = [];
  final List<DrawElement> _undoStack = [];
  Color _currentColor = Colors.black;
  double _currentStrokeWidth = 3.0;
  double _currentFontSize = 16.0;
  DrawingToolType _currentTool = DrawingToolType.pen;
  DrawElement? _selectedElement;
  WhiteboardModel? _currentWhiteboard;
  WhiteboardUser? _currentUser;
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

  void undo() {
    if (_elements.isEmpty) return;
    
    _undoStack.add(_elements.removeLast());
    notifyListeners();
  }

  void redo() {
    if (_undoStack.isEmpty) return;
    
    _elements.add(_undoStack.removeLast());
    notifyListeners();
  }

  void deleteSelectedElement() {
    if (_selectedElement == null) return;
    
    _elements.remove(_selectedElement);
    _selectedElement = null;
    notifyListeners();
  }
  
  void clearWhiteboard() {
    _elements.clear();
    _undoStack.clear();
    _selectedElement = null;
    notifyListeners();
  }
  
  void closeWhiteboard() {
    _currentWhiteboard = null;
    _elements.clear();
    _undoStack.clear();
    _selectedElement = null;
    notifyListeners();
  }

  // Implementation methods
  void addText(Offset position, String text) {
    if (_currentTool != DrawingToolType.text || text.isEmpty) return;

    final textElement = TextElement(
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      position: position,
      text: text,
      fontSize: _currentFontSize,
    );

    _elements.add(textElement);
    _undoStack.clear();
    notifyListeners();
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
        // Remove too small lines
        _elements.removeLast();
      }
    }
    notifyListeners();
  }

  void startRectangle(Offset start) {
    if (_currentTool != DrawingToolType.rectangle) return;

    final rectangleElement = RectangleElement(
      color: _currentColor,
      strokeWidth: _currentStrokeWidth,
      topLeft: start,
      bottomRight: start,
    );

    _elements.add(rectangleElement);
    _undoStack.clear();
    notifyListeners();
  }

  void updateRectangle(Offset end) {
    if (_elements.isEmpty || _currentTool != DrawingToolType.rectangle) return;

    final lastElement = _elements.last;
    if (lastElement is RectangleElement) {
      lastElement.bottomRight = end;
      notifyListeners();
    }
  }

  void finalizeRectangle() {
    if (_elements.isEmpty || _currentTool != DrawingToolType.rectangle) return;

    final lastElement = _elements.last;
    if (lastElement is RectangleElement) {
      if ((lastElement.topLeft - lastElement.bottomRight).distance < 5) {
        // Remove too small rectangles
        _elements.removeLast();
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
      }
    }
    notifyListeners();
  }

  void selectElementAt(Offset position) {
    if (_currentTool != DrawingToolType.select) return;

    _selectedElement = null;
    for (int i = _elements.length - 1; i >= 0; i--) {
      if (_elements[i].contains(position)) {
        _selectedElement = _elements[i];
        _selectedElement!.isSelected = true;
        break;
      }
    }
    
    // Deselect other elements
    for (var element in _elements) {
      if (element != _selectedElement) {
        element.isSelected = false;
      }
    }
    
    notifyListeners();
  }

  void moveSelectedElement(Offset delta) {
    if (_selectedElement == null || _currentTool != DrawingToolType.select) return;
    
    _selectedElement!.move(delta);
    notifyListeners();
  }

  void finalizeElementMove() {
    if (_selectedElement == null) return;
  }

  Future<void> _fetchWhiteboardData() async {
    if (_currentWhiteboard == null) return;
    
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
  
  Future<void> openWhiteboard(String whiteboardId, WhiteboardUser user) async {
    _currentUser = user;
    _currentWhiteboard = await WhiteboardModel.load(whiteboardId);
    
    if (_currentWhiteboard != null) {
      await _fetchWhiteboardData();
    }
  }
}