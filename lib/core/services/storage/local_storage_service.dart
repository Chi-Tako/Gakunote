// lib/core/services/storage/local_storage_service.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/note.dart';
import 'storage_service.dart';

/// ローカルストレージを使用したノート保存サービス
class LocalStorageService implements StorageService {
  static const String _notesBoxName = 'notes';
  static const String _settingsBoxName = 'settings';
  
  late Box<String> _notesBox;
  late Box<dynamic> _settingsBox;
  
  @override
  Future<void> initialize() async {
    // Hiveの初期化
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    
    // ボックスを開く
    _notesBox = await Hive.openBox<String>(_notesBoxName);
    _settingsBox = await Hive.openBox<dynamic>(_settingsBoxName);
  }
  
  @override
  Future<List<Note>> getNotes() async {
    final notes = <Note>[];
    
    for (final key in _notesBox.keys) {
      final noteJson = _notesBox.get(key);
      if (noteJson != null) {
        try {
          final note = Note.fromJson(json.decode(noteJson));
          notes.add(note);
        } catch (e) {
          print('ノートの解析エラー: $e');
        }
      }
    }
    
    // 更新日時でソート（新しい順）
    notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return notes;
  }
  
  @override
  Future<Note?> getNoteById(String id) async {
    final noteJson = _notesBox.get(id);
    if (noteJson != null) {
      try {
        return Note.fromJson(json.decode(noteJson));
      } catch (e) {
        print('ノートの解析エラー: $e');
      }
    }
    return null;
  }
  
  @override
  Future<List<Note>> getFavoriteNotes() async {
    final allNotes = await getNotes();
    return allNotes.where((note) => note.isFavorite).toList();
  }
  
  @override
  Future<List<Note>> getNotesByTag(String tag) async {
    final allNotes = await getNotes();
    return allNotes.where((note) => note.tags.contains(tag)).toList();
  }
  
  @override
  Future<void> saveNote(Note note) async {
    // 更新日時を更新
    final now = DateTime.now();
    final updatedNote = Note(
      id: note.id,
      title: note.title,
      blocks: note.blocks,
      createdAt: note.createdAt,
      updatedAt: now,
      tags: note.tags,
      isFavorite: note.isFavorite,
    );
    
    // JSONに変換して保存
    final noteJson = json.encode(updatedNote.toJson());
    await _notesBox.put(note.id, noteJson);
  }
  
  @override
  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }
  
  @override
  Future<void> toggleFavorite(String id) async {
    final note = await getNoteById(id);
    if (note != null) {
      note.isFavorite = !note.isFavorite;
      await saveNote(note);
    }
  }
  
  @override
  Future<List<String>> getAllTags() async {
    final allNotes = await getNotes();
    final Set<String> uniqueTags = {};
    
    for (final note in allNotes) {
      uniqueTags.addAll(note.tags);
    }
    
    return uniqueTags.toList();
  }
  
  @override
  String get storageType => 'local';
  
  @override
  Future<Map<String, dynamic>> exportData() async {
    final notes = await getNotes();
    final notesJson = notes.map((note) => note.toJson()).toList();
    
    return {
      'notes': notesJson,
      'settings': Map<String, dynamic>.from(_settingsBox.toMap()),
      'exportDate': DateTime.now().toIso8601String(),
    };
  }
  
  @override
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // ノートをインポート
      if (data.containsKey('notes')) {
        final notesJson = List<Map<String, dynamic>>.from(data['notes']);
        
        // 現在のノートを全て削除
        await _notesBox.clear();
        
        // 新しいノートを保存
        for (final noteJson in notesJson) {
          final note = Note.fromJson(noteJson);
          final encodedNote = json.encode(note.toJson());
          await _notesBox.put(note.id, encodedNote);
        }
      }
      
      // 設定をインポート
      if (data.containsKey('settings')) {
        final settings = Map<String, dynamic>.from(data['settings']);
        await _settingsBox.clear();
        settings.forEach((key, value) async {
          await _settingsBox.put(key, value);
        });
      }
      
      return true;
    } catch (e) {
      print('データインポートエラー: $e');
      return false;
    }
  }
  
  // 設定の保存と取得のヘルパーメソッド
  Future<void> setSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
  
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
}