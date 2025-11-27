import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/whiteboard_document.dart';
import '../services/realtime_whiteboard_service.dart';
import '../utils/theme_controller.dart';
import 'whiteboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  DashboardNavSection _activeSection = DashboardNavSection.dashboard;
  DocumentSort _sort = DocumentSort.newest;
  bool _isGridView = true;
  bool _isHoveringHeaderAction = false;
  DashboardNavSection? _hoveredSection;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => context.read<RealtimeWhiteboardService>().refreshRecentDocuments(),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createNewDocument(BuildContext context) async {
    final service = context.read<RealtimeWhiteboardService>();
    final navigator = Navigator.of(context);

    String tempTitle = '';
    final bool shouldCreate = await showDialog<bool?>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Create Presentation'),
            content: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Untitled Presentation',
              ),
              onChanged: (value) => tempTitle = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Create'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldCreate) return;

    await service.createNewDocument(
      title: tempTitle.trim().isEmpty ? null : tempTitle.trim(),
    );
    if (!mounted) return;

    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const WhiteboardScreen()),
    );
    if (!mounted) return;

    await service.refreshRecentDocuments();
  }

  Future<void> _openDocument(
    BuildContext context,
    WhiteboardDocumentSummary summary,
  ) async {
    final service = context.read<RealtimeWhiteboardService>();
    final navigator = Navigator.of(context);

    await service.loadDocument(summary.id);
    if (!mounted) return;

    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const WhiteboardScreen()),
    );
    if (!mounted) return;

    await service.refreshRecentDocuments();
  }

  Future<void> _openFromFile(BuildContext context) async {
    final service = context.read<RealtimeWhiteboardService>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final bool loaded = await service.loadDocumentFromFile();
    if (!mounted) return;

    if (!loaded) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Import cancelled or invalid file.')),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const WhiteboardScreen()),
    );
    if (!mounted) return;

    await service.refreshRecentDocuments();
  }

  Future<void> _renameDocument(
    BuildContext context,
    WhiteboardDocumentSummary summary,
  ) async {
    String newTitle = summary.title;

    final bool confirmed = await showDialog<bool?>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Rename Presentation'),
            content: TextField(
              controller: TextEditingController(text: summary.title),
              autofocus: true,
              onChanged: (value) => newTitle = value,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Rename'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final service = context.read<RealtimeWhiteboardService>();
    await service.loadDocument(summary.id);
    await service.renameCurrentDocument(
      newTitle.trim().isEmpty ? summary.title : newTitle.trim(),
    );
    await service.refreshRecentDocuments();
  }

  Future<void> _deleteDocument(
    BuildContext context,
    WhiteboardDocumentSummary summary,
  ) async {
    final bool confirmed = await showDialog<bool?>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete Presentation'),
            content: Text('Are you sure you want to delete "${summary.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    await context.read<RealtimeWhiteboardService>().deleteDocument(summary.id);
    await context.read<RealtimeWhiteboardService>().refreshRecentDocuments();
  }

  Future<void> _exportDocument(
    BuildContext context,
    WhiteboardDocumentSummary summary,
    ExportTarget target,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<RealtimeWhiteboardService>();

    await service.loadDocument(summary.id);
    bool success = false;

    switch (target) {
      case ExportTarget.json:
        success = await service.saveDocumentToFile();
        break;
      case ExportTarget.pdf:
        success = await service.exportDocumentAsPdf();
        break;
      case ExportTarget.pptx:
        success = await service.exportDocumentAsPptx();
        break;
    }

    if (!mounted) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Exported "${summary.title}" as ${target.label}.'
              : 'Failed to export "${summary.title}" as ${target.label}.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _DashboardPalette.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: palette.canvas,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: _showsDocumentActions
          ? FloatingActionButton.extended(
              onPressed: () => _createNewDocument(context),
              backgroundColor: palette.accent,
              foregroundColor: palette.onAccent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Presentation'),
            )
          : null,
      drawer: _isCompactLayout(context)
          ? _buildSidebar(palette, isDrawer: true)
          : null,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(palette),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_isCompactLayout(context))
                    _buildSidebar(palette),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.body,
                        borderRadius:
                            const BorderRadius.only(topLeft: Radius.circular(24)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      child: Consumer<RealtimeWhiteboardService>(
                        builder: (context, service, _) {
                          final documents =
                              _filterDocuments(service.recentDocuments);
                          final stats =
                              _computeDashboardStats(service.recentDocuments);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildContentHeader(
                                palette,
                                documents.isNotEmpty,
                              ),
                              if (documents.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                _buildInsightsRow(stats, palette),
                                const SizedBox(height: 18),
                                _buildFilterToolbar(palette),
                                const SizedBox(height: 16),
                              ] else
                                const SizedBox(height: 24),
                              Expanded(
                                child: _buildContentSwitch(
                                  documents: documents,
                                  palette: palette,
                                  service: service,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCompactLayout(BuildContext context) =>
      MediaQuery.of(context).size.width < 960;

  bool get _showsDocumentActions =>
    _activeSection == DashboardNavSection.dashboard ||
    _activeSection == DashboardNavSection.recent;

  List<WhiteboardDocumentSummary> _filterDocuments(
    List<WhiteboardDocumentSummary> docs,
  ) {
    Iterable<WhiteboardDocumentSummary> working = docs;
    final query = _searchController.text.trim();
    final now = DateTime.now();

    if (query.isNotEmpty) {
      working = working.where(
        (doc) => doc.title.toLowerCase().contains(query.toLowerCase()),
      );
    }

    List<WhiteboardDocumentSummary> sorted;

    if (_activeSection == DashboardNavSection.recent) {
      sorted = working
          .where((doc) => now.difference(doc.updatedAt).inDays <= 14)
          .take(12)
          .toList();
    } else if (_activeSection == DashboardNavSection.dashboard) {
      final recentIds = docs
          .where((doc) => now.difference(doc.updatedAt).inDays <= 14)
          .map((doc) => doc.id)
          .toSet();
      sorted = working
          .where((doc) => !recentIds.contains(doc.id))
          .toList();

      if (sorted.isEmpty && docs.isNotEmpty) {
        sorted = working.toList();
      }
    } else {
      sorted = working.toList();
    }

    sorted.sort((a, b) {
      switch (_sort) {
        case DocumentSort.newest:
          return b.updatedAt.compareTo(a.updatedAt);
        case DocumentSort.oldest:
          return a.updatedAt.compareTo(b.updatedAt);
        case DocumentSort.nameAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case DocumentSort.nameDesc:
          return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
    return sorted;
  }

  _DashboardStats _computeDashboardStats(List<WhiteboardDocumentSummary> docs) {
    if (docs.isEmpty) {
      return const _DashboardStats();
    }

    final now = DateTime.now();
    final updatedThisWeek = docs.where(
      (d) => now.difference(d.updatedAt).inDays <= 7,
    );
    final lastTouched = docs.reduce(
      (a, b) => a.updatedAt.isAfter(b.updatedAt) ? a : b,
    );

    final totalPages = docs.fold<int>(0, (sum, d) => sum + d.pageCount);

    return _DashboardStats(
      totalDocs: docs.length,
      totalPages: totalPages,
      updatedThisWeek: updatedThisWeek.length,
      lastUpdated: lastTouched.updatedAt,
    );
  }

  Widget _buildInsightsRow(_DashboardStats stats, _DashboardPalette palette) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        final spacing = isNarrow ? 16.0 : 20.0;
        final children = [
          _InsightCard(
            title: 'Total presentations',
            value: stats.totalDocs.toString(),
            subtitle: stats.totalDocs == 1
                ? 'One workspace ready to present'
                : '${stats.totalDocs} decks at your fingertips',
            icon: Icons.dashboard_customize_rounded,
            accent: palette.accent,
            palette: palette,
          ),
          _InsightCard(
            title: 'Pages across decks',
            value: stats.totalPages.toString(),
            subtitle: 'Slides and canvases across all boards',
            icon: Icons.layers_rounded,
            accent: const Color(0xFFEC4899),
            palette: palette,
          ),
          _InsightCard(
            title: 'Updated this week',
            value: stats.updatedThisWeek.toString(),
            subtitle: stats.updatedThisWeek == 0
                ? 'Nothing new yet—time to create'
                : 'Fresh ideas captured in the last 7 days',
            icon: Icons.auto_graph_rounded,
            accent: const Color(0xFF22D3EE),
            palette: palette,
          ),
          _InsightCard(
            title: 'Last activity',
            value: stats.lastUpdatedLabel,
            subtitle: 'Keep momentum going with your team',
            icon: Icons.schedule_rounded,
            accent: const Color(0xFFF97316),
            palette: palette,
          ),
        ];

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (card) => SizedBox(
                  width: isNarrow
                      ? constraints.maxWidth
                      : (constraints.maxWidth - spacing * 3) / 4,
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildFilterToolbar(_DashboardPalette palette) {
    final filters = [
      _QuickFilter(
        label: 'All decks',
        icon: Icons.apps_rounded,
        selected: true,
        palette: palette,
      ),
      _QuickFilter(
        label: 'Shared with me',
        icon: Icons.group_outlined,
        palette: palette,
      ),
      _QuickFilter(
        label: 'Starred',
        icon: Icons.star_outline_rounded,
        palette: palette,
      ),
      _QuickFilter(
        label: 'Workshops',
        icon: Icons.record_voice_over_outlined,
        palette: palette,
      ),
      _QuickFilter(
        label: 'Archived',
        icon: Icons.inventory_2_outlined,
        palette: palette,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: filter,
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(_DashboardPalette palette) {
    final accent = palette.accent;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: palette.topBar,
        border: Border(
          bottom: BorderSide(color: palette.topBarBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: palette.topBarShadow,
            offset: const Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          if (_isCompactLayout(context))
            IconButton(
              icon: Icon(Icons.menu_rounded, color: palette.navInactiveIcon),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(
                'Collaborative Whiteboard',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 520),
              child: _buildSearchField(palette),
            ),
          ),
          const SizedBox(width: 24),
          MouseRegion(
            onEnter: (_) => setState(() => _isHoveringHeaderAction = true),
            onExit: (_) => setState(() => _isHoveringHeaderAction = false),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: palette.onAccent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isHoveringHeaderAction ? 8 : 2,
              ),
              onPressed: () => _createNewDocument(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('New Presentation'),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Open from file',
            icon: Icon(Icons.folder_open_outlined, color: palette.iconMuted),
            onPressed: () => _openFromFile(context),
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: palette.card,
            ),
            child: IconButton(
              tooltip: 'Account',
              icon: Icon(Icons.person_outline_rounded, color: palette.iconMuted),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(_DashboardPalette palette) {
    final suffix =
        _searchController.text.isEmpty ? '' : '  (press Enter to refine)';

    return TextField(
      controller: _searchController,
      style: GoogleFonts.inter(color: palette.textPrimary, fontSize: 14),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.filterBg,
        prefixIcon: Icon(Icons.search, color: palette.iconMuted),
        hintText: 'Search presentations...$suffix',
        hintStyle: TextStyle(color: palette.filterInactiveText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.filterBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.filterBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 0),
      ),
    );
  }

  Widget _buildSidebar(_DashboardPalette palette, {bool isDrawer = false}) {
    final tiles = [
      _navItem(
        DashboardNavSection.dashboard,
        Icons.dashboard_customize_rounded,
        'My Presentations',
        palette,
      ),
      _navItem(
        DashboardNavSection.recent,
        Icons.schedule_rounded,
        'Recent',
        palette,
      ),
      _navItem(
        DashboardNavSection.trash,
        Icons.delete_outline,
        'Trash',
        palette,
      ),
      _navItem(
        DashboardNavSection.settings,
        Icons.settings_outlined,
        'Settings',
        palette,
      ),
    ];

    final sidebar = Container(
      width: isDrawer ? double.infinity : 280,
      decoration: BoxDecoration(
        color: palette.sidebar,
        border: isDrawer
            ? null
            : Border(
                right: BorderSide(color: palette.sidebarBorder, width: 1),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Workspace',
              style: GoogleFonts.inter(
                color: palette.textSecondary,
                fontSize: 12,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemBuilder: (_, index) => tiles[index],
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemCount: tiles.length,
            ),
          ),
        ],
      ),
    );

    if (isDrawer) {
      return Drawer(child: SafeArea(child: sidebar));
    }

    return sidebar;
  }

  Widget _navItem(
    DashboardNavSection section,
    IconData icon,
    String label,
    _DashboardPalette palette,
  ) {
    final bool isActive = _activeSection == section;
    final bool isHovered = _hoveredSection == section;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredSection = section),
      onExit: (_) => setState(() => _hoveredSection = null),
      child: InkWell(
        onTap: () {
          if (_activeSection == section) return;
          setState(() => _activeSection = section);
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: isActive
                ? palette.navActiveBg
                : (isHovered ? palette.navHoverBg : Colors.transparent),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive ? palette.navActiveBorder : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive
                      ? palette.accent
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                icon,
                color: isActive
                    ? palette.navActiveText
                    : (isHovered ? palette.textPrimary : palette.navInactiveIcon),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? palette.navActiveText
                        : (isHovered ? palette.textPrimary : palette.navInactiveText),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentHeader(_DashboardPalette palette, bool hasDocuments) {
    final String title;
    final String subtitle;

    switch (_activeSection) {
      case DashboardNavSection.dashboard:
        title = 'My Presentations';
        subtitle = hasDocuments
            ? 'Organize, collaborate, and present from a single workspace.'
            : 'Start by creating your first presentation to unlock your workspace.';
        break;
      case DashboardNavSection.recent:
        title = 'Recently Opened';
        subtitle =
            'Quick access to presentations you worked on in the last few days.';
        break;
      case DashboardNavSection.trash:
        title = 'Trash';
        subtitle = 'Restore or permanently delete presentations removed in the last 30 days.';
        break;
      case DashboardNavSection.settings:
        title = 'Workspace Settings';
        subtitle = 'Configure your preferences, integrations, and account details.';
        break;
    }

  final bool canToggleLayout =
    _activeSection == DashboardNavSection.dashboard ||
    _activeSection == DashboardNavSection.recent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (canToggleLayout)
              Row(
                children: [
                  _toggleButton(
                    label: 'Grid',
                    icon: Icons.grid_view_rounded,
                    selected: _isGridView,
                    onTap: () => setState(() => _isGridView = true),
                    palette: palette,
                  ),
                  const SizedBox(width: 8),
                  _toggleButton(
                    label: 'List',
                    icon: Icons.view_agenda_outlined,
                    selected: !_isGridView,
                    onTap: () => setState(() => _isGridView = false),
                    palette: palette,
                  ),
                  const SizedBox(width: 16),
                  PopupMenuButton<DocumentSort>(
                    onSelected: (value) => setState(() => _sort = value),
                    color: palette.popupBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: DocumentSort.newest,
                        child: Text('Sort by newest'),
                      ),
                      PopupMenuItem(
                        value: DocumentSort.oldest,
                        child: Text('Sort by oldest'),
                      ),
                      PopupMenuItem(
                        value: DocumentSort.nameAsc,
                        child: Text('Sort A → Z'),
                      ),
                      PopupMenuItem(
                        value: DocumentSort.nameDesc,
                        child: Text('Sort Z → A'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: palette.popupBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: palette.filterBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swap_vert, size: 18, color: palette.iconMuted),
                          const SizedBox(width: 8),
                          Text(
                            _sort.label,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _toggleButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required _DashboardPalette palette,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? palette.filterActiveBg : palette.filterBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? palette.filterActiveBorder : palette.filterBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? palette.filterActiveText : palette.iconMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: selected ? palette.filterActiveText : palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _gridCrossAxisCount(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final int count = width ~/ 280;
    return math.max(1, count);
  }

  Widget _buildContentSwitch({
    required List<WhiteboardDocumentSummary> documents,
    required _DashboardPalette palette,
    required RealtimeWhiteboardService service,
  }) {
    switch (_activeSection) {
      case DashboardNavSection.dashboard:
      case DashboardNavSection.recent:
        return _buildDocumentCollection(
          documents: documents,
          palette: palette,
          service: service,
        );
      case DashboardNavSection.trash:
        return _buildTrashSection(palette);
      case DashboardNavSection.settings:
        return _buildSettingsSection(palette);
    }
  }

  Widget _buildDocumentCollection({
    required List<WhiteboardDocumentSummary> documents,
    required _DashboardPalette palette,
    required RealtimeWhiteboardService service,
  }) {
    if (documents.isEmpty) {
      return _buildEmptyState(palette);
    }

    return RefreshIndicator(
      onRefresh: service.refreshRecentDocuments,
      child: Scrollbar(
        radius: const Radius.circular(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _isGridView
              ? GridView.builder(
                  key: const ValueKey('grid-view'),
                  padding: const EdgeInsets.only(bottom: 24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridCrossAxisCount(context),
                    childAspectRatio: 1.25,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) => _PresentationCard(
                    document: documents[index],
                    palette: palette,
                    onOpen: () => _openDocument(context, documents[index]),
                    onRename: () => _renameDocument(context, documents[index]),
                    onDelete: () => _deleteDocument(context, documents[index]),
                    onExport: (target) =>
                        _exportDocument(context, documents[index], target),
                  ),
                )
              : ListView.separated(
                  key: const ValueKey('list-view'),
                  padding: const EdgeInsets.only(bottom: 24, top: 4),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) => _PresentationListTile(
                    document: documents[index],
                    palette: palette,
                    onOpen: () => _openDocument(context, documents[index]),
                    onRename: () => _renameDocument(context, documents[index]),
                    onDelete: () => _deleteDocument(context, documents[index]),
                    onExport: (target) =>
                        _exportDocument(context, documents[index], target),
                  ),
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: documents.length,
                ),
        ),
      ),
    );
  }

  Widget _buildTrashSection(_DashboardPalette palette) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: palette.emptyCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.emptyBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: palette.filterBg,
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 32,
                  color: palette.iconMuted,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your trash is empty',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Deleted presentations will live here for 30 days before being permanently removed.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.outlineButtonForeground,
                  side: BorderSide(color: palette.outlineButtonBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                icon: const Icon(Icons.help_outline_rounded),
                label: const Text('Learn more'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _InfoCard(
          icon: Icons.shield_outlined,
          title: 'Retention policy',
          subtitle: 'Keep work safe while giving collaborators time to recover mistakes.',
          body:
              'Items remain recoverable for 30 days. Afterwards, they are permanently deleted from the workspace archive.',
          palette: palette,
        ),
      ],
    );
  }

  Widget _buildSettingsSection(_DashboardPalette palette) {
    final themeController = context.watch<ThemeController>();
    return ListView(
      padding: const EdgeInsets.only(bottom: 48),
      children: [
        Text(
          'Appearance',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ToggleButtons(
                isSelected: [
                  themeController.mode == ThemeMode.light,
                  themeController.mode == ThemeMode.dark,
                ],
                onPressed: (index) {
                  final mode = index == 0 ? ThemeMode.light : ThemeMode.dark;
                  themeController.setMode(mode);
                },
                borderRadius: BorderRadius.circular(12),
                borderColor: palette.filterBorder,
                selectedBorderColor: palette.accent,
                fillColor: palette.filterActiveBg,
                selectedColor: palette.filterActiveText,
                color: palette.filterInactiveText,
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('Light'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text('Dark'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          activeColor: palette.accent,
          title: Text(
            'Session reminders',
            style: TextStyle(color: palette.textPrimary),
          ),
          subtitle: Text(
            'Get a heads-up before scheduled workshops begin.',
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
        SwitchListTile(
          value: false,
          onChanged: (_) {},
          activeColor: palette.accent,
          title: Text(
            'Product updates',
            style: TextStyle(color: palette.textPrimary),
          ),
          subtitle: Text(
            'Be first to know about new templates and features.',
            style: TextStyle(color: palette.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(_DashboardPalette palette) {
    final accent = palette.accent;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 360,
            height: 220,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: palette.emptyCard,
              border: Border.all(color: palette.emptyBorder),
              boxShadow: [
                BoxShadow(
                  color: palette.topBarShadow.withOpacity(0.35),
                  blurRadius: 28,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [accent.withOpacity(0.28), accent.withOpacity(0.08)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 36,
                  left: 42,
                  right: 42,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: palette.onAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                Positioned(
                  top: 104,
                  left: 42,
                  right: 160,
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: palette.onAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                Positioned(
                  top: 104,
                  right: 42,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: accent.withOpacity(0.3),
                    ),
                    child: Icon(Icons.auto_awesome, color: palette.onAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Design your first collaborative board',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 420,
            child: Text(
              'Kick things off with a blank canvas or import an existing deck. Invite teammates to annotate, co-create, and present in real time.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: palette.textSecondary,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: palette.onAccent,
                  fixedSize: const Size(260, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () => _createNewDocument(context),
                child: const Text('Create your first presentation'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: palette.textPrimary,
                  side: BorderSide(color: palette.outlineButtonBorder),
                  fixedSize: const Size(180, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                onPressed: () => _openFromFile(context),
                child: const Text('Import a board'),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _PresentationCard extends StatelessWidget {
  const _PresentationCard({
    required this.document,
    required this.palette,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onExport,
  });

  final WhiteboardDocumentSummary document;
  final _DashboardPalette palette;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<ExportTarget> onExport;

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('MMM d, yyyy • h:mm a');
    final accent = palette.accent;

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.cardBorder),
          boxShadow: [
            BoxShadow(
              color: palette.topBarShadow.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withOpacity(0.8),
                        palette.card,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 18,
                        right: 18,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: palette.onAccent.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 36,
                        left: 18,
                        right: 60,
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: palette.onAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 28,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: palette.onAccent.withOpacity(0.14),
                          ),
                          child: const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 22,
                        bottom: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${document.pageCount} pages',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: palette.onAccent.withOpacity(0.85),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              document.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Updated ${fmt.format(document.updatedAt)}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: accent.withOpacity(0.16),
                    foregroundColor: palette.onAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: onOpen,
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('Open'),
                ),
                const Spacer(),
                _MenuButton(
                  palette: palette,
                  onRename: onRename,
                  onDelete: onDelete,
                  onExport: onExport,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.palette,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final _DashboardPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.statsCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.statsBorder),
        boxShadow: [
          BoxShadow(
            color: palette.topBarShadow.withOpacity(0.15),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.5,
              color: palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickFilter extends StatelessWidget {
  const _QuickFilter({
    required this.label,
    required this.icon,
    this.selected = false,
    required this.palette,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final _DashboardPalette palette;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? palette.filterActiveBg : palette.filterBg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color:
              selected ? palette.filterActiveBorder : palette.filterBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color:
                selected ? palette.filterActiveText : palette.filterInactiveText,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected
                  ? palette.filterActiveText
                  : palette.filterInactiveText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresentationListTile extends StatelessWidget {
  const _PresentationListTile({
    required this.document,
    required this.palette,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
    required this.onExport,
  });

  final WhiteboardDocumentSummary document;
  final _DashboardPalette palette;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<ExportTarget> onExport;

  @override
  Widget build(BuildContext context) {
    final DateFormat fmt = DateFormat('MMM d, yyyy – h:mm a');
    final accent = palette.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: palette.listTileBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.listTileBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [accent.withOpacity(0.7), palette.card],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.slideshow_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 14,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${document.pageCount} pages',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 180,
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: palette.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fmt.format(document.updatedAt),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: palette.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: accent.withOpacity(0.16),
              foregroundColor: palette.onAccent,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onOpen,
            child: const Text('Open'),
          ),
          const SizedBox(width: 12),
          _MenuButton(
            palette: palette,
            onRename: onRename,
            onDelete: onDelete,
            onExport: onExport,
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.palette,
    required this.onRename,
    required this.onDelete,
    required this.onExport,
  });

  final _DashboardPalette palette;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<ExportTarget> onExport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: palette.iconMuted),
      color: palette.popupBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        switch (value) {
          case 'rename':
            onRename();
            break;
          case 'export-json':
            onExport(ExportTarget.json);
            break;
          case 'export-pdf':
            onExport(ExportTarget.pdf);
            break;
          case 'export-pptx':
            onExport(ExportTarget.pptx);
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rename',
          child: Text('Rename', style: TextStyle(color: palette.textPrimary)),
        ),
        PopupMenuItem(
          value: 'export-json',
          child: Text('Export as JSON', style: TextStyle(color: palette.textPrimary)),
        ),
        PopupMenuItem(
          value: 'export-pdf',
          child: Text('Export as PDF', style: TextStyle(color: palette.textPrimary)),
        ),
        PopupMenuItem(
          value: 'export-pptx',
          child: Text('Export as PPTX', style: TextStyle(color: palette.textPrimary)),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Delete',
            style: TextStyle(color: Colors.redAccent.shade200),
          ),
        ),
      ],
    );
  }
}

class _DashboardStats {
  const _DashboardStats({
    this.totalDocs = 0,
    this.totalPages = 0,
    this.updatedThisWeek = 0,
    this.lastUpdated,
  });

  final int totalDocs;
  final int totalPages;
  final int updatedThisWeek;
  final DateTime? lastUpdated;

  String get lastUpdatedLabel {
    if (lastUpdated == null) return '—';
    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(lastUpdated!);
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.palette,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final _DashboardPalette palette;

  @override
  Widget build(BuildContext context) {
    final accent = palette.accent;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [accent, accent.withOpacity(0.6)],
              ),
            ),
            child: Icon(icon, color: Colors.white70),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.7,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum DashboardNavSection { dashboard, recent, trash, settings }

enum DocumentSort { newest, oldest, nameAsc, nameDesc }

extension on DocumentSort {
  String get label {
    switch (this) {
      case DocumentSort.newest:
        return 'Newest';
      case DocumentSort.oldest:
        return 'Oldest';
      case DocumentSort.nameAsc:
        return 'Name A → Z';
      case DocumentSort.nameDesc:
        return 'Name Z → A';
    }
  }
}

enum ExportTarget { json, pdf, pptx }

extension on ExportTarget {
  String get label {
    switch (this) {
      case ExportTarget.json:
        return 'JSON';
      case ExportTarget.pdf:
        return 'PDF';
      case ExportTarget.pptx:
        return 'PPTX';
    }
  }
}

class _DashboardPalette {
  const _DashboardPalette({
    required this.isDark,
    required this.accent,
    required this.onAccent,
    required this.canvas,
    required this.body,
    required this.sidebar,
    required this.sidebarBorder,
    required this.card,
    required this.cardBorder,
    required this.topBar,
    required this.topBarBorder,
    required this.topBarShadow,
    required this.navActiveBg,
    required this.navActiveBorder,
    required this.navHoverBg,
    required this.navActiveText,
    required this.navInactiveText,
    required this.navInactiveIcon,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconMuted,
    required this.statsCard,
    required this.statsBorder,
    required this.filterBg,
    required this.filterBorder,
    required this.filterActiveBg,
    required this.filterActiveBorder,
    required this.filterActiveText,
    required this.filterInactiveText,
    required this.listTileBg,
    required this.listTileBorder,
    required this.popupBg,
    required this.emptyCard,
    required this.emptyBorder,
    required this.emptyOverlay,
    required this.outlineButtonBorder,
    required this.outlineButtonForeground,
  });

  final bool isDark;
  final Color accent;
  final Color onAccent;
  final Color canvas;
  final Color body;
  final Color sidebar;
  final Color sidebarBorder;
  final Color card;
  final Color cardBorder;
  final Color topBar;
  final Color topBarBorder;
  final Color topBarShadow;
  final Color navActiveBg;
  final Color navActiveBorder;
  final Color navHoverBg;
  final Color navActiveText;
  final Color navInactiveText;
  final Color navInactiveIcon;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconMuted;
  final Color statsCard;
  final Color statsBorder;
  final Color filterBg;
  final Color filterBorder;
  final Color filterActiveBg;
  final Color filterActiveBorder;
  final Color filterActiveText;
  final Color filterInactiveText;
  final Color listTileBg;
  final Color listTileBorder;
  final Color popupBg;
  final Color emptyCard;
  final Color emptyBorder;
  final Color emptyOverlay;
  final Color outlineButtonBorder;
  final Color outlineButtonForeground;

  static _DashboardPalette of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    if (isDark) {
      return _DashboardPalette(
        isDark: true,
        accent: scheme.primary,
        onAccent: scheme.onPrimary,
        canvas: const Color(0xFF080A10),
        body: const Color(0xFF0F111A),
        sidebar: const Color(0xFF11121A),
        sidebarBorder: const Color(0xFF1F2334),
        card: const Color(0xFF171A26),
        cardBorder: const Color(0xFF2B3146),
        topBar: const Color(0xFF0D1019),
        topBarBorder: const Color(0xFF1F2334),
        topBarShadow: Colors.black26,
        navActiveBg: const Color(0xFF1C1F2F),
        navActiveBorder: const Color(0xFF343C55),
        navHoverBg: const Color(0xFF161A26),
        navActiveText: const Color(0xFFEEF0FF),
        navInactiveText: const Color(0xFF9BA1C1),
        navInactiveIcon: const Color(0xFF7C819C),
        textPrimary: Colors.white,
        textSecondary: const Color(0xFF9CA3C9),
        iconMuted: const Color(0xFF858AA8),
        statsCard: const Color(0xFF1A1D29),
        statsBorder: const Color(0xFF25293A),
        filterBg: const Color(0xFF121623),
        filterBorder: const Color(0xFF1F2538),
        filterActiveBg: const Color(0xFF1F2440),
        filterActiveBorder: scheme.primary,
        filterActiveText: const Color(0xFFCBCFF8),
        filterInactiveText: const Color(0xFF8E94B1),
        listTileBg: const Color(0xFF1A1E2A),
        listTileBorder: const Color(0xFF2A3045),
        popupBg: const Color(0xFF161A27),
        emptyCard: const Color(0xFF1C2136),
        emptyBorder: const Color(0xFF262C42),
        emptyOverlay: Colors.black54,
        outlineButtonBorder: scheme.primary.withOpacity(0.5),
        outlineButtonForeground: Colors.white,
      );
    }

    return _DashboardPalette(
      isDark: false,
      accent: scheme.primary,
      onAccent: scheme.onPrimary,
      canvas: const Color(0xFFF3F4F6),
      body: Colors.white,
      sidebar: Colors.white,
      sidebarBorder: const Color(0xFFE5E7EB),
      card: Colors.white,
      cardBorder: const Color(0xFFE5E7EB),
      topBar: Colors.white,
      topBarBorder: const Color(0xFFE5E7EB),
      topBarShadow: Colors.black12,
      navActiveBg: scheme.primary.withOpacity(0.08),
      navActiveBorder: scheme.primary.withOpacity(0.2),
      navHoverBg: const Color(0xFFF3F4F6),
      navActiveText: scheme.primary,
      navInactiveText: const Color(0xFF4B5563),
      navInactiveIcon: const Color(0xFF6B7280),
      textPrimary: const Color(0xFF111827),
      textSecondary: const Color(0xFF6B7280),
      iconMuted: const Color(0xFF6B7280),
      statsCard: const Color(0xFFF9FAFB),
      statsBorder: const Color(0xFFE5E7EB),
      filterBg: const Color(0xFFF3F4F6),
      filterBorder: const Color(0xFFE5E7EB),
      filterActiveBg: scheme.primary.withOpacity(0.12),
      filterActiveBorder: scheme.primary.withOpacity(0.3),
      filterActiveText: scheme.primary,
      filterInactiveText: const Color(0xFF6B7280),
      listTileBg: Colors.white,
      listTileBorder: const Color(0xFFE5E7EB),
      popupBg: Colors.white,
      emptyCard: Colors.white,
      emptyBorder: const Color(0xFFE5E7EB),
      emptyOverlay: Colors.black12,
      outlineButtonBorder: const Color(0xFFD1D5DB),
      outlineButtonForeground: const Color(0xFF111827),
    );
  }
}

