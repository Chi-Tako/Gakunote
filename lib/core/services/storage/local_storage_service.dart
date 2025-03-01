import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../../models/note.dart';
import 'storage_service.dart';

@Singleton(as: StorageService)
class LocalStorageService implements StorageService {
  static const String _notesBoxName = 'notes';

  late Box _notesBox;

  @override
  Future<void> initialize() async {
    _notesBox = await Hive.openBox(_notesBoxName);
  }

  @override
  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  @override
  Future<Note?> getNoteById(String id) async {
    return _notesBox.get(id);
  }

  @override
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }

  @override
  Future<void> clear() async {
    await _notesBox.clear();
  }

  @override
  String get storageType => 'local';

  @override
  Future<List<Note>> getFavoriteNotes() async {
    // TODO: implement getFavoriteNotes
    return [];
  }

  @override
  Future<List<Note>> getNotes() async {
    // TODO: implement getNotes
    return _notesBox.values.toList().cast<Note>();
  }

  @override
  Future<List<Note>> getNotesByTag(String tag) async {
    // TODO: implement getNotesByTag
    return [];
  }

  @override
  Future<void> toggleFavorite(String id) async {
    // TODO: implement toggleFavorite
  }

  @override
  Future<List<String>> getAllTags() async {
    // TODO: implement getAllTags
    return [];
  }

  @override
  Future<Map<String, dynamic>> exportData() async {
    // TODO: implement exportData
    return {};
  }

  @override
  Future<bool> importData(Map<String, dynamic> data) async {
    // TODO: implement importData
    return false;
  }
}