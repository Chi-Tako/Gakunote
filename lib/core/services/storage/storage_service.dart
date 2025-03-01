// lib/core/services/storage/storage_service.dart
import '../../models/note.dart';

/// ノートストレージの抽象インターフェース
/// ローカルとクラウドの両方のストレージに対応
abstract class StorageService {
  /// 初期化処理
  Future<void> initialize();
  
  /// ノート一覧を取得
  Future<List<Note>> getNotes();
  
  /// ノートをIDで取得
  Future<Note?> getNoteById(String id);
  
  /// お気に入りのノート一覧を取得
  Future<List<Note>> getFavoriteNotes();
  
  /// タグでノートを絞り込み
  Future<List<Note>> getNotesByTag(String tag);
  
  /// ノートを保存（新規作成または更新）
  Future<void> saveNote(Note note);
  
  /// ノートを削除
  Future<void> deleteNote(String id);
  
  /// お気に入り状態を切り替え
  Future<void> toggleFavorite(String id);
  
  /// 全てのタグを取得
  Future<List<String>> getAllTags();
  
  /// ストレージタイプを取得（"local" または "cloud"）
  String get storageType;
  
  /// データをエクスポート（バックアップ用）
  Future<Map<String, dynamic>> exportData();
  
  /// データをインポート（復元用）
  Future<bool> importData(Map<String, dynamic> data);
}