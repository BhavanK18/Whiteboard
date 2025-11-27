import 'dart:ui';

import 'package:uuid/uuid.dart';

import 'drawing.dart';

/// Represents an individual page inside a collaborative whiteboard session.
/// Pages allow teams to segment brainstorms without spawning new sessions.
class WhiteboardPage {
  WhiteboardPage({
    required this.id,
    required this.name,
    Color? backgroundColor,
    List<DrawElement>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : backgroundColor = backgroundColor ?? const Color(0xFFFFFFFF),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        elements = elements ?? <DrawElement>[];

  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  Color backgroundColor;
  final List<DrawElement> elements;

  factory WhiteboardPage.blank({int index = 0}) {
    final id = const Uuid().v4();
    return WhiteboardPage(
      id: id,
      name: 'Page ${index + 1}',
      elements: <DrawElement>[],
      backgroundColor: const Color(0xFFFFFFFF),
    );
  }

  WhiteboardPage duplicate({required int copyIndex}) {
    final newId = const Uuid().v4();
    final copiedElements = elements
        .map((element) => DrawElement.fromJson(element.toJson())..pageId = newId)
        .toList();
    final suffix = copyIndex > 0 ? ' Copy $copyIndex' : ' Copy';
    return WhiteboardPage(
      id: newId,
      name: '$name$suffix',
      backgroundColor: backgroundColor,
      elements: copiedElements,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  WhiteboardPage copyWith({
    String? name,
    List<DrawElement>? elements,
    Color? backgroundColor,
    DateTime? updatedAt,
  }) {
    return WhiteboardPage(
      id: id,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      elements: elements ?? List<DrawElement>.from(this.elements),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backgroundColor': backgroundColor.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  factory WhiteboardPage.fromJson(Map<String, dynamic> json) {
    return WhiteboardPage(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Page',
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : const Color(0xFFFFFFFF),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      elements: (json['elements'] as List<dynamic>? ?? const [])
          .map((raw) => DrawElement.fromJson(raw as Map<String, dynamic>))
          .toList(),
    );
  }
}
