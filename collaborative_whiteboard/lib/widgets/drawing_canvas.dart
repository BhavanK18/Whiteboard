import 'package:flutter/material.dart';
import '../models/drawing.dart';

class DrawingCanvas extends StatelessWidget {
  final List<DrawElement> elements;
  final double scale;
  final Offset panOffset;
  final Color backgroundColor;
  final Color gridColor;

  const DrawingCanvas({
    super.key,
    required this.elements,
    required this.scale,
    required this.panOffset,
    required this.backgroundColor,
    required this.gridColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: CustomPaint(
        painter: DrawingPainter(
          elements: elements,
          scale: scale,
          panOffset: panOffset,
          backgroundColor: backgroundColor,
          gridColor: gridColor,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawElement> elements;
  final double scale;
  final Offset panOffset;
  final Color backgroundColor;
  final Color gridColor;

  DrawingPainter({
    required this.elements,
    required this.scale,
    required this.panOffset,
    required this.backgroundColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Offset.zero & size, backgroundPaint);

    canvas.save();
    
    // Apply scaling and panning transformations
    canvas.translate(panOffset.dx, panOffset.dy);
    canvas.scale(scale, scale);
    
    // Draw background grid for better orientation
  _drawGrid(canvas, size);
    
    // Draw all elements
    for (var element in elements) {
      element.draw(canvas);
    }
    
    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.65;
    
    const gridSize = 50.0;
    final width = size.width / scale;
    final height = size.height / scale;
    final offsetX = panOffset.dx / scale;
    final offsetY = panOffset.dy / scale;
    
    // Calculate grid start and end points based on the current view
    final startX = ((-offsetX) / gridSize).floor() * gridSize;
    final endX = ((-offsetX + width) / gridSize).ceil() * gridSize;
    final startY = ((-offsetY) / gridSize).floor() * gridSize;
    final endY = ((-offsetY + height) / gridSize).ceil() * gridSize;
    
    // Draw vertical lines
    for (double x = startX; x <= endX; x += gridSize) {
      canvas.drawLine(Offset(x, startY), Offset(x, endY), paint);
    }
    
    // Draw horizontal lines
    for (double y = startY; y <= endY; y += gridSize) {
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
  return oldDelegate.elements != elements ||
    oldDelegate.scale != scale ||
    oldDelegate.panOffset != panOffset ||
    oldDelegate.backgroundColor != backgroundColor ||
    oldDelegate.gridColor != gridColor;
  }
}