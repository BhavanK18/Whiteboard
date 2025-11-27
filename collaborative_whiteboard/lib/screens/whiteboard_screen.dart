import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

import '../models/drawing.dart';
import '../models/whiteboard_page.dart';
import '../services/realtime_whiteboard_service.dart';
import '../widgets/drawing_canvas.dart';

class WhiteboardScreen extends StatefulWidget {
  const WhiteboardScreen({super.key});

  @override
  State<WhiteboardScreen> createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> {
  final Map<String, List<Offset>> _activePaths = <String, List<Offset>>{};
  final TextEditingController _textController = TextEditingController();
  DrawingToolType? _optionsForTool;
  bool _showToolOptions = false;
  Offset? _lastMovePosition;
  Offset? _lastPanPosition;

  static const List<Color> _quickPalette = <Color>[
    Color(0xFF1E88E5),
    Color(0xFF1565C0),
    Color(0xFF00897B),
    Color(0xFF43A047),
    Color(0xFFFDD835),
    Color(0xFFF57C00),
    Color(0xFFD81B60),
    Color(0xFF8E24AA),
    Color(0xFF5E35B1),
    Color(0xFF455A64),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeWhiteboardService>(
      builder: (context, service, _) {
        final WhiteboardPage fallbackPage = _ensurePage(service);
        final String pageId = service.activePageId ?? fallbackPage.id;
        final WhiteboardPage activePage = service.activePage ?? fallbackPage;
        final ThemeData theme = Theme.of(context);
        final bool optionsVisible =
            _showToolOptions && _optionsForTool != null && _optionsForTool != DrawingToolType.select;
        final Color gridColor = theme.brightness == Brightness.dark
            ? const Color(0xFF2C3444).withOpacity(0.18)
            : const Color(0xFFE9ECF5).withOpacity(0.12);

        return Scaffold(
          backgroundColor: theme.colorScheme.background,
          body: SafeArea(
            minimum: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTopBar(service),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) => _handleTap(details, service, pageId),
                              onPanStart: (details) => _handlePanStart(details, service, pageId),
                              onPanUpdate: (details) => _handlePanUpdate(details, service, pageId),
                              onPanEnd: (_) => _handlePanEnd(service, pageId),
                              child: DrawingCanvas(
                                elements: service.elements,
                                scale: service.scaleForPage(pageId),
                                panOffset: service.panOffsetForPage(pageId),
                                backgroundColor: activePage.backgroundColor,
                                gridColor: gridColor,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 16,
                          child: _buildFloatingToolbar(service),
                        ),
                        if (optionsVisible)
                          Positioned(
                            left: 96,
                            top: 16,
                            child: _buildToolOptionsSheet(service),
                          ),
                        Positioned(
                          right: 16,
                          bottom: 28,
                          child: _buildUtilityCluster(service, pageId),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildPageStrip(service, pageId),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(RealtimeWhiteboardService service) {
    final ThemeData theme = Theme.of(context);
    final String title = service.currentDocument?.title ?? 'Untitled presentation';
    final WhiteboardPage? page = service.activePage;
    final bool hasUnsavedChanges = service.hasUnsavedChanges;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.82 : 0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.32 : 0.14),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.gesture_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: hasUnsavedChanges
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasUnsavedChanges ? 'Unsaved changes' : 'All changes saved',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.textTheme.labelMedium?.color?.withOpacity(0.72),
                      ),
                    ),
                    if (page != null) ...[
                      const SizedBox(width: 16),
                      Text(
                        'Viewing ${page.name}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.textTheme.labelMedium?.color?.withOpacity(0.72),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _HoverButton(
                icon: Icons.bookmark_added_rounded,
                tooltip: 'Save to library',
                onTap: () async {
                  await service.saveDocument();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Presentation saved')),
                  );
                },
              ),
              _HoverButton(
                icon: Icons.download_rounded,
                tooltip: 'Download project file',
                onTap: () async {
                  final bool didSave = await service.saveDocumentToFile();
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(didSave ? 'Whiteboard file saved' : 'Save cancelled'),
                    ),
                  );
                },
              ),
              _HoverButton(
                icon: Icons.ios_share_rounded,
                tooltip: 'Export JSON',
                onTap: () => _showExportDialog(context, service),
              ),
              _HoverButton(
                icon: Icons.picture_as_pdf_rounded,
                tooltip: 'Export as PDF',
                onTap: () => _handleExportPdf(service),
              ),
              _HoverButton(
                icon: Icons.slideshow_rounded,
                tooltip: 'Export as PowerPoint',
                onTap: () => _handleExportPptx(service),
              ),
              Tooltip(
                message: 'More options',
                child: PopupMenuButton<String>(
                  elevation: 6,
                  offset: const Offset(0, 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'import', child: Text('Import from file')),
                    PopupMenuItem(value: 'rename', child: Text('Rename presentation')),
                    PopupMenuItem(value: 'new', child: Text('New presentation')),
                  ],
                  onSelected: (value) async {
                    switch (value) {
                      case 'import':
                        final bool loaded = await service.loadDocumentFromFile();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loaded ? 'Presentation imported' : 'Import cancelled'),
                          ),
                        );
                        break;
                      case 'rename':
                        _showRenameDialog(context, service);
                        break;
                      case 'new':
                        await service.createNewDocument();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Started new presentation')),
                        );
                        break;
                    }
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.16)),
                    ),
                    child: Icon(
                      Icons.more_horiz_rounded,
                      color: theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingToolbar(RealtimeWhiteboardService service) {
    final ThemeData theme = Theme.of(context);
    const List<_ToolConfig> toolItems = <_ToolConfig>[
      _ToolConfig(DrawingToolType.select, Icons.near_me_rounded, 'Select'),
      _ToolConfig(DrawingToolType.pen, Icons.edit_rounded, 'Pen'),
      _ToolConfig(DrawingToolType.eraser, Icons.auto_fix_off_rounded, 'Eraser'),
      _ToolConfig(DrawingToolType.line, Icons.show_chart_rounded, 'Line'),
      _ToolConfig(DrawingToolType.rectangle, Icons.crop_square_rounded, 'Rectangle'),
      _ToolConfig(DrawingToolType.circle, Icons.circle_outlined, 'Circle'),
      _ToolConfig(DrawingToolType.triangle, Icons.change_history_rounded, 'Triangle'),
      _ToolConfig(DrawingToolType.arrow, Icons.call_made_rounded, 'Arrow'),
      _ToolConfig(DrawingToolType.text, Icons.title_rounded, 'Text'),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.78),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.24 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < toolItems.length; i++) ...[
              _HoverButton(
                icon: toolItems[i].icon,
                tooltip: toolItems[i].label,
                dimension: 46,
                active: service.currentTool == toolItems[i].type,
                onTap: () => _onToolSelected(toolItems[i].type, service),
              ),
              if (i != toolItems.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildToolOptionsSheet(RealtimeWhiteboardService service) {
    final ThemeData theme = Theme.of(context);
    final DrawingToolType? tool = _optionsForTool;
    if (tool == null || tool == DrawingToolType.select) {
      return const SizedBox.shrink();
    }

    final bool showColorPalette = tool != DrawingToolType.eraser;
    final bool showStrokeSlider = tool != DrawingToolType.select;
    final bool showFontSlider = tool == DrawingToolType.text;
    final double minStroke = tool == DrawingToolType.eraser ? 8 : 1;
    final double maxStroke = tool == DrawingToolType.eraser ? 60 : 40;
    final double strokeValue = service.currentStrokeWidth.clamp(minStroke, maxStroke).toDouble();
    final double fontValue = service.currentFontSize.clamp(12, 96).toDouble();

    final String toolLabel;
    switch (tool) {
      case DrawingToolType.pen:
        toolLabel = 'Pen settings';
        break;
      case DrawingToolType.eraser:
        toolLabel = 'Eraser width';
        break;
      case DrawingToolType.line:
        toolLabel = 'Line settings';
        break;
      case DrawingToolType.rectangle:
        toolLabel = 'Rectangle settings';
        break;
      case DrawingToolType.circle:
        toolLabel = 'Circle settings';
        break;
      case DrawingToolType.triangle:
        toolLabel = 'Triangle settings';
        break;
      case DrawingToolType.arrow:
        toolLabel = 'Arrow settings';
        break;
      case DrawingToolType.text:
        toolLabel = 'Text settings';
        break;
      case DrawingToolType.select:
        toolLabel = 'Selection';
        break;
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _showToolOptions ? 1 : 0,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.94),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.32 : 0.18),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      toolLabel,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  _HoverButton(
                    icon: Icons.close_rounded,
                    dimension: 36,
                    tooltip: 'Hide options',
                    onTap: _dismissToolOptions,
                  ),
                ],
              ),
              if (showStrokeSlider) ...[
                const SizedBox(height: 16),
                Text('Stroke width', style: theme.textTheme.labelMedium),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    min: minStroke,
                    max: maxStroke,
                    value: strokeValue,
                    onChanged: service.setCurrentStrokeWidth,
                  ),
                ),
              ],
              if (showFontSlider) ...[
                const SizedBox(height: 16),
                Text('Font size', style: theme.textTheme.labelMedium),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    overlayShape: SliderComponentShape.noOverlay,
                  ),
                  child: Slider(
                    min: 12,
                    max: 96,
                    value: fontValue,
                    onChanged: service.setCurrentFontSize,
                  ),
                ),
              ],
              if (showColorPalette) ...[
                const SizedBox(height: 16),
                Text('Quick colors', style: theme.textTheme.labelMedium),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final Color color in _quickPalette)
                      _ColorSwatchDot(
                        color: color,
                        selected: service.currentColor.value == color.value,
                        onTap: () => service.setCurrentColor(color),
                      ),
                    _HoverButton(
                      icon: Icons.palette_rounded,
                      dimension: 36,
                      tooltip: 'More colors',
                      onTap: () => _showColorPicker(context, service.currentColor, service.setCurrentColor),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityCluster(RealtimeWhiteboardService service, String pageId) {
    final ThemeData theme = Theme.of(context);
    final List<WhiteboardPage> pages = service.pages;
    final bool canDeletePage = pages.length > 1;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.78),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.24 : 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HoverButton(
              icon: Icons.undo_rounded,
              tooltip: 'Undo',
              onTap: service.undo,
            ),
            _HoverButton(
              icon: Icons.redo_rounded,
              tooltip: 'Redo',
              onTap: service.redo,
            ),
            const SizedBox(height: 4),
            _HoverButton(
              icon: Icons.zoom_in_rounded,
              tooltip: 'Zoom in',
              onTap: () => _adjustZoom(service, increase: true),
            ),
            _HoverButton(
              icon: Icons.zoom_out_rounded,
              tooltip: 'Zoom out',
              onTap: () => _adjustZoom(service, increase: false),
            ),
            _HoverButton(
              icon: Icons.center_focus_strong_rounded,
              tooltip: 'Reset view',
              onTap: () => _resetView(service),
            ),
            const SizedBox(height: 6),
            _HoverButton(
              icon: Icons.color_lens_rounded,
              tooltip: 'Canvas color',
              onTap: () => _showBackgroundColorPicker(service, pageId),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              width: 48,
              color: theme.colorScheme.outlineVariant.withOpacity(0.28),
            ),
            const SizedBox(height: 10),
            _HoverButton(
              icon: Icons.add_rounded,
              dimension: 44,
              tooltip: 'Add page',
              onTap: () => service.createPage(),
            ),
            const SizedBox(height: 6),
            _HoverButton(
              icon: Icons.content_copy_rounded,
              dimension: 44,
              tooltip: 'Duplicate page',
              onTap: () => service.duplicatePage(pageId),
            ),
            if (canDeletePage) ...[
              const SizedBox(height: 6),
              _HoverButton(
                icon: Icons.delete_sweep_rounded,
                dimension: 44,
                tooltip: 'Delete page',
                onTap: () => service.deletePage(pageId),
              ),
            ],
            const SizedBox(height: 6),
            _HoverButton(
              icon: Icons.auto_fix_high_rounded,
              dimension: 44,
              tooltip: 'Clear page',
              onTap: () => service.clearPage(pageId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageStrip(RealtimeWhiteboardService service, String activePageId) {
    final ThemeData theme = Theme.of(context);
    final List<WhiteboardPage> pages = service.pages;
    if (pages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withOpacity(0.82),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.18 : 0.1),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < pages.length; i++) ...[
                  _PageChip(
                    label: pages[i].name,
                    active: pages[i].id == activePageId,
                    onTap: () => service.setActivePage(pages[i].id),
                  ),
                  if (i != pages.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onToolSelected(DrawingToolType tool, RealtimeWhiteboardService service) {
    FocusScope.of(context).unfocus();
    service.setCurrentTool(tool);
    setState(() {
      if (_optionsForTool == tool && _showToolOptions) {
        _showToolOptions = false;
      } else {
        _optionsForTool = tool;
        _showToolOptions = tool != DrawingToolType.select;
      }
    });
  }

  void _dismissToolOptions() {
    if (_showToolOptions) {
      setState(() {
        _showToolOptions = false;
      });
    }
  }

  WhiteboardPage _ensurePage(RealtimeWhiteboardService service) {
    if (service.pages.isEmpty) {
      return service.createPage();
    }
    return service.pages.first;
  }

  void _adjustZoom(RealtimeWhiteboardService service, {required bool increase}) {
    final String? pageId = service.activePageId;
    if (pageId == null) return;
    final double currentScale = service.scaleForPage(pageId);
    final double nextScale = (increase ? currentScale + 0.1 : currentScale - 0.1).clamp(0.2, 5.0);
    service.updateViewState(pageId, nextScale, service.panOffsetForPage(pageId));
  }

  void _resetView(RealtimeWhiteboardService service) {
    final String? pageId = service.activePageId;
    if (pageId == null) return;
    service.updateViewState(pageId, 1.0, Offset.zero);
  }

  void _handlePanStart(DragStartDetails details, RealtimeWhiteboardService service, String pageId) {
    final Offset boardPoint = _toBoardSpace(details.localPosition, service, pageId);
    switch (service.currentTool) {
      case DrawingToolType.pen:
      case DrawingToolType.eraser:
        final List<Offset> points = <Offset>[boardPoint];
        _activePaths[pageId] = points;
        service.addPathPoint(boardPoint, points);
        break;
      case DrawingToolType.line:
        service.beginLine(boardPoint, pageId: pageId);
        break;
      case DrawingToolType.rectangle:
        service.beginRectangle(boardPoint, pageId: pageId);
        break;
      case DrawingToolType.circle:
        service.beginCircle(boardPoint, pageId: pageId);
        break;
      case DrawingToolType.triangle:
        service.beginTriangle(boardPoint, pageId: pageId);
        break;
      case DrawingToolType.arrow:
        service.beginArrow(boardPoint, pageId: pageId);
        break;
      case DrawingToolType.select:
        service.selectElementAt(boardPoint);
        _lastMovePosition = boardPoint;
        _lastPanPosition = details.localPosition;
        break;
      case DrawingToolType.text:
        break;
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, RealtimeWhiteboardService service, String pageId) {
    final Offset boardPoint = _toBoardSpace(details.localPosition, service, pageId);
    switch (service.currentTool) {
      case DrawingToolType.pen:
      case DrawingToolType.eraser:
        final List<Offset>? points = _activePaths[pageId];
        if (points != null) {
          points.add(boardPoint);
          service.addPathPoint(boardPoint, points);
        }
        break;
      case DrawingToolType.line:
        service.updateLine(boardPoint);
        break;
      case DrawingToolType.rectangle:
        service.updateRectangle(boardPoint);
        break;
      case DrawingToolType.circle:
        service.updateCircle(boardPoint);
        break;
      case DrawingToolType.triangle:
        service.updateTriangle(boardPoint);
        break;
      case DrawingToolType.arrow:
        service.updateArrow(boardPoint);
        break;
      case DrawingToolType.select:
        if (service.selectedElement != null && _lastMovePosition != null) {
          final Offset delta = boardPoint - _lastMovePosition!;
          service.moveSelectedElement(delta);
          _lastMovePosition = boardPoint;
        } else {
          final Offset currentPan = service.panOffsetForPage(pageId);
          final Offset deltaScreen = details.localPosition - (_lastPanPosition ?? details.localPosition);
          _lastPanPosition = details.localPosition;
          service.updateViewState(pageId, service.scaleForPage(pageId), currentPan + deltaScreen);
        }
        break;
      case DrawingToolType.text:
        break;
    }
  }

  void _handlePanEnd(RealtimeWhiteboardService service, String pageId) {
    switch (service.currentTool) {
      case DrawingToolType.pen:
      case DrawingToolType.eraser:
        final List<Offset>? points = _activePaths.remove(pageId);
        if (points != null) {
          service.finalizePath(points);
        }
        break;
      case DrawingToolType.line:
        service.finalizeLine();
        break;
      case DrawingToolType.rectangle:
        service.finalizeRectangle();
        break;
      case DrawingToolType.circle:
        service.finalizeCircle();
        break;
      case DrawingToolType.triangle:
        service.finalizeTriangle();
        break;
      case DrawingToolType.arrow:
        service.finalizeArrow();
        break;
      case DrawingToolType.select:
        service.finalizeElementMove();
        _lastMovePosition = null;
        _lastPanPosition = null;
        break;
      case DrawingToolType.text:
        break;
    }
    service.disposeDrafts();
  }

  void _handleTap(TapUpDetails details, RealtimeWhiteboardService service, String pageId) {
    final Offset boardPoint = _toBoardSpace(details.localPosition, service, pageId);
    switch (service.currentTool) {
      case DrawingToolType.text:
        _showTextDialog(boardPoint, service);
        break;
      case DrawingToolType.select:
        service.selectElementAt(boardPoint);
        break;
      default:
        break;
    }
  }

  Offset _toBoardSpace(Offset position, RealtimeWhiteboardService service, String pageId) {
    final double scale = service.scaleForPage(pageId);
    final Offset pan = service.panOffsetForPage(pageId);
    return Offset(
      (position.dx - pan.dx) / scale,
      (position.dy - pan.dy) / scale,
    );
  }

  void _showTextDialog(Offset position, RealtimeWhiteboardService service) {
    _textController.clear();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add text'),
        content: TextField(
          controller: _textController,
          autofocus: true,
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final String text = _textController.text.trim();
              if (text.isNotEmpty) {
                service.addText(position, text);
              }
              Navigator.of(context).pop();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBackgroundColorPicker(RealtimeWhiteboardService service, String pageId) async {
    final ThemeData theme = Theme.of(context);
    final Color currentColor = service.backgroundColorForPage(pageId);
    Color workingColor = currentColor;

    final Color? selectedColor = await showDialog<Color>(
      context: context,
      barrierColor: theme.colorScheme.scrim.withOpacity(0.4),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Canvas background'),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: workingColor,
                    onColorChanged: (color) => setState(() => workingColor = color),
                    enableAlpha: false,
                    displayThumbColor: true,
                    paletteType: PaletteType.hsl,
                    labelTypes: const [ColorLabelType.rgb, ColorLabelType.hsv],
                    hexInputBar: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      color: workingColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.18)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(const Color(0xFFFFFFFF)),
                  child: const Text('Reset to white'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(workingColor),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (selectedColor != null && selectedColor.value != currentColor.value) {
      service.setPageBackgroundColor(pageId, selectedColor);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Canvas color updated for ${service.activePage?.name ?? 'current page'}'),
        ),
      );
    }
  }

  void _showColorPicker(BuildContext context, Color initialColor, ValueChanged<Color> onChanged) {
    final ThemeData theme = Theme.of(context);
    Color workingColor = initialColor;

    showDialog<void>(
      context: context,
      barrierColor: theme.colorScheme.scrim.withOpacity(0.4),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Select color'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ColorPicker(
                  pickerColor: workingColor,
                  onColorChanged: (color) {
                    setState(() => workingColor = color);
                    onChanged(color);
                  },
                  enableAlpha: false,
                  displayThumbColor: true,
                  paletteType: PaletteType.hsv,
                  labelTypes: const [ColorLabelType.hex],
                  hexInputBar: true,
                ),
                const SizedBox(height: 16),
                Container(
                  height: 48,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: workingColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.18)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportDialog(BuildContext context, RealtimeWhiteboardService service) async {
    final String json = await service.exportCurrentDocumentAsJson();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export JSON'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(child: SelectableText(json)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportPdf(RealtimeWhiteboardService service) async {
    await _exportDocument(
      action: () => service.exportDocumentAsPdf(),
      successMessage: 'PDF exported successfully',
      cancelMessage: 'Export cancelled',
      errorMessage: 'Failed to export PDF',
    );
  }

  Future<void> _handleExportPptx(RealtimeWhiteboardService service) async {
    await _exportDocument(
      action: () => service.exportDocumentAsPptx(),
      successMessage: 'PowerPoint exported successfully',
      cancelMessage: 'Export cancelled',
      errorMessage: 'Failed to export PowerPoint',
    );
  }

  Future<void> _exportDocument({
    required Future<bool> Function() action,
    required String successMessage,
    required String cancelMessage,
    required String errorMessage,
  }) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.2),
      builder: (context) => const Center(
        child: SizedBox(
          width: 64,
          height: 64,
          child: CircularProgressIndicator(),
        ),
      ),
    );

    bool? outcome;
    Object? error;
    try {
      outcome = await action();
    } catch (err, stack) {
      error = err;
      debugPrint('Export error: $err\n$stack');
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    if (!mounted) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(outcome == true ? successMessage : cancelMessage)),
    );
  }

  void _showRenameDialog(BuildContext context, RealtimeWhiteboardService service) {
    final TextEditingController controller =
        TextEditingController(text: service.currentDocument?.title ?? 'Untitled Presentation');

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename presentation'),
        content: TextField(
          controller: controller,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await service.renameCurrentDocument(controller.text);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }
}

class _ToolConfig {
  const _ToolConfig(this.type, this.icon, this.label);

  final DrawingToolType type;
  final IconData icon;
  final String label;
}

class _HoverButton extends StatefulWidget {
  const _HoverButton({
    required this.icon,
    this.onTap,
    this.tooltip,
    this.active = false,
    this.dimension = 44,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool active;
  final double dimension;

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovering = false;

  bool get _isEnabled => widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool active = widget.active;
    final double dimension = widget.dimension;

    final Color baseColor = active
        ? theme.colorScheme.primary.withOpacity(_hovering ? 0.28 : 0.2)
        : theme.colorScheme.surfaceVariant.withOpacity(_hovering ? 0.55 : 0.38);
    final Color borderColor = active
        ? theme.colorScheme.primary.withOpacity(0.5)
        : theme.colorScheme.outline.withOpacity(0.14);
    final Color iconColor = active
        ? theme.colorScheme.primary
        : theme.iconTheme.color ?? theme.colorScheme.onSurfaceVariant;

    Widget button = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(dimension * 0.36),
        border: Border.all(color: borderColor, width: active ? 1.4 : 1),
        boxShadow: _hovering || active
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(active ? 0.24 : 0.12),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : const [],
      ),
      child: Icon(
        widget.icon,
        size: dimension * 0.48,
        color: _isEnabled ? iconColor : iconColor.withOpacity(0.4),
      ),
    );

    button = MouseRegion(
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      cursor: _isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: button,
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

class _PageChip extends StatefulWidget {
  const _PageChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_PageChip> createState() => _PageChipState();
}

class _PageChipState extends State<_PageChip> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool active = widget.active;

    final Color background = active
        ? theme.colorScheme.primary.withOpacity(_hovering ? 0.26 : 0.18)
        : theme.colorScheme.surfaceVariant.withOpacity(_hovering ? 0.55 : 0.34);
    final Color borderColor = active
        ? theme.colorScheme.primary.withOpacity(0.5)
        : theme.colorScheme.outline.withOpacity(0.16);
    final Color textColor = active
        ? theme.colorScheme.primary
        : theme.textTheme.labelLarge?.color ?? theme.colorScheme.onSurface;

    Widget chip = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        widget.label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          color: textColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    chip = MouseRegion(
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: chip,
      ),
    );

    return chip;
  }
}

class _ColorSwatchDot extends StatefulWidget {
  const _ColorSwatchDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ColorSwatchDot> createState() => _ColorSwatchDotState();
}

class _ColorSwatchDotState extends State<_ColorSwatchDot> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    const double size = 30;
    final bool selected = widget.selected;

    final double scale = selected ? 1.12 : (_hovering ? 1.05 : 1.0);
    final Color borderColor = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.outline.withOpacity(0.2);

    Widget dot = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color,
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
          boxShadow: selected || _hovering
              ? [
                  BoxShadow(
                    color: widget.color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: selected
            ? Icon(
                Icons.check,
                size: 16,
                color: widget.color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
              )
            : null,
      ),
    );

    dot = MouseRegion(
      onEnter: (_) {
        if (!_hovering) setState(() => _hovering = true);
      },
      onExit: (_) {
        if (_hovering) setState(() => _hovering = false);
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: dot,
      ),
    );

    return dot;
  }
}
