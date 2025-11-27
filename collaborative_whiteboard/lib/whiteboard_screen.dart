import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import './whiteboard_model.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({Key? key}) : super(key: key);

  @override
  _WhiteboardScreenState createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  Color _selectedColor = Colors.black;
  double _strokeWidth = 5.0;
  List<DrawingPoint?> _points = [];
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    // Set up a timer to periodically sync with the database
    _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      final model = Provider.of<WhiteboardModel>(context, listen: false);
      model.syncDrawing(_points);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final point = DrawingPoint(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      offsets: [box.globalToLocal(details.globalPosition)],
      color: _selectedColor,
      width: _strokeWidth,
    );
    
    setState(() {
      _points.add(point);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final box = context.findRenderObject() as RenderBox;
    final position = box.globalToLocal(details.globalPosition);
    
    setState(() {
      if (_points.isNotEmpty) {
        final lastPoint = _points.last;
        if (lastPoint != null) {
          final updatedPoint = DrawingPoint(
            id: lastPoint.id,
            offsets: [...lastPoint.offsets, position],
            color: lastPoint.color,
            width: lastPoint.width,
          );
          _points[_points.length - 1] = updatedPoint;
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    // Save the drawing to the model when a stroke is completed
    final model = Provider.of<WhiteboardModel>(context, listen: false);
    model.syncDrawing(_points);
  }

  void _clearCanvas() {
    setState(() {
      _points.clear();
    });
    
    // Clear drawing in the model
    final model = Provider.of<WhiteboardModel>(context, listen: false);
    model.clearDrawing();
  }

  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<WhiteboardModel>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collaborative Whiteboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearCanvas,
          ),
          IconButton(
            icon: const Icon(Icons.color_lens),
            onPressed: _showColorPicker,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Draw the stored points from the model
            if (model.drawingPoints.isNotEmpty)
              CustomPaint(
                size: Size.infinite,
                painter: WhiteboardPainter(points: model.drawingPoints),
              ),
              
            // Draw the current user's points
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              child: CustomPaint(
                size: Size.infinite,
                painter: WhiteboardPainter(points: _points),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          height: 60.0,
          child: Row(
            children: [
              const Text('Stroke Width: '),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1.0,
                  max: 20.0,
                  onChanged: (value) {
                    setState(() {
                      _strokeWidth = value;
                    });
                  },
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: _selectedColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  WhiteboardPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (point == null || point.offsets.isEmpty) continue;

      final offsets = point.offsets;
      if (offsets.length < 2) continue;

      final paint = Paint()
        ..color = point.color
        ..strokeWidth = point.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(offsets[0].dx, offsets[0].dy);

      for (int j = 1; j < offsets.length; j++) {
        path.lineTo(offsets[j].dx, offsets[j].dy);
      }

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}

class DrawingPoint {
  final String id;
  final List<Offset> offsets;
  final Color color;
  final double width;

  DrawingPoint({
    required this.id,
    required this.offsets,
    required this.color,
    required this.width,
  });

  // Convert to map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'offsets': offsets.map((offset) => {'dx': offset.dx, 'dy': offset.dy}).toList(),
      'color': color.value,
      'width': width,
    };
  }

  // Create from map for database retrieval
  factory DrawingPoint.fromMap(Map<String, dynamic> map) {
    final offsetsList = (map['offsets'] as List).map((item) {
      return Offset(item['dx'], item['dy']);
    }).toList();
    
    return DrawingPoint(
      id: map['id'],
      offsets: offsetsList,
      color: Color(map['color']),
      width: map['width'],
    );
  }
}