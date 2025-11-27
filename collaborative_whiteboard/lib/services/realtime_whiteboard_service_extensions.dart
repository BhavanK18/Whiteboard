import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/drawing.dart';
import 'realtime_whiteboard_service.dart';

// Extension methods for RealtimeWhiteboardService
extension RealtimeWhiteboardServiceDrawing on RealtimeWhiteboardService {
  // Text-related methods
  void addText(Offset position, String text) {
    final element = TextElement(
      id: generateElementId(),
      position: position,
      text: text,
      color: currentColor,
      fontSize: currentFontSize,
    );
    
    // Add to elements list
    addDrawElement(element);
  }
  
  // Path-related methods
  void addPathPoint(Offset point, List<DrawingPoint> currentPoints) {
    currentPoints.add(DrawingPoint(
      position: point,
      pressure: 1.0, // Default pressure
    ));
    notifyListeners();
  }
  
  void finalizePath(List<DrawingPoint> points) {
    if (points.length < 2) return;
    
    final element = PathElement(
      id: generateElementId(),
      points: List.from(points),
      color: currentColor,
      strokeWidth: currentStrokeWidth,
    );
    
    // Add to elements list
    addDrawElement(element);
  }
  
  // Line-related methods
  Offset? _lineStart;
  
  void updateLine(Offset endPoint) {
    if (_lineStart == null) {
      _lineStart = endPoint;
      return;
    }
    
    // For preview, we can notify listeners
    notifyListeners();
  }
  
  void finalizeLine() {
    if (_lineStart == null) return;
    
    final element = LineElement(
      id: generateElementId(),
      start: _lineStart!,
      end: _selectedElement != null ? 
        (_selectedElement as LineElement).end : _lineStart!,
      color: currentColor,
      strokeWidth: currentStrokeWidth,
    );
    
    // Reset line start
    _lineStart = null;
    
    // Add to elements list
    addDrawElement(element);
  }
  
  // Rectangle-related methods
  Offset? _rectStart;
  
  void updateRectangle(Offset currentPoint) {
    if (_rectStart == null) {
      _rectStart = currentPoint;
      return;
    }
    
    // For preview, we can notify listeners
    notifyListeners();
  }
  
  void finalizeRectangle() {
    if (_rectStart == null) return;
    
    final rect = Rect.fromPoints(
      _rectStart!,
      _selectedElement != null ? 
        (_selectedElement as RectangleElement).bottomRight : _rectStart!
    );
    
    final element = RectangleElement(
      id: generateElementId(),
      topLeft: rect.topLeft,
      bottomRight: rect.bottomRight,
      color: currentColor,
      strokeWidth: currentStrokeWidth,
      isFilled: false, // Default to outline
    );
    
    // Reset rectangle start
    _rectStart = null;
    
    // Add to elements list
    addDrawElement(element);
  }
  
  // Circle-related methods
  Offset? _circleCenter;
  
  void updateCircle(Offset currentPoint) {
    if (_circleCenter == null) {
      _circleCenter = currentPoint;
      return;
    }
    
    // For preview, we can notify listeners
    notifyListeners();
  }
  
  void finalizeCircle() {
    if (_circleCenter == null) return;
    
    final radius = _selectedElement != null ? 
      (_selectedElement as CircleElement).radius : 50.0;
    
    final element = CircleElement(
      id: generateElementId(),
      center: _circleCenter!,
      radius: radius,
      color: currentColor,
      strokeWidth: currentStrokeWidth,
      isFilled: false, // Default to outline
    );
    
    // Reset circle center
    _circleCenter = null;
    
    // Add to elements list
    addDrawElement(element);
  }
  
  // Element manipulation methods
  void moveSelectedElement(Offset delta) {
    if (_selectedElement == null) return;
    
    _selectedElement!.move(delta);
    notifyListeners();
  }
  
  void finalizeElementMove() {
    if (_selectedElement == null) return;
    
    // Save the updated position to database/backend
    updateDrawElement(_selectedElement!);
    notifyListeners();
  }
  
  void deleteSelectedElement() {
    if (_selectedElement == null) return;
    
    // Remove from elements list
    removeDrawElement(_selectedElement!.id);
    _selectedElement = null;
    notifyListeners();
  }
  
  // View manipulation methods
  void resetView() {
    _scale = 1.0;
    _panOffset = Offset.zero;
    notifyListeners();
  }
  
  // Clear whiteboard
  void clearWhiteboard() {
    _elements.clear();
    _undoStack.clear();
    
    // Notify socket if collaborating
    if (isCollaborating) {
      _socketService.clearBoard();
    }
    
    // Save to backend/local
    _clearBoardInBackend();
    _clearBoardInLocal();
    
    notifyListeners();
  }
  
  // Helper method to generate unique IDs
  String generateElementId() {
    // Simple implementation - in a real app, use a UUID library
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}