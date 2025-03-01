// lib/core/services/note_service.dart
import 'package:flutter/foundation.dart';
import '../models/note.dart';
import 'storage/storage_service_factory.dart';

/// ノート関連のビジネスロジックと状態管理を提供するサービスクラス
class NoteService extends ChangeNotifier {
  final StorageServiceFactory _storageFactory = StorageServiceFactory();
  
  // 現在のノート一覧
  List<Note> _notes = [];
  
  // お気に入りノート一覧
  List<Note> _favoriteNotes = [];
  
  // タグリスト
  List<String> _tags = [];
  
  // 現在開いているノート
  Note? _currentNote;
  
  // ローディング状態
  bool _isLoading = false;
  
  // ゲッター
  List<Note> get notes => _notes;
  List<Note> get favoriteNotes => _favoriteNotes;
  List<String> get tags => _tags;
  Note? get currentNote => _currentNote;
  bool get isLoading => _isLoading;
  
  // 初期化処理
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // ストレージファクトリの初期化
      await _storageFactory.initialize();
      
      // ノート一覧の読み込み
      await _refreshNotes();
      
      // タグの読み込み
      await _loadTags();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('NoteServiceの初期化中にエラーが発生しました: $e');
    }
  }
  
  // ノート一覧を再読み込み
  Future<void> _refreshNotes() async {
    try {
      final storageService = _storageFactory.getStorageService();
      _notes = await storageService.getNotes();
      _favoriteNotes = await storageService.getFavoriteNotes();
      notifyListeners();
    } catch (e) {
      print('ノート一覧の読み込み中にエラーが発生しました: $e');
    }
  }
  
  // タグリストを読み込む
  Future<void> _loadTags() async {
    try {
      final storageService = _storageFactory.getStorageService();
      _tags = await storageService.getAllTags();
      notifyListeners();
    } catch (e) {
      print('タグリストの取得中にエラーが発生しました: $e');
    }
  }
  
  // 特定のノートを読み込む
  Future<Note?> getNoteById(String id) async {
    _setLoading(true);
    
    try {
      final storageService = _storageFactory.getStorageService();
      final note = await storageService.getNoteById(id);
      _currentNote = note;
      _setLoading(false);
      notifyListeners();
      return note;
    } catch (e) {
      _setLoading(false);
      print('ノートの取得中にエラーが発生しました: $e');
      return null;
    }
  }
  
  // ノートを保存（作成または更新）
  Future<void> saveNote(Note note) async {
    _setLoading(true);
    
    try {
      final storageService = _storageFactory.getStorageService();
      await storageService.saveNote(note);
      _currentNote = note;
      
      // ノート一覧を更新
      await _refreshNotes();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('ノートの保存中にエラーが発生しました: $e');
    }
  }
  
  // ノートを削除
  Future<void> deleteNote(String id) async {
    _setLoading(true);
    
    try {
      final storageService = _storageFactory.getStorageService();
      await storageService.deleteNote(id);
      
      if (_currentNote?.id == id) {
        _currentNote = null;
      }
      
      // ノート一覧を更新
      await _refreshNotes();
      
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('ノートの削除中にエラーが発生しました: $e');
    }
  }
  
  // お気に入り状態を切り替え
  Future<void> toggleFavorite(String id) async {
    try {
      final storageService = _storageFactory.getStorageService();
      await storageService.toggleFavorite(id);
      
      // 現在開いているノートの場合は状態を更新
      if (_currentNote?.id == id) {
        _currentNote = await storageService.getNoteById(id);
      }
      
      // ノート一覧を更新
      await _refreshNotes();
      
      notifyListeners();
    } catch (e) {
      print('お気に入り状態の切り替え中にエラーが発生しました: $e');
    }
  }
  
  // 新規ノートを作成
  Note createNewNote({String title = '新規ノート'}) {
    final note = Note(
      title: title,
      blocks: [
        NoteBlock(
          type: BlockType.heading1,
          content: title,
        ),
        NoteBlock(
          type: BlockType.text,
          content: '',
        ),
      ],
    );
    
    _currentNote = note;
    notifyListeners();
    return note;
  }
  
  // 特定のタグを持つノートをフィルタリング
  Future<List<Note>> getNotesByTag(String tag) async {
    final storageService = _storageFactory.getStorageService();
    return await storageService.getNotesByTag(tag);
  }
  
  // データをエクスポート
  Future<Map<String, dynamic>> exportData() async {
    final storageService = _storageFactory.getStorageService();
    return await storageService.exportData();
  }
  
  // データをインポート
  Future<bool> importData(Map<String, dynamic> data) async {
    final storageService = _storageFactory.getStorageService();
    final result = await storageService.importData(data);
    
    if (result) {
      // データを再読み込み
      await _refreshNotes();
      await _loadTags();
    }
    
    return result;
  }
  
  // クラウド同期の有効/無効を切り替え
  Future<void> toggleCloudSync(bool enabled) async {
    await _storageFactory.setCloudSyncEnabled(enabled);
    
    // データを再読み込み
    await _refreshNotes();
    
    notifyListeners();
  }
  
  // クラウド同期が有効かどうか
  bool get isCloudSyncEnabled => _storageFactory.isCloudSyncEnabled;
  
  // 現在のストレージタイプ
  String get currentStorageType => _storageFactory.currentStorageType;
  
  // 手動でクラウド同期を実行
  Future<void> syncWithCloud() async {
    _setLoading(true);
    
    try {
      await _storageFactory.syncData();
      await _refreshNotes();
      await _loadTags();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('クラウド同期中にエラーが発生しました: $e');
    }
  }
  
  // ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}