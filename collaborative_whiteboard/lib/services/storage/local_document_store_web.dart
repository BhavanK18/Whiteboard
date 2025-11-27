import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/whiteboard_document.dart';
import 'local_document_store.dart';

LocalDocumentStore createDocumentStoreImpl() => LocalDocumentStoreWeb();

class LocalDocumentStoreWeb implements LocalDocumentStore {
  static const String _idsKey = 'whiteboard_documents_ids';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<List<String>> _loadIds(SharedPreferences prefs) async {
    return prefs.getStringList(_idsKey) ?? <String>[];
  }

  Future<void> _persistIds(SharedPreferences prefs, List<String> ids) async {
    await prefs.setStringList(_idsKey, ids);
  }

  String _docKey(String id) => 'whiteboard_document_$id';

  @override
  Future<void> deleteDocument(String id) async {
    final prefs = await _prefs();
    final ids = await _loadIds(prefs);
    ids.remove(id);
    await _persistIds(prefs, ids);
    await prefs.remove(_docKey(id));
  }

  @override
  Future<WhiteboardDocument?> loadDocument(String id) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_docKey(id));
    if (raw == null) {
      return null;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return WhiteboardDocument.fromJson(json);
  }

  @override
  Future<List<WhiteboardDocumentSummary>> listDocuments({int? limit}) async {
    final prefs = await _prefs();
    final ids = await _loadIds(prefs);
    final summaries = <WhiteboardDocumentSummary>[];
    for (final id in ids) {
      if (limit != null && summaries.length >= limit) {
        break;
      }
      final raw = prefs.getString(_docKey(id));
      if (raw == null) continue;
      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        final doc = WhiteboardDocument.fromJson(json);
        summaries.add(WhiteboardDocumentSummary.fromDocument(doc));
      } catch (_) {
        continue;
      }
    }
    summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return summaries;
  }

  @override
  Future<void> renameDocument(String id, String newTitle) async {
    final prefs = await _prefs();
    final raw = prefs.getString(_docKey(id));
    if (raw == null) {
      return;
    }
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final document = WhiteboardDocument.fromJson(json);
    final updated = document.copyWith(title: newTitle, updatedAt: DateTime.now());
    await saveDocument(updated);
  }

  @override
  Future<void> saveDocument(WhiteboardDocument document) async {
    final prefs = await _prefs();
    final ids = await _loadIds(prefs);
    if (!ids.contains(document.id)) {
      ids.insert(0, document.id);
    }
    await _persistIds(prefs, ids);
    await prefs.setString(_docKey(document.id), jsonEncode(document.toJson()));
  }
}
