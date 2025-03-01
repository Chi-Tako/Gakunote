import 'package:flutter/foundation.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

/// ノート関連のビジネスロジックと状態管理を提供するサービスクラス
class NoteService extends ChangeNotifier {
  final NoteRepository _noteRepository = NoteRepository();
  
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
      await _loadTags();
      // _loadNotes()はStreamなので、ここでは呼び出さない
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      print('NoteServiceの初期化中にエラーが発生しました: $e');
    }
  }
  
  // ノート一覧を読み込む
  void loadNotes() {
    _noteRepository.getNotes().listen((notes) {
      _notes = notes;
      notifyListeners();
    }, onError: (e) {
      print('ノート一覧の取得中にエラーが発生しました: $e');
    });
  }
  
  // お気に入りノート一覧を読み込む
  void loadFavoriteNotes() {
    _noteRepository.getFavoriteNotes().listen((notes) {
      _favoriteNotes = notes;
      notifyListeners();
    }, onError: (e) {
      print('お気に入りノート一覧の取得中にエラーが発生しました: $e');
    });
  }
  
  // タグリストを読み込む
  Future<void> _loadTags() async {
    try {
      _tags = await _noteRepository.getAllTags();
    } catch (e) {
      print('タグリストの取得中にエラーが発生しました: $e');
    }
  }
  
  // 特定のノートを読み込む
  Future<Note?> getNoteById(String id) async {
    _setLoading(true);
    try {
      final note = await _noteRepository.getNoteById(id);
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
      await _noteRepository.saveNote(note);
      _currentNote = note;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      print('ノートの保存中にエラーが発生しました: $e');
    }
  }
  
  // ノートを削除
  Future<void> deleteNote(String id) async {
    _setLoading(true);
    try {
      await _noteRepository.deleteNote(id);
      if (_currentNote?.id == id) {
        _currentNote = null;
      }
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setLoading(false);
      print('ノートの削除中にエラーが発生しました: $e');
    }
  }
  
  // お気に入り状態を切り替え
  Future<void> toggleFavorite(String id) async {
    try {
      await _noteRepository.toggleFavorite(id);
      
      // 現在開いているノートの場合は状態を更新
      if (_currentNote?.id == id) {
        _currentNote = await _noteRepository.getNoteById(id);
        notifyListeners();
      }
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
  
  // ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}