import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing.dart';
import '../models/whiteboard_model.dart';
import '../services/whiteboard_service_sqlite.dart';

class CollaborativeDrawingPage extends StatefulWidget {
  final String whiteboardId;
  final String whiteboardName;

  const CollaborativeDrawingPage({
    Key? key,
    required this.whiteboardId,
    required this.whiteboardName,
  }) : super(key: key);

  @override
  CollaborativeDrawingPageState createState() => CollaborativeDrawingPageState();
}

class CollaborativeDrawingPageState extends State<CollaborativeDrawingPage> {
  Timer? _syncTimer;
  final TransformationController _transformationController = TransformationController();
  bool _isDrawing = false;
  List<Offset> _currentStroke = [];
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    
    // Load the whiteboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final whiteboardService = Provider.of<WhiteboardServiceSQLite>(context, listen: false);
      whiteboardService.loadWhiteboard(widget.whiteboardId);
      
      // Set up a timer to periodically sync changes
      _syncTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        whiteboardService.saveElements();
      });
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _transformationController.dispose();
    
    // Save any pending changes before disposing
    final whiteboardService = Provider.of<WhiteboardServiceSQLite>(context, listen: false);
    whiteboardService.saveElements();
    
    super.dispose();
  }

  void _handlePanStart(DragStartDetails details) {
    final whiteboardService = Provider.of<WhiteboardServiceSQLite>(context, listen: false);
    
    // Convert screen position to drawing position
    final viewportOffset = details.localPosition;
    
    setState(() {
      _isDrawing = true;
      _currentStroke = [viewportOffset];
    });
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    
    final viewportOffset = details.localPosition;
    
    setState(() {
      _currentStroke.add(viewportOffset);
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    if (!_isDrawing || _currentStroke.length < 2) {
      setState(() {
        _isDrawing = false;
        _currentStroke.clear();
      });
      return;
    }
    
    final whiteboardService = Provider.of<WhiteboardServiceSQLite>(context, listen: false);
    
    // Create a path element
    final pathElement = PathElement(
      id: _uuid.v4(),
      color: whiteboardService.currentColor,
      strokeWidth: whiteboardService.currentStrokeWidth,
      points: List.from(_currentStroke),
    );
    
    // Add the element to the whiteboard
    whiteboardService.addElement(pathElement);
    
    setState(() {
      _isDrawing = false;
      _currentStroke.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.whiteboardName),
        actions: [
          _buildUndoButton(),
          _buildRedoButton(),
          _buildClearButton(),
        ],
      ),
      body: Consumer<WhiteboardServiceSQLite>(
        builder: (context, whiteboardService, child) {
          return Stack(
            children: [
              // Main drawing area with zoom/pan capability
              GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 3.0,
                  boundaryMargin: const EdgeInsets.all(double.infinity),
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(
                      painter: WhiteboardPainter(
                        elements: whiteboardService.elements,
                        currentStroke: _isDrawing ? _currentStroke : null,
                        currentColor: whiteboardService.currentColor,
                        currentStrokeWidth: whiteboardService.currentStrokeWidth,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Toolbar overlay
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: _buildToolbar(whiteboardService),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildUndoButton() {
    return Consumer<WhiteboardServiceSQLite>(
      builder: (context, whiteboardService, child) {
        return IconButton(
          icon: const Icon(Icons.undo),
          onPressed: whiteboardService.canUndo ? whiteboardService.undo : null,
        );
      },
    );
  }
  
  Widget _buildRedoButton() {
    return Consumer<WhiteboardServiceSQLite>(
      builder: (context, whiteboardService, child) {
        return IconButton(
          icon: const Icon(Icons.redo),
          onPressed: whiteboardService.canRedo ? whiteboardService.redo : null,
        );
      },
    );
  }
  
  Widget _buildClearButton() {
    return Consumer<WhiteboardServiceSQLite>(
      builder: (context, whiteboardService, child) {
        return IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Clear Whiteboard'),
                content: const Text('Are you sure you want to clear all elements?'),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text('Clear'),
                    onPressed: () {
                      whiteboardService.clearElements();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildToolbar(WhiteboardServiceSQLite whiteboardService) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildToolButton(
              icon: Icons.edit,
              isSelected: whiteboardService.currentTool == DrawingToolType.pen,
              onPressed: () => whiteboardService.setCurrentTool(DrawingToolType.pen),
            ),
            _buildToolButton(
              icon: Icons.line_weight,
              isSelected: whiteboardService.currentTool == DrawingToolType.line,
              onPressed: () => whiteboardService.setCurrentTool(DrawingToolType.line),
            ),
            _buildToolButton(
              icon: Icons.rectangle_outlined,
              isSelected: whiteboardService.currentTool == DrawingToolType.rectangle,
              onPressed: () => whiteboardService.setCurrentTool(DrawingToolType.rectangle),
            ),
            _buildToolButton(
              icon: Icons.circle_outlined,
              isSelected: whiteboardService.currentTool == DrawingToolType.circle,
              onPressed: () => whiteboardService.setCurrentTool(DrawingToolType.circle),
            ),
            _buildToolButton(
              icon: Icons.text_fields,
              isSelected: whiteboardService.currentTool == DrawingToolType.text,
              onPressed: () => whiteboardService.setCurrentTool(DrawingToolType.text),
            ),
            _buildToolButton(
              icon: Icons.auto_fix_high,
              isSelected: whiteboardService.currentTool == DrawingToolType.select,
              onPressed: () => whiteboardService.setCurrentTool(DrawingToolType.select),
            ),
            _buildColorPicker(whiteboardService),
            _buildStrokeWidthSelector(whiteboardService),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToolButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon),
        color: isSelected ? Theme.of(context).primaryColor : null,
        onPressed: onPressed,
      ),
    );
  }
  
  Widget _buildColorPicker(WhiteboardServiceSQLite whiteboardService) {
    return GestureDetector(
      onTap: () => _showColorPicker(whiteboardService),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: whiteboardService.currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
  
  void _showColorPicker(WhiteboardServiceSQLite whiteboardService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: whiteboardService.currentColor,
              onColorChanged: whiteboardService.setCurrentColor,
              enableAlpha: false,
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
  
  Widget _buildStrokeWidthSelector(WhiteboardServiceSQLite whiteboardService) {
    return GestureDetector(
      onTap: () => _showStrokeWidthSelector(whiteboardService),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
        child: Center(
          child: Container(
            width: whiteboardService.currentStrokeWidth,
            height: whiteboardService.currentStrokeWidth,
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
  
  void _showStrokeWidthSelector(WhiteboardServiceSQLite whiteboardService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double strokeWidth = whiteboardService.currentStrokeWidth;
        
        return AlertDialog(
          title: const Text('Select Stroke Width'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    value: strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    divisions: 19,
                    label: strokeWidth.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() {
                        strokeWidth = value;
                      });
                    },
                  ),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: Container(
                        width: strokeWidth,
                        height: strokeWidth,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Apply'),
              onPressed: () {
                whiteboardService.setCurrentStrokeWidth(strokeWidth);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class WhiteboardPainter extends CustomPainter {
  final List<DrawElement> elements;
  final List<Offset>? currentStroke;
  final Color currentColor;
  final double currentStrokeWidth;
  
  WhiteboardPainter({
    required this.elements,
    this.currentStroke,
    required this.currentColor,
    required this.currentStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw all stored elements
    for (var element in elements) {
      element.draw(canvas);
    }
    
    // Draw current stroke if one is in progress
    if (currentStroke != null && currentStroke!.length >= 2) {
      final paint = Paint()
        ..color = currentColor
        ..strokeWidth = currentStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
        
      final path = Path();
      path.moveTo(currentStroke![0].dx, currentStroke![0].dy);
      
      for (int i = 1; i < currentStroke!.length; i++) {
        path.lineTo(currentStroke![i].dx, currentStroke![i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}

// Import Flutter Color Picker
class ColorPicker extends StatefulWidget {
  final Color pickerColor;
  final ValueChanged<Color> onColorChanged;
  final bool enableAlpha;
  final double pickerAreaHeightPercent;

  const ColorPicker({
    Key? key,
    required this.pickerColor,
    required this.onColorChanged,
    this.enableAlpha = true,
    this.pickerAreaHeightPercent = 1.0,
  }) : super(key: key);

  @override
  _ColorPickerState createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  // Define a list of material colors
  final List<Color> _materialColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
    Colors.white,
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300 * widget.pickerAreaHeightPercent,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemCount: _materialColors.length,
        itemBuilder: (context, index) {
          final color = _materialColors[index];
          return InkWell(
            onTap: () => widget.onColorChanged(color),
            child: Container(
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: color == widget.pickerColor
                      ? Colors.blue
                      : Colors.grey.shade300,
                  width: color == widget.pickerColor ? 3 : 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}