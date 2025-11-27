import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart' as fs;
import 'package:path/path.dart' as p;
import 'package:vector_math/vector_math_64.dart' as vmath;

import '../models/drawing.dart';
import '../models/whiteboard_document.dart';
import '../models/whiteboard_page.dart';
import '../utils/whiteboard_exporter.dart';
import 'package:uuid/uuid.dart';

import 'storage/local_document_store.dart';

class RealtimeWhiteboardService extends ChangeNotifier {
	RealtimeWhiteboardService() {
		_initializeEmptyDocument();
		Future.microtask(() async {
			await refreshRecentDocuments();
		});
	}

	// Drawing state
	final Map<String, List<DrawElement>> _pageElements = <String, List<DrawElement>>{};
	final Map<String, List<DrawElement>> _pageUndoStacks = <String, List<DrawElement>>{};
	final Map<String, double> _pageScales = <String, double>{};
	final Map<String, Offset> _pagePanOffsets = <String, Offset>{};
	final List<WhiteboardPage> _pages = <WhiteboardPage>[];

	List<DrawElement> _elements = <DrawElement>[];
	List<DrawElement> _undoStack = <DrawElement>[];
	DrawElement? _activeDraftElement;
	PathElement? _previewPath;
	Offset? _dragStart;
	String? _activePageId;

	// Tool configuration
	Color _currentColor = Colors.black;
	double _currentStrokeWidth = 3.0;
	double _currentFontSize = 16.0;
	DrawingToolType _currentTool = DrawingToolType.pen;
	DrawElement? _selectedElement;

	// Document persistence
	final LocalDocumentStore _documentStore = createDocumentStore();
	WhiteboardDocument? _currentDocument;
	final List<WhiteboardDocumentSummary> _recentDocuments = <WhiteboardDocumentSummary>[];
	bool _hasUnsavedChanges = false;

	// Metadata
	Offset? _lineStart;
	Offset? _rectStart;
	Offset? _circleCenter;
	Offset? _triangleStart;
	Offset? _arrowStart;

	// Getters
	List<DrawElement> get elements {
		final List<DrawElement> output = List<DrawElement>.from(_elements);
		if (_previewPath != null) output.add(_previewPath!);
		if (_activeDraftElement != null) output.add(_activeDraftElement!);
		return List.unmodifiable(output);
	}

	List<WhiteboardPage> get pages => List.unmodifiable(_pages);
		WhiteboardPage? get activePage {
			if (_activePageId == null) return null;
			for (final page in _pages) {
				if (page.id == _activePageId) {
					return page;
				}
			}
			return null;
		}
	String? get activePageId => _activePageId;
	Color get currentPageBackgroundColor => _activePageId == null
			? Colors.white
			: backgroundColorForPage(_activePageId!);

	Color backgroundColorForPage(String pageId) {
		for (final page in _pages) {
			if (page.id == pageId) {
				return page.backgroundColor;
			}
		}
		return Colors.white;
	}

	Color get currentColor => _currentColor;
	double get currentStrokeWidth => _currentStrokeWidth;
	double get currentFontSize => _currentFontSize;
	DrawingToolType get currentTool => _currentTool;
	DrawElement? get selectedElement => _selectedElement;

	WhiteboardDocument? get currentDocument => _currentDocument;
	bool get hasUnsavedChanges => _hasUnsavedChanges;
	List<WhiteboardDocumentSummary> get recentDocuments => List.unmodifiable(_recentDocuments);

	double get scale => _pageScales[_ensureActivePage()] ?? 1.0;
	double scaleForPage(String pageId) => _pageScales[pageId] ?? 1.0;
	Offset get panOffset => _pagePanOffsets[_ensureActivePage()] ?? Offset.zero;
	Offset panOffsetForPage(String pageId) => _pagePanOffsets[pageId] ?? Offset.zero;

	// Initialization helpers
	void _initializeEmptyDocument({String? title}) {
		_pages
			..clear()
			..add(WhiteboardPage.blank(index: 0));
		final String pageId = _pages.first.id;
		_pageElements[pageId] = _pages.first.elements;
		_pageUndoStacks[pageId] = <DrawElement>[];
		_pageScales[pageId] = 1.0;
		_pagePanOffsets[pageId] = Offset.zero;
		_activePageId = pageId;
		_elements = _pageElements[pageId]!;
		_undoStack = _pageUndoStacks[pageId]!;
		_selectedElement = null;
		_previewPath = null;
		_activeDraftElement = null;
		_currentDocument = WhiteboardDocument(
			title: title ?? 'Untitled Presentation',
			pages: _clonePages(),
		);
		_hasUnsavedChanges = false;
		notifyListeners();
	}

	String _ensureActivePage() {
		if (_activePageId != null && _pageElements.containsKey(_activePageId)) {
			_elements = _pageElements[_activePageId] ?? _elements;
			_undoStack = _pageUndoStacks[_activePageId] ?? _undoStack;
			return _activePageId!;
		}

		if (_pages.isEmpty) {
			_pages.add(WhiteboardPage.blank(index: 0));
		}
		final String fallbackId = _pages.first.id;
		_pageElements.putIfAbsent(fallbackId, () => _pages.first.elements);
		_pageUndoStacks.putIfAbsent(fallbackId, () => <DrawElement>[]);
		_pageScales.putIfAbsent(fallbackId, () => 1.0);
		_pagePanOffsets.putIfAbsent(fallbackId, () => Offset.zero);
		_elements = _pageElements[fallbackId]!;
		_undoStack = _pageUndoStacks[fallbackId]!;
		_activePageId = fallbackId;
		return fallbackId;
	}

	void _ensurePageStructures(String pageId) {
		_pageElements.putIfAbsent(pageId, () => <DrawElement>[]);
		_pageUndoStacks.putIfAbsent(pageId, () => <DrawElement>[]);
		_pageScales.putIfAbsent(pageId, () => 1.0);
		_pagePanOffsets.putIfAbsent(pageId, () => Offset.zero);
	}

	List<WhiteboardPage> _clonePages() {
		return _pages
				.map(
					(page) => WhiteboardPage.fromJson(page.toJson()),
				)
				.toList();
	}

	void _markDirty({bool notify = true}) {
		_hasUnsavedChanges = true;
		if (notify) notifyListeners();
	}

	// Persistence operations
	Future<void> refreshRecentDocuments() async {
		final docs = await _documentStore.listDocuments(limit: 20);
		_recentDocuments
			..clear()
			..addAll(docs);
		notifyListeners();
	}

	Future<void> createNewDocument({String? title}) async {
		_initializeEmptyDocument(title: title);
		await refreshRecentDocuments();
	}

	Future<void> loadDocument(String documentId) async {
		final WhiteboardDocument? document = await _documentStore.loadDocument(documentId);
		if (document == null) {
			return;
		}

		_applyDocumentSnapshot(document);
		await refreshRecentDocuments();
	}

	void _applyDocumentSnapshot(WhiteboardDocument document) {
		_currentDocument = document;
		_pages
			..clear()
			..addAll(document.pages.map((page) => WhiteboardPage.fromJson(page.toJson())));
		_pageElements.clear();
		_pageUndoStacks.clear();
		_pageScales.clear();
		_pagePanOffsets.clear();

		for (final page in _pages) {
			_pageElements[page.id] = page.elements;
			_pageUndoStacks[page.id] = <DrawElement>[];
			_pageScales[page.id] = 1.0;
			_pagePanOffsets[page.id] = Offset.zero;
		}

		_activePageId = _pages.isNotEmpty ? _pages.first.id : null;
		_elements = _activePageId != null ? _pageElements[_activePageId!] ?? <DrawElement>[] : <DrawElement>[];
		_undoStack = _activePageId != null ? _pageUndoStacks[_activePageId!] ?? <DrawElement>[] : <DrawElement>[];
		_hasUnsavedChanges = false;
		notifyListeners();
	}

	Future<void> saveDocument({String? title}) async {
		_ensureActivePage();
		final String documentTitle = title?.trim().isNotEmpty == true
				? title!.trim()
				: (_currentDocument?.title ?? 'Untitled Presentation');

		final WhiteboardDocument snapshot = WhiteboardDocument(
			id: _currentDocument?.id,
			title: documentTitle,
			pages: _clonePages(),
			createdAt: _currentDocument?.createdAt,
			updatedAt: DateTime.now(),
		);

		await _documentStore.saveDocument(snapshot);
		_currentDocument = snapshot;
		_hasUnsavedChanges = false;
		await refreshRecentDocuments();
	}

	Future<void> renameCurrentDocument(String newTitle) async {
		if (_currentDocument == null) return;
		final String trimmed = newTitle.trim();
		if (trimmed.isEmpty) return;

		_currentDocument = _currentDocument!.copyWith(title: trimmed, updatedAt: DateTime.now());
		await _documentStore.saveDocument(
			WhiteboardDocument(
				id: _currentDocument!.id,
				title: _currentDocument!.title,
				pages: _clonePages(),
				createdAt: _currentDocument!.createdAt,
				updatedAt: _currentDocument!.updatedAt,
			),
		);
		_hasUnsavedChanges = false;
		await refreshRecentDocuments();
		notifyListeners();
	}

	Future<void> deleteDocument(String documentId) async {
		await _documentStore.deleteDocument(documentId);
		if (_currentDocument?.id == documentId) {
			_initializeEmptyDocument();
		}
		await refreshRecentDocuments();
	}

	Future<String> exportCurrentDocumentAsJson() async {
		final WhiteboardDocument snapshot = WhiteboardDocument(
			id: _currentDocument?.id,
			title: _currentDocument?.title ?? 'Untitled Presentation',
			pages: _clonePages(),
			createdAt: _currentDocument?.createdAt,
			updatedAt: DateTime.now(),
		);
		return const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
	}

	Future<bool> saveDocumentToFile() async {
		_ensureActivePage();
		final WhiteboardDocument snapshot = WhiteboardDocument(
			id: _currentDocument?.id,
			title: _currentDocument?.title ?? 'Untitled Presentation',
			pages: _clonePages(),
			createdAt: _currentDocument?.createdAt,
			updatedAt: DateTime.now(),
		);
		final String jsonPayload = const JsonEncoder.withIndent('  ').convert(snapshot.toJson());
		final String defaultName = _safeFileName(snapshot.title);
		final fs.FileSaveLocation? location = await fs.getSaveLocation(
			suggestedName: '$defaultName.whiteboard.json',
			acceptedTypeGroups: const [
				fs.XTypeGroup(
					label: 'Whiteboard project',
					extensions: <String>['whiteboard', 'json'],
				),
			],
		);
		if (location == null) {
			return false;
		}
		String resolvedPath = location.path;
		if (!resolvedPath.toLowerCase().endsWith('.json')) {
			resolvedPath = '$resolvedPath.json';
		}
		final fs.XFile outputFile = fs.XFile.fromData(
			Uint8List.fromList(utf8.encode(jsonPayload)),
			name: p.basename(resolvedPath),
			mimeType: 'application/json',
		);
		await outputFile.saveTo(resolvedPath);
		return true;
	}

	Future<bool> exportDocumentAsPdf() async {
		final List<WhiteboardPage> pagesSnapshot = _clonePages();
		final String title = _currentDocument?.title ?? 'Untitled Presentation';
		final WhiteboardExporter exporter = WhiteboardExporter(
			documentTitle: title,
			sanitizedFileName: _safeFileName(title),
		);
		final List<RenderedWhiteboardPage> rendered = await exporter.renderPages(pagesSnapshot);
		return exporter.exportAsPdf(rendered);
	}

	Future<bool> exportDocumentAsPptx() async {
		final List<WhiteboardPage> pagesSnapshot = _clonePages();
		final String title = _currentDocument?.title ?? 'Untitled Presentation';
		final WhiteboardExporter exporter = WhiteboardExporter(
			documentTitle: title,
			sanitizedFileName: _safeFileName(title),
		);
		final List<RenderedWhiteboardPage> rendered = await exporter.renderPages(pagesSnapshot);
		return exporter.exportAsPptx(rendered);
	}

	Future<bool> loadDocumentFromFile() async {
		final fs.XFile? selected = await fs.openFile(
			acceptedTypeGroups: const [
				fs.XTypeGroup(
					label: 'Whiteboard project',
					extensions: <String>['whiteboard', 'json'],
				),
			],
		);
		if (selected == null) {
			return false;
		}
		final String raw = await selected.readAsString();
		final dynamic decoded = jsonDecode(raw);
		if (decoded is! Map<String, dynamic>) {
			return false;
		}
		final WhiteboardDocument document = WhiteboardDocument.fromJson(decoded);
		_applyDocumentSnapshot(document);
		await refreshRecentDocuments();
		return true;
	}

	String _safeFileName(String input) {
		final String sanitized = input.trim().isEmpty ? 'presentation' : input.trim();
		return sanitized.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_').toLowerCase();
	}

	// Page management
	void setActivePage(String pageId) {
		if (!_pageElements.containsKey(pageId)) {
			return;
		}
		_activePageId = pageId;
		_elements = _pageElements[pageId]!;
		_undoStack = _pageUndoStacks[pageId]!;
		_selectedElement = null;
		_previewPath = null;
		_activeDraftElement = null;
		notifyListeners();
	}

	WhiteboardPage createPage({String? name, bool activate = true}) {
		final WhiteboardPage page = WhiteboardPage.blank(index: _pages.length);
		if (name != null && name.trim().isNotEmpty) {
			page.name = name.trim();
		}
		_pages.add(page);
		_pageElements[page.id] = page.elements;
		_pageUndoStacks[page.id] = <DrawElement>[];
		_pageScales[page.id] = 1.0;
		_pagePanOffsets[page.id] = Offset.zero;
		if (activate) {
			setActivePage(page.id);
		} else {
			_markDirty();
		}
		return page;
	}

	WhiteboardPage duplicatePage(String pageId) {
		final int index = _pages.indexWhere((page) => page.id == pageId);
		if (index == -1) {
			return createPage();
		}
		final WhiteboardPage existing = _pages[index];
		final int duplicatesCount = _pages.where((page) => page.name.startsWith(existing.name)).length;
		final WhiteboardPage copy = existing.duplicate(copyIndex: duplicatesCount - 1);

		_pages.insert(index + 1, copy);
		_pageElements[copy.id] = copy.elements;
		_pageUndoStacks[copy.id] = <DrawElement>[];
		_pageScales[copy.id] = _pageScales[pageId] ?? 1.0;
		_pagePanOffsets[copy.id] = _pagePanOffsets[pageId] ?? Offset.zero;
		setActivePage(copy.id);
		_markDirty();
		return copy;
	}

	void renamePage(String pageId, String newName) {
		final int index = _pages.indexWhere((page) => page.id == pageId);
		if (index == -1) return;
		final String trimmed = newName.trim();
		if (trimmed.isEmpty) return;
		final WhiteboardPage page = _pages[index];
		page.name = trimmed;
		page.updatedAt = DateTime.now();
		_markDirty();
	}

	void movePage(int oldIndex, int newIndex) {
		if (oldIndex < 0 || newIndex < 0 || oldIndex >= _pages.length || newIndex >= _pages.length) {
			return;
		}
		final page = _pages.removeAt(oldIndex);
		_pages.insert(newIndex, page);
		_markDirty();
	}

	void deletePage(String pageId) {
		if (_pages.length <= 1) {
			clearPage(pageId);
			return;
		}
		_pages.removeWhere((page) => page.id == pageId);
		_pageElements.remove(pageId);
		_pageUndoStacks.remove(pageId);
		_pageScales.remove(pageId);
		_pagePanOffsets.remove(pageId);
		if (_activePageId == pageId) {
			_activePageId = null;
			_ensureActivePage();
		}
		_markDirty();
	}

	void clearPage(String pageId) {
		_ensurePageStructures(pageId);
		_pageElements[pageId]!.clear();
		_pageUndoStacks[pageId]!.clear();
		if (_activePageId == pageId) {
			_selectedElement = null;
			_previewPath = null;
			_activeDraftElement = null;
		}
		_markDirty();
	}

	void clearAllPages() {
		for (final page in _pages) {
			clearPage(page.id);
		}
		_markDirty();
	}

	void setPageBackgroundColor(String pageId, Color color) {
		for (final page in _pages) {
			if (page.id == pageId) {
				if (page.backgroundColor == color) {
					return;
				}
				page.backgroundColor = color;
				page.updatedAt = DateTime.now();
				_markDirty();
				return;
			}
		}
	}

	// View state
	void updateViewState(String pageId, double scale, Offset pan) {
		_pageScales[pageId] = scale.clamp(0.1, 5.0);
		_pagePanOffsets[pageId] = pan;
		notifyListeners();
	}

	vmath.Matrix4 viewMatrixForPage(String pageId) {
		final double scale = _pageScales[pageId] ?? 1.0;
		final Offset pan = _pagePanOffsets[pageId] ?? Offset.zero;
		return vmath.Matrix4.identity()
			..translate(pan.dx, pan.dy)
			..scale(scale, scale, 1.0);
	}

	// Tool configuration
	void setCurrentTool(DrawingToolType tool) {
		_currentTool = tool;
		if (tool != DrawingToolType.select) {
			_selectedElement = null;
		}
		notifyListeners();
	}

	void setCurrentColor(Color color) {
		_currentColor = color;
		notifyListeners();
	}

	void setCurrentStrokeWidth(double width) {
		_currentStrokeWidth = width.clamp(1.0, 40.0);
		notifyListeners();
	}

	void setCurrentFontSize(double size) {
		_currentFontSize = size.clamp(8.0, 120.0);
		notifyListeners();
	}

	// Element helpers
	void addElement(DrawElement element, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_ensurePageStructures(targetPageId);
		element.pageId = targetPageId;
		_pageElements[targetPageId]!.add(element);
		if (_activePageId == targetPageId) {
			_elements = _pageElements[targetPageId]!;
			_undoStack = _pageUndoStacks[targetPageId]!;
		}
		_pageUndoStacks[targetPageId]!.clear();
		_markDirty();
	}

	void updateElement(DrawElement element) {
		final String pageId = element.pageId.isNotEmpty ? element.pageId : _ensureActivePage();
		_ensurePageStructures(pageId);
		final List<DrawElement> targetElements = _pageElements[pageId]!;
		final int index = targetElements.indexWhere((e) => e.id == element.id);
		if (index != -1) {
			targetElements[index] = element;
			if (_activePageId == pageId) {
				_elements = targetElements;
			}
			_markDirty();
		}
	}

	void deleteElement(String elementId, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_ensurePageStructures(targetPageId);
		final List<DrawElement> targetElements = _pageElements[targetPageId]!;
		final int index = targetElements.indexWhere((e) => e.id == elementId);
		if (index == -1) return;
		final DrawElement removed = targetElements.removeAt(index);
		_pageUndoStacks[targetPageId]!.add(removed);
		if (_activePageId == targetPageId) {
			_elements = targetElements;
			_undoStack = _pageUndoStacks[targetPageId]!;
		}
		_markDirty();
	}

	void selectElement(DrawElement? element) {
		_selectedElement = element;
		for (final pageEntry in _pageElements.entries) {
			for (final element in pageEntry.value) {
				element.isSelected = element == _selectedElement;
			}
		}
		notifyListeners();
	}

	void moveSelectedElement(Offset delta) {
		if (_selectedElement == null) return;
		_selectedElement!.move(delta);
		_markDirty();
	}

	void finalizeElementMove() {
		if (_selectedElement == null) return;
		updateElement(_selectedElement!);
	}

	void undo() {
		final String pageId = _ensureActivePage();
		final List<DrawElement> elements = _pageElements[pageId]!;
		final List<DrawElement> undoStack = _pageUndoStacks[pageId]!;
		if (elements.isEmpty) return;
		undoStack.add(elements.removeLast());
		_markDirty();
	}

	void redo() {
		final String pageId = _ensureActivePage();
		final List<DrawElement> elements = _pageElements[pageId]!;
		final List<DrawElement> undoStack = _pageUndoStacks[pageId]!;
		if (undoStack.isEmpty) return;
		final DrawElement element = undoStack.removeLast();
		element.pageId = pageId;
		elements.add(element);
		_markDirty();
	}

	// Text
	void addText(Offset position, String text) {
		if (text.trim().isEmpty) return;
		final TextElement element = TextElement(
			id: const Uuid().v4(),
			position: position,
			text: text,
			color: _currentColor,
			fontSize: _currentFontSize,
			strokeWidth: _currentStrokeWidth,
		);
		addElement(element);
	}

	// Path drawing
	void addPathPoint(Offset point, List<dynamic> points) {
		points.add(point);
		final String pageId = _ensureActivePage();
		_previewPath = PathElement(
			id: 'preview_${DateTime.now().microsecondsSinceEpoch}',
			points: List<Offset>.from(points.map((dynamic p) => p is Offset ? p : (p as DrawingPoint).offset)),
			color: _currentTool == DrawingToolType.eraser ? Colors.white : _currentColor,
			strokeWidth: _currentTool == DrawingToolType.eraser ? 20.0 : _currentStrokeWidth,
			pageId: pageId,
		);
		notifyListeners();
	}

	void finalizePath(List<dynamic> points) {
		if (points.length < 2) {
			_previewPath = null;
			notifyListeners();
			return;
		}

		final List<Offset> offsets = points.map((dynamic p) => p is Offset ? p : (p as DrawingPoint).offset).toList();
		if (offsets.length < 2) {
			_previewPath = null;
			notifyListeners();
			return;
		}

		final PathElement element = PathElement(
			id: const Uuid().v4(),
			points: offsets,
			color: _currentTool == DrawingToolType.eraser ? Colors.white : _currentColor,
			strokeWidth: _currentTool == DrawingToolType.eraser ? 20.0 : _currentStrokeWidth,
			pageId: _ensureActivePage(),
		);

		_previewPath = null;
		addElement(element);
	}

	// Line drawing
	void beginLine(Offset startPoint, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_lineStart = startPoint;
		_activeDraftElement = LineElement(
			id: 'draft_line_${DateTime.now().microsecondsSinceEpoch}',
			start: startPoint,
			end: startPoint,
			color: _currentColor,
			strokeWidth: _currentStrokeWidth,
			pageId: targetPageId,
		);
		notifyListeners();
	}

	void updateLine(Offset endPoint) {
		final draft = _activeDraftElement;
		if (draft is! LineElement) return;
		draft.end = endPoint;
		notifyListeners();
	}

	void finalizeLine() {
		final draft = _activeDraftElement;
		if (draft is! LineElement) {
			_lineStart = null;
			return;
		}
		if ((draft.end - draft.start).distance < 1.0) {
			_activeDraftElement = null;
			_lineStart = null;
			notifyListeners();
			return;
		}
		final LineElement element = LineElement(
			id: const Uuid().v4(),
			color: draft.color,
			strokeWidth: draft.strokeWidth,
			start: draft.start,
			end: draft.end,
			pageId: draft.pageId,
		);
		_activeDraftElement = null;
		_lineStart = null;
		addElement(element, pageId: element.pageId);
		selectElement(element);
	}

	// Rectangle drawing
	void beginRectangle(Offset startPoint, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_rectStart = startPoint;
		_activeDraftElement = RectangleElement(
			id: 'draft_rectangle_${DateTime.now().microsecondsSinceEpoch}',
			topLeft: startPoint,
			bottomRight: startPoint,
			color: _currentColor,
			strokeWidth: _currentStrokeWidth,
			pageId: targetPageId,
		);
		notifyListeners();
	}

	void updateRectangle(Offset currentPoint) {
		final draft = _activeDraftElement;
		final start = _rectStart;
		if (draft is! RectangleElement || start == null) return;
		final double left = math.min(start.dx, currentPoint.dx);
		final double right = math.max(start.dx, currentPoint.dx);
		final double top = math.min(start.dy, currentPoint.dy);
		final double bottom = math.max(start.dy, currentPoint.dy);
		draft.topLeft = Offset(left, top);
		draft.bottomRight = Offset(right, bottom);
		notifyListeners();
	}

	void finalizeRectangle() {
		final draft = _activeDraftElement;
		if (draft is! RectangleElement) {
			_rectStart = null;
			return;
		}
		final double width = (draft.bottomRight.dx - draft.topLeft.dx).abs();
		final double height = (draft.bottomRight.dy - draft.topLeft.dy).abs();
		if (width < 1.0 || height < 1.0) {
			_activeDraftElement = null;
			_rectStart = null;
			notifyListeners();
			return;
		}
		final RectangleElement element = RectangleElement(
			id: const Uuid().v4(),
			topLeft: draft.topLeft,
			bottomRight: draft.bottomRight,
			color: draft.color,
			strokeWidth: draft.strokeWidth,
			pageId: draft.pageId,
		);
		_activeDraftElement = null;
		_rectStart = null;
		addElement(element, pageId: element.pageId);
		selectElement(element);
	}

	// Circle drawing
	void beginCircle(Offset startPoint, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_circleCenter = startPoint;
		_activeDraftElement = CircleElement(
			id: 'draft_circle_${DateTime.now().microsecondsSinceEpoch}',
			center: startPoint,
			radius: 0,
			color: _currentColor,
			strokeWidth: _currentStrokeWidth,
			pageId: targetPageId,
		);
		notifyListeners();
	}

	void updateCircle(Offset currentPoint) {
		final draft = _activeDraftElement;
		final center = _circleCenter;
		if (draft is! CircleElement || center == null) return;
		draft.radius = (currentPoint - center).distance.abs();
		notifyListeners();
	}

	void finalizeCircle() {
		final draft = _activeDraftElement;
		if (draft is! CircleElement) {
			_circleCenter = null;
			return;
		}
		if (draft.radius < 1.0) {
			_activeDraftElement = null;
			_circleCenter = null;
			notifyListeners();
			return;
		}
		final CircleElement element = CircleElement(
			id: const Uuid().v4(),
			center: draft.center,
			radius: draft.radius,
			color: draft.color,
			strokeWidth: draft.strokeWidth,
			pageId: draft.pageId,
		);
		_activeDraftElement = null;
		_circleCenter = null;
		addElement(element, pageId: element.pageId);
		selectElement(element);
	}

	// Triangle drawing
	void beginTriangle(Offset startPoint, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_triangleStart = startPoint;
		_activeDraftElement = TriangleElement(
			id: 'draft_triangle_${DateTime.now().microsecondsSinceEpoch}',
			p1: startPoint,
			p2: startPoint,
			p3: startPoint,
			color: _currentColor,
			strokeWidth: _currentStrokeWidth,
			pageId: targetPageId,
		);
		notifyListeners();
	}

	void updateTriangle(Offset currentPoint) {
		final draft = _activeDraftElement;
		final start = _triangleStart;
		if (draft is! TriangleElement || start == null) return;
		final double dx = currentPoint.dx - start.dx;
		final double dy = currentPoint.dy - start.dy;
		final double baseHalf = dx.abs();
		draft.p1 = start;
		draft.p2 = Offset(start.dx - baseHalf, start.dy + dy);
		draft.p3 = Offset(start.dx + baseHalf, start.dy + dy);
		notifyListeners();
	}

	void finalizeTriangle() {
		final draft = _activeDraftElement;
		if (draft is! TriangleElement) {
			_triangleStart = null;
			return;
		}
		final double height = (draft.p1.dy - draft.p2.dy).abs();
		final double base = (draft.p3.dx - draft.p2.dx).abs();
		if (height < 1.0 || base < 1.0) {
			_activeDraftElement = null;
			_triangleStart = null;
			notifyListeners();
			return;
		}
		final TriangleElement element = TriangleElement(
			id: const Uuid().v4(),
			p1: draft.p1,
			p2: draft.p2,
			p3: draft.p3,
			color: draft.color,
			strokeWidth: draft.strokeWidth,
			pageId: draft.pageId,
		);
		_activeDraftElement = null;
		_triangleStart = null;
		addElement(element, pageId: element.pageId);
		selectElement(element);
	}

	// Arrow drawing
	void beginArrow(Offset startPoint, {String? pageId}) {
		final String targetPageId = pageId ?? _ensureActivePage();
		_arrowStart = startPoint;
		_activeDraftElement = ArrowElement(
			id: 'draft_arrow_${DateTime.now().microsecondsSinceEpoch}',
			start: startPoint,
			end: startPoint,
			color: _currentColor,
			strokeWidth: _currentStrokeWidth,
			pageId: targetPageId,
		);
		notifyListeners();
	}

	void updateArrow(Offset currentPoint) {
		final draft = _activeDraftElement;
		if (draft is! ArrowElement) return;
		draft.end = currentPoint;
		notifyListeners();
	}

	void finalizeArrow() {
		final draft = _activeDraftElement;
		if (draft is! ArrowElement) {
			_arrowStart = null;
			return;
		}
		if ((draft.end - draft.start).distance < 1.0) {
			_activeDraftElement = null;
			_arrowStart = null;
			notifyListeners();
			return;
		}
		final ArrowElement element = ArrowElement(
			id: const Uuid().v4(),
			start: draft.start,
			end: draft.end,
			color: draft.color,
			strokeWidth: draft.strokeWidth,
			pageId: draft.pageId,
		);
		_activeDraftElement = null;
		_arrowStart = null;
		addElement(element, pageId: element.pageId);
		selectElement(element);
	}

	// Selection helpers
	void selectElementAt(Offset position) {
		final String pageId = _ensureActivePage();
		final List<DrawElement> elements = _pageElements[pageId]!;
		DrawElement? hit;
		for (int i = elements.length - 1; i >= 0; i--) {
			if (elements[i].contains(position)) {
				hit = elements[i];
				break;
			}
		}
		selectElement(hit);
	}

	void clearSelection() {
		selectElement(null);
	}

	void clearBoard() {
		clearPage(_ensureActivePage());
	}

	// Utility
	void disposeDrafts() {
		_activeDraftElement = null;
		_previewPath = null;
		notifyListeners();
	}
}

