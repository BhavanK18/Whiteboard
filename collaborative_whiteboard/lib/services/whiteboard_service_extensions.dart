import 'dart:convert';
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/drawing.dart';
import '../models/session.dart';
import '../models/whiteboard_model.dart';

// Extension to add functionality to WhiteboardServiceSQLite
extension WhiteboardServiceExtensions on WhiteboardServiceSQLite {
  // This method syncs the local drawing with other collaborators
  Future<void> syncWithCollaborators(String whiteboardId) async {
    try {
      // First, ensure we have saved all local changes
      await saveElements();
      
      // Fetch any new changes from the database
      await loadWhiteboard(whiteboardId);
      
    } catch (error) {
      debugPrint('Error syncing with collaborators: $error');
    }
  }
  
  // Helper method to add finer control over auto-save behavior
  Future<void> startAutoSync(String whiteboardId, Duration interval) async {
    // Implementation would set up a timer to periodically call syncWithCollaborators
    // This would typically be done in the state class that uses this service
  }
  
  // Add a method to export the current drawing as JSON
  Future<String> exportDrawingAsJson() async {
    final exportData = <Map<String, dynamic>>[];
    
    for (final element in elements) {
      exportData.add(element.toJson());
    }
    
    return jsonEncode(exportData);
  }
  
  // Add a method to import a drawing from JSON
  Future<void> importDrawingFromJson(String jsonData) async {
    try {
      final List<dynamic> data = jsonDecode(jsonData);
      
      // Clear existing elements
      clearElements();
      
      // Add each element from the imported data
      for (final elementData in data) {
        // We would need to implement a factory method in DrawElement
        // to reconstruct the correct subclass based on the type field
        final String type = elementData['type'];
        
        switch (type) {
          case 'path':
            addElement(PathElement.fromJson(elementData));
            break;
          case 'line':
            addElement(LineElement.fromJson(elementData));
            break;
          case 'rectangle':
            addElement(RectangleElement.fromJson(elementData));
            break;
          case 'circle':
            addElement(CircleElement.fromJson(elementData));
            break;
          case 'text':
            addElement(TextElement.fromJson(elementData));
            break;
          default:
            debugPrint('Unknown element type: $type');
        }
      }
      
      // Save the imported elements
      await saveElements();
      
      // Notify listeners of changes
      notifyListeners();
      
    } catch (error) {
      debugPrint('Error importing drawing from JSON: $error');
    }
  }
  
  // Add a method to check if there are unsaved changes
  bool hasUnsavedChanges() {
    // Implementation would track if there are unsaved changes
    // This could be done by comparing the current elements with
    // the last saved state, or by using a dirty flag
    return false;
  }
}

// Extend the WhiteboardServiceSQLite class with factory methods for different element types
extension DrawElementFactory on DrawElement {
  static DrawElement fromJson(Map<String, dynamic> json) {
    final String type = json['type'];
    
    switch (type) {
      case 'path':
        return PathElement.fromJson(json);
      case 'line':
        return LineElement.fromJson(json);
      case 'rectangle':
        return RectangleElement.fromJson(json);
      case 'circle':
        return CircleElement.fromJson(json);
      case 'text':
        return TextElement.fromJson(json);
      default:
        throw Exception('Unknown element type: $type');
    }
  }
}