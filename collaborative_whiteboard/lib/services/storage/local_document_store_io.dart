import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/whiteboard_document.dart';
import 'local_document_store.dart';

LocalDocumentStore createDocumentStoreImpl() => LocalDocumentStoreIo();

class LocalDocumentStoreIo implements LocalDocumentStore {
  Future<Directory> _documentsDirectory() async {
    final Directory baseDir = await getApplicationDocumentsDirectory();
    final Directory target = Directory(p.join(baseDir.path, 'whiteboard_documents'));
    if (!await target.exists()) {
      await target.create(recursive: true);
    }
    return target;
  }

  Future<File> _documentFile(String id) async {
    final dir = await _documentsDirectory();
    return File(p.join(dir.path, '$id.json'));
  }

  @override
  Future<void> deleteDocument(String id) async {
    final file = await _documentFile(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<WhiteboardDocument?> loadDocument(String id) async {
    final file = await _documentFile(id);
    if (!await file.exists()) {
      return null;
    }
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return WhiteboardDocument.fromJson(json);
  }

  @override
  Future<List<WhiteboardDocumentSummary>> listDocuments({int? limit}) async {
    final dir = await _documentsDirectory();
    if (!await dir.exists()) {
      return [];
    }
    final entities = await dir.list().where((entity) => entity is File && entity.path.endsWith('.json')).toList();
    entities.sort((a, b) => (b.statSync().modified).compareTo(a.statSync().modified));
    final summaries = <WhiteboardDocumentSummary>[];
    for (final entity in entities) {
      if (limit != null && summaries.length >= limit) {
        break;
      }
      try {
        final raw = await File(entity.path).readAsString();
        final json = jsonDecode(raw) as Map<String, dynamic>;
        if (json.containsKey('pages')) {
          final doc = WhiteboardDocument.fromJson(json);
          summaries.add(WhiteboardDocumentSummary.fromDocument(doc));
        }
      } catch (_) {
        continue;
      }
    }
    return summaries;
  }

  @override
  Future<void> renameDocument(String id, String newTitle) async {
    final doc = await loadDocument(id);
    if (doc == null) return;
    final updated = doc.copyWith(title: newTitle, updatedAt: DateTime.now());
    await saveDocument(updated);
  }

  @override
  Future<void> saveDocument(WhiteboardDocument document) async {
    final file = await _documentFile(document.id);
    final payload = jsonEncode(document.toJson());
    await file.writeAsString(payload, flush: true);
  }
}
