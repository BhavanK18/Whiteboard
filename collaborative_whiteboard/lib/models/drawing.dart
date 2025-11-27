import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as dart_math;

enum DrawingToolType {
  pen,
  line,
  rectangle,
  circle,
  triangle,
  arrow,
  text,
  eraser,
  select,
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;

  DrawingPoint({required this.offset, required this.paint});

  Map<String, dynamic> toJson() {
    return {
      'x': offset.dx,
      'y': offset.dy,
      'color': paint.color.value,
      'strokeWidth': paint.strokeWidth,
      'isAntiAlias': paint.isAntiAlias,
    };
  }

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      offset: Offset(json['x'], json['y']),
      paint: Paint()
        ..color = Color(json['color'])
        ..strokeWidth = json['strokeWidth']
        ..isAntiAlias = json['isAntiAlias'] ?? true
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }
}

abstract class DrawElement {
  String id;
  Color color;
  double strokeWidth;
  bool isSelected;
  String pageId;

  DrawElement({
    String? id,
    required this.color,
    required this.strokeWidth,
    this.isSelected = false,
    this.pageId = 'default',
  }) : id = id ?? const Uuid().v4();

  void draw(Canvas canvas);
  bool contains(Offset point);
  void move(Offset delta);
  Map<String, dynamic> toJson();
  
  // Add hitTest method that delegates to contains
  bool hitTest(Offset point) => contains(point);
  
  factory DrawElement.fromJson(Map<String, dynamic> json) {
    final String type = json['type'];
    
    switch (type) {
      case 'path':
        return PathElement.fromJson(json);
      case 'line':
        return LineElement.fromJson(json);
      case 'arrow':
        return ArrowElement.fromJson(json);
      case 'rectangle':
        return RectangleElement.fromJson(json);
      case 'circle':
        return CircleElement.fromJson(json);
      case 'triangle':
        return TriangleElement.fromJson(json);
      case 'text':
        return TextElement.fromJson(json);
      default:
        throw Exception('Unknown element type: $type');
    }
  }
}

class PathElement extends DrawElement {
  final List<dynamic> points; // Can be List<DrawingPoint> or List<Offset>
  
  PathElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.points,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    if (points.isEmpty) return;
    
    final path = Path();
    
    // Handle both DrawingPoint and Offset
    Offset firstPoint;
    if (points.first is Offset) {
      firstPoint = points.first as Offset;
    } else if (points.first is DrawingPoint) {
      firstPoint = (points.first as DrawingPoint).offset;
    } else {
      return; // Unknown type
    }
    
    path.moveTo(firstPoint.dx, firstPoint.dy);
    
    for (int i = 1; i < points.length; i++) {
      Offset point;
      if (points[i] is Offset) {
        point = points[i] as Offset;
      } else if (points[i] is DrawingPoint) {
        point = (points[i] as DrawingPoint).offset;
      } else {
        continue; // Unknown type
      }
      
      path.lineTo(point.dx, point.dy);
    }
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, paint);
    
    if (isSelected) {
      final bounds = path.getBounds();
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(bounds.inflate(5), selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    if (points.isEmpty) return false;
    
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      
      final distance = _distanceToLine(point, p1, p2);
      if (distance < 10) {
        return true;
      }
    }
    
    return false;
  }
  
  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final l2 = (lineEnd - lineStart).distanceSquared;
    if (l2 == 0) return (point - lineStart).distance;
    
    final t = ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) +
               (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) / l2;
               
    if (t < 0) return (point - lineStart).distance;
    if (t > 1) return (point - lineEnd).distance;
    
    final projection = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );
    
    return (point - projection).distance;
  }
  
  @override
  void move(Offset delta) {
    for (int i = 0; i < points.length; i++) {
      points[i] = points[i].translate(delta.dx, delta.dy);
    }
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'path',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'pageId': pageId,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }
  
  factory PathElement.fromJson(Map<String, dynamic> json) {
    final List<dynamic> pointsJson = json['points'];
    final List<Offset> points = pointsJson
        .map((p) => Offset(p['x'], p['y']))
        .toList();
    
    return PathElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      points: points,
      pageId: json['pageId'] ?? 'default',
    );
  }
}

class LineElement extends DrawElement {
  Offset start;
  Offset end;
  
  LineElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.start,
    required this.end,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
      
    canvas.drawLine(start, end, paint);
    
    if (isSelected) {
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      final rect = Rect.fromPoints(start, end).inflate(5);
      canvas.drawRect(rect, selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    return _distanceToLine(point, start, end) < 10;
  }
  
  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final l2 = (lineEnd - lineStart).distanceSquared;
    if (l2 == 0) return (point - lineStart).distance;
    
    final t = ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) +
               (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) / l2;
               
    if (t < 0) return (point - lineStart).distance;
    if (t > 1) return (point - lineEnd).distance;
    
    final projection = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );
    
    return (point - projection).distance;
  }
  
  @override
  void move(Offset delta) {
    start = start.translate(delta.dx, delta.dy);
    end = end.translate(delta.dx, delta.dy);
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'line',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'start': {'x': start.dx, 'y': start.dy},
      'end': {'x': end.dx, 'y': end.dy},
      'pageId': pageId,
    };
  }
  
  factory LineElement.fromJson(Map<String, dynamic> json) {
    return LineElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      start: Offset(json['start']['x'], json['start']['y']),
      end: Offset(json['end']['x'], json['end']['y']),
      pageId: json['pageId'] ?? 'default',
    );
  }
}

class RectangleElement extends DrawElement {
  Offset topLeft;
  Offset bottomRight;
  
  RectangleElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.topLeft,
    required this.bottomRight,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    final rect = Rect.fromPoints(topLeft, bottomRight);
    canvas.drawRect(rect, paint);
    
    if (isSelected) {
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRect(rect.inflate(5), selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    final rect = Rect.fromPoints(topLeft, bottomRight).inflate(5);
    if (rect.contains(point)) {
      final innerRect = Rect.fromPoints(topLeft, bottomRight).deflate(5);
      return !innerRect.contains(point);
    }
    return false;
  }
  
  @override
  void move(Offset delta) {
    topLeft = topLeft.translate(delta.dx, delta.dy);
    bottomRight = bottomRight.translate(delta.dx, delta.dy);
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'rectangle',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'topLeft': {'x': topLeft.dx, 'y': topLeft.dy},
      'bottomRight': {'x': bottomRight.dx, 'y': bottomRight.dy},
      'pageId': pageId,
    };
  }
  
  factory RectangleElement.fromJson(Map<String, dynamic> json) {
    return RectangleElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      topLeft: Offset(json['topLeft']['x'], json['topLeft']['y']),
      bottomRight: Offset(json['bottomRight']['x'], json['bottomRight']['y']),
      pageId: json['pageId'] ?? 'default',
    );
  }
}

class CircleElement extends DrawElement {
  Offset center;
  double radius;
  
  CircleElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.center,
    required this.radius,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
      
    canvas.drawCircle(center, radius, paint);
    
    if (isSelected) {
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawCircle(center, radius + 5, selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    final distance = (point - center).distance;
    return (distance >= radius - 5) && (distance <= radius + 5);
  }
  
  @override
  void move(Offset delta) {
    center = center.translate(delta.dx, delta.dy);
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'circle',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'center': {'x': center.dx, 'y': center.dy},
      'radius': radius,
      'pageId': pageId,
    };
  }
  
  factory CircleElement.fromJson(Map<String, dynamic> json) {
    return CircleElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      center: Offset(json['center']['x'], json['center']['y']),
      radius: json['radius'],
      pageId: json['pageId'] ?? 'default',
    );
  }
}

class TriangleElement extends DrawElement {
  Offset p1;
  Offset p2;
  Offset p3;
  
  TriangleElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.p1,
    required this.p2,
    required this.p3,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    final path = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy)
      ..close();
      
    canvas.drawPath(path, paint);
    
    if (isSelected) {
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawPath(path, selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    // Simple bounding box check for triangle
    final minX = [p1.dx, p2.dx, p3.dx].reduce((a, b) => a < b ? a : b);
    final maxX = [p1.dx, p2.dx, p3.dx].reduce((a, b) => a > b ? a : b);
    final minY = [p1.dy, p2.dy, p3.dy].reduce((a, b) => a < b ? a : b);
    final maxY = [p1.dy, p2.dy, p3.dy].reduce((a, b) => a > b ? a : b);
    
    return point.dx >= minX - 10 && point.dx <= maxX + 10 &&
           point.dy >= minY - 10 && point.dy <= maxY + 10;
  }
  
  @override
  void move(Offset delta) {
    p1 = p1.translate(delta.dx, delta.dy);
    p2 = p2.translate(delta.dx, delta.dy);
    p3 = p3.translate(delta.dx, delta.dy);
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'triangle',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'p1': {'x': p1.dx, 'y': p1.dy},
      'p2': {'x': p2.dx, 'y': p2.dy},
      'p3': {'x': p3.dx, 'y': p3.dy},
      'pageId': pageId,
    };
  }
  
  factory TriangleElement.fromJson(Map<String, dynamic> json) {
    return TriangleElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      p1: Offset(json['p1']['x'], json['p1']['y']),
      p2: Offset(json['p2']['x'], json['p2']['y']),
      p3: Offset(json['p3']['x'], json['p3']['y']),
      pageId: json['pageId'] ?? 'default',
    );
  }
}

class ArrowElement extends DrawElement {
  Offset start;
  Offset end;
  
  ArrowElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.start,
    required this.end,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    // Draw the line
    canvas.drawLine(start, end, paint);
    
    // Draw arrowhead
    final arrowSize = strokeWidth * 3 + 10;
    
    // Better arrowhead calculation
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final angle2 = dart_math.atan2(dy, dx);
    
    final arrowAngle = 0.4; // 23 degrees
    final arrowLength = arrowSize;
    
    final arrowPoint1 = Offset(
      end.dx - arrowLength * dart_math.cos(angle2 - arrowAngle),
      end.dy - arrowLength * dart_math.sin(angle2 - arrowAngle),
    );
    
    final arrowPoint2 = Offset(
      end.dx - arrowLength * dart_math.cos(angle2 + arrowAngle),
      end.dy - arrowLength * dart_math.sin(angle2 + arrowAngle),
    );
    
    final arrowHead = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);
    
    canvas.drawPath(arrowHead, paint);
    
    if (isSelected) {
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      final rect = Rect.fromPoints(start, end).inflate(5);
      canvas.drawRect(rect, selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    return _distanceToLine(point, start, end) < 10;
  }
  
  double _distanceToLine(Offset point, Offset lineStart, Offset lineEnd) {
    final l2 = (lineEnd - lineStart).distanceSquared;
    if (l2 == 0) return (point - lineStart).distance;
    
    final t = ((point.dx - lineStart.dx) * (lineEnd.dx - lineStart.dx) +
               (point.dy - lineStart.dy) * (lineEnd.dy - lineStart.dy)) / l2;
               
    if (t < 0) return (point - lineStart).distance;
    if (t > 1) return (point - lineEnd).distance;
    
    final projection = Offset(
      lineStart.dx + t * (lineEnd.dx - lineStart.dx),
      lineStart.dy + t * (lineEnd.dy - lineStart.dy),
    );
    
    return (point - projection).distance;
  }
  
  @override
  void move(Offset delta) {
    start = start.translate(delta.dx, delta.dy);
    end = end.translate(delta.dx, delta.dy);
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'arrow',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'start': {'x': start.dx, 'y': start.dy},
      'end': {'x': end.dx, 'y': end.dy},
      'pageId': pageId,
    };
  }
  
  factory ArrowElement.fromJson(Map<String, dynamic> json) {
    return ArrowElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      start: Offset(json['start']['x'], json['start']['y']),
      end: Offset(json['end']['x'], json['end']['y']),
      pageId: json['pageId'] ?? 'default',
    );
  }
}

class TextElement extends DrawElement {
  Offset position;
  String text;
  double fontSize;
  
  TextElement({
    super.id,
    required super.color,
    required super.strokeWidth,
    required this.position,
    required this.text,
    required this.fontSize,
  super.pageId = 'default',
    super.isSelected = false,
  });
  
  @override
  void draw(Canvas canvas) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position);
    
    if (isSelected) {
      final rect = Rect.fromPoints(
        position,
        Offset(position.dx + textPainter.width, position.dy + textPainter.height),
      );
      final selectPaint = Paint()
        ..color = Colors.blue.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRect(rect.inflate(5), selectPaint);
    }
  }
  
  @override
  bool contains(Offset point) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
    );
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    final rect = Rect.fromPoints(
      position,
      Offset(position.dx + textPainter.width, position.dy + textPainter.height),
    );
    
    return rect.inflate(10).contains(point);
  }
  
  @override
  void move(Offset delta) {
    position = position.translate(delta.dx, delta.dy);
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'text',
      'color': color.value,
      'strokeWidth': strokeWidth,
      'position': {'x': position.dx, 'y': position.dy},
      'text': text,
      'fontSize': fontSize,
      'pageId': pageId,
    };
  }
  
  factory TextElement.fromJson(Map<String, dynamic> json) {
    return TextElement(
      id: json['id'],
      color: Color(json['color']),
      strokeWidth: json['strokeWidth'],
      position: Offset(json['position']['x'], json['position']['y']),
      text: json['text'],
      fontSize: json['fontSize']?.toDouble() ?? 16.0,
      pageId: json['pageId'] ?? 'default',
    );
  }
}