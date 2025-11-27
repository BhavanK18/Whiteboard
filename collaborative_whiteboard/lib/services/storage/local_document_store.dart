import '../../models/whiteboard_document.dart';
import 'local_document_store_io.dart'
    if (dart.library.html) 'local_document_store_web.dart';

abstract class LocalDocumentStore {
  Future<List<WhiteboardDocumentSummary>> listDocuments({int? limit});
  Future<WhiteboardDocument?> loadDocument(String id);
  Future<void> saveDocument(WhiteboardDocument document);
  Future<void> deleteDocument(String id);
  Future<void> renameDocument(String id, String newTitle);
}

LocalDocumentStore createDocumentStore() => createDocumentStoreImpl();
