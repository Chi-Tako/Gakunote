import 'package:cloud_firestore/cloud_firestore.dart';
import '../database/firebase_service.dart';
import '../models/note.dart';

/// ノートのCRUD操作を提供するリポジトリクラス
class NoteRepository {
  final FirebaseService _firebase = FirebaseService();
  
  // コレクション名の定数
  static const String _collectionPath = 'notes';
  
  /// ノート一覧を取得
  Stream<List<Note>> getNotes() {
    // タグやお気に入りでフィルタリングする場合は引数を追加して対応可能
    return _firebase.userCollection(_collectionPath)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Note.fromJson(doc.data());
          }).toList();
        });
  }
  
  /// 指定したIDのノートを取得
  Future<Note?> getNoteById(String id) async {
    final docSnapshot = await _firebase.userCollection(_collectionPath).doc(id).get();
    
    if (docSnapshot.exists) {
      return Note.fromJson(docSnapshot.data()!);
    }
    
    return null;
  }
  
  /// お気に入りのノート一覧を取得
  Stream<List<Note>> getFavoriteNotes() {
    return _firebase.userCollection(_collectionPath)
        .where('isFavorite', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Note.fromJson(doc.data());
          }).toList();
        });
  }
  
  /// 特定のタグを持つノート一覧を取得
  Stream<List<Note>> getNotesByTag(String tag) {
    return _firebase.userCollection(_collectionPath)
        .where('tags', arrayContains: tag)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Note.fromJson(doc.data());
          }).toList();
        });
  }
  
  /// ノートを保存（作成または更新）
  Future<void> saveNote(Note note) async {
    // FirebaseのサーバータイムスタンプでupdatedAtを更新
    final data = note.toJson();
    data['updatedAt'] = _firebase.serverTimestamp;
    
    // 新規作成の場合はcreatedAtも設定
    if (note.createdAt == note.updatedAt) {
      data['createdAt'] = _firebase.serverTimestamp;
    }
    
    await _firebase.userCollection(_collectionPath).doc(note.id).set(data);
  }
  
  /// ノートを削除
  Future<void> deleteNote(String id) async {
    await _firebase.userCollection(_collectionPath).doc(id).delete();
  }
  
  /// お気に入り状態を切り替え
  Future<void> toggleFavorite(String id) async {
    final docRef = _firebase.userCollection(_collectionPath).doc(id);
    
    return _firebase.firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      
      if (snapshot.exists) {
        final currentValue = snapshot.data()?['isFavorite'] ?? false;
        transaction.update(docRef, {'isFavorite': !currentValue});
      }
    });
  }
  
  /// 全てのタグのリストを取得
  Future<List<String>> getAllTags() async {
    final snapshot = await _firebase.userCollection(_collectionPath).get();
    
    // すべてのノートからタグを抽出して重複を排除
    final Set<String> uniqueTags = {};
    
    for (var doc in snapshot.docs) {
      final tags = List<String>.from(doc.data()['tags'] ?? []);
      uniqueTags.addAll(tags);
    }
    
    return uniqueTags.toList();
  }
}