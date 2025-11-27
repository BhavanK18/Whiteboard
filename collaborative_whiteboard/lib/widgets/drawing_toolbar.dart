import 'package:flutter/material.dart';
import '../models/drawing.dart';

class DrawingToolbar extends StatelessWidget {
  final DrawingToolType currentTool;
  final Color currentColor;
  final Function(DrawingToolType) onToolChanged;
  final VoidCallback onColorPickerPressed;
  final ValueChanged<TapDownDetails> onStrokeWidthTapDown;
  final VoidCallback onFontSizePressed;
  final VoidCallback onUndoPressed;
  final VoidCallback onRedoPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onClearCurrentPressed;
  final VoidCallback? onClearAllPressed;

  const DrawingToolbar({
    super.key,
    required this.currentTool,
    required this.currentColor,
    required this.onToolChanged,
    required this.onColorPickerPressed,
    required this.onStrokeWidthTapDown,
    required this.onFontSizePressed,
    required this.onUndoPressed,
    required this.onRedoPressed,
    required this.onDeletePressed,
    required this.onClearCurrentPressed,
    this.onClearAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToolButton(
                context: context,
                icon: Icons.edit,
                tooltip: 'Pen',
                tool: DrawingToolType.pen,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.horizontal_rule,
                tooltip: 'Line',
                tool: DrawingToolType.line,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.arrow_forward,
                tooltip: 'Arrow',
                tool: DrawingToolType.arrow,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.rectangle_outlined,
                tooltip: 'Rectangle',
                tool: DrawingToolType.rectangle,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.circle_outlined,
                tooltip: 'Circle',
                tool: DrawingToolType.circle,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.change_history,
                tooltip: 'Triangle',
                tool: DrawingToolType.triangle,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.text_fields,
                tooltip: 'Text',
                tool: DrawingToolType.text,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.pan_tool,
                tooltip: 'Select',
                tool: DrawingToolType.select,
              ),
              _buildToolButton(
                context: context,
                icon: Icons.auto_fix_high,
                tooltip: 'Eraser',
                tool: DrawingToolType.eraser,
              ),
              const VerticalDivider(
                indent: 8,
                endIndent: 8,
                thickness: 1,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.palette,
                tooltip: 'Color',
                onPressed: onColorPickerPressed,
                showIndicator: true,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.line_weight,
                tooltip: 'Stroke Width',
                onPressed: () {},
                onTapDown: onStrokeWidthTapDown,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.format_size,
                tooltip: 'Font Size',
                onPressed: onFontSizePressed,
              ),
              const VerticalDivider(
                indent: 8,
                endIndent: 8,
                thickness: 1,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.undo,
                tooltip: 'Undo',
                onPressed: onUndoPressed,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.redo,
                tooltip: 'Redo',
                onPressed: onRedoPressed,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.delete,
                tooltip: 'Delete Selected',
                onPressed: onDeletePressed,
              ),
              const VerticalDivider(
                indent: 8,
                endIndent: 8,
                thickness: 1,
              ),
              _buildActionButton(
                context: context,
                icon: Icons.delete_sweep,
                tooltip: onClearAllPressed != null
                    ? 'Clear Page (tap) · Clear All (press & hold)'
                    : 'Clear Page',
                onPressed: onClearCurrentPressed,
                onLongPress: onClearAllPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required DrawingToolType tool,
  }) {
    final isSelected = currentTool == tool;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => onToolChanged(tool),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 50,
          height: double.infinity,
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : null,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool showIndicator = false,
    ValueChanged<TapDownDetails>? onTapDown,
    VoidCallback? onLongPress,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        onTapDown: onTapDown,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 50,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                color: null,
                size: 24,
              ),
              if (showIndicator)
                Positioned(
                  bottom: 10,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: currentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).canvasColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}