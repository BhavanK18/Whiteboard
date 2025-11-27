import 'package:uuid/uuid.dart';
import 'whiteboard_page.dart';

class WhiteboardDocument {
  WhiteboardDocument({
    String? id,
    required this.title,
    required this.pages,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String title;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<WhiteboardPage> pages;

  WhiteboardDocument copyWith({
    String? title,
    List<WhiteboardPage>? pages,
    DateTime? updatedAt,
  }) {
    return WhiteboardDocument(
      id: id,
      title: title ?? this.title,
      pages: pages ?? List<WhiteboardPage>.from(this.pages),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pages': pages.map((page) => page.toJson()).toList(),
    };
  }

  factory WhiteboardDocument.fromJson(Map<String, dynamic> json) {
    return WhiteboardDocument(
      id: json['id'] as String?,
      title: json['title'] as String? ?? 'Untitled',
      pages: (json['pages'] as List<dynamic>? ?? const [])
          .map((raw) => WhiteboardPage.fromJson(raw as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class WhiteboardDocumentSummary {
  WhiteboardDocumentSummary({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.pageCount,
  });

  final String id;
  final String title;
  final DateTime updatedAt;
  final int pageCount;

  factory WhiteboardDocumentSummary.fromDocument(WhiteboardDocument document) {
    return WhiteboardDocumentSummary(
      id: document.id,
      title: document.title,
      updatedAt: document.updatedAt,
      pageCount: document.pages.length,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'updatedAt': updatedAt.toIso8601String(),
        'pageCount': pageCount,
      };

  factory WhiteboardDocumentSummary.fromJson(Map<String, dynamic> json) {
    return WhiteboardDocumentSummary(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      pageCount: json['pageCount'] is int
          ? json['pageCount'] as int
          : int.tryParse(json['pageCount']?.toString() ?? '0') ?? 0,
    );
  }
}
