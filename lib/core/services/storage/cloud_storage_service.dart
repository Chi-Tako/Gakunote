// lib/core/services/storage/cloud_storage_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/note.dart';
import '../../database/firebase_service.dart';
import 'storage_service.dart';

/// クラウドストレージ（Firebase）を使用したノート保存サービス
class CloudStorageService implements StorageService {
  final FirebaseService _firebase = FirebaseService();
  
  // コレクション名の定数
  static const String _collectionPath = 'notes';
  
  @override
  Future<void> initialize() async {
    // Firebase認証が必要
    if (_firebase.auth.currentUser == null) {
      throw Exception('ユーザーがログインしていません。クラウド同期を使用するにはログインが必要です。');
    }
  }
  
  @override
  Future<List<Note>> getNotes() async {
    try {
      final snapshot = await _firebase.userCollection(_collectionPath)
          .orderBy('updatedAt', descending: true)
          .get();
          
      return snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList();
    } catch (e) {
      print('クラウドからのノート取得エラー: $e');
      return [];
    }
  }
  
  @override
  Future<Note?> getNoteById(String id) async {
    try {
      final docSnapshot = await _firebase.userCollection(_collectionPath).doc(id).get();
      
      if (docSnapshot.exists) {
        return Note.fromJson(docSnapshot.data()!);
      }
      
      return null;
    } catch (e) {
      print('クラウドからのノート取得エラー: $e');
      return null;
    }
  }
  
  @override
  Future<List<Note>> getFavoriteNotes() async {
    try {
      final snapshot = await _firebase.userCollection(_collectionPath)
          .where('isFavorite', isEqualTo: true)
          .orderBy('updatedAt', descending: true)
          .get();
          
      return snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList();
    } catch (e) {
      print('クラウドからのお気に入りノート取得エラー: $e');
      return [];
    }
  }
  
  @override
  Future<List<Note>> getNotesByTag(String tag) async {
    try {
      final snapshot = await _firebase.userCollection(_collectionPath)
          .where('tags', arrayContains: tag)
          .orderBy('updatedAt', descending: true)
          .get();
          
      return snapshot.docs.map((doc) => Note.fromJson(doc.data())).toList();
    } catch (e) {
      print('クラウドからのタグ付きノート取得エラー: $e');
      return [];
    }
  }
  
  @override
  Future<void> saveNote(Note note) async {
    try {
      // FirebaseのサーバータイムスタンプでupdatedAtを更新
      final data = note.toJson();
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      // 新規作成の場合はcreatedAtも設定
      if (note.createdAt == note.updatedAt) {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      
      await _firebase.userCollection(_collectionPath).doc(note.id).set(data);
    } catch (e) {
      print('クラウドへのノート保存エラー: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> deleteNote(String id) async {
    try {
      await _firebase.userCollection(_collectionPath).doc(id).delete();
    } catch (e) {
      print('クラウドからのノート削除エラー: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> toggleFavorite(String id) async {
    try {
      final docRef = _firebase.userCollection(_collectionPath).doc(id);
      
      await _firebase.firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        
        if (snapshot.exists) {
          final currentValue = snapshot.data()?['isFavorite'] ?? false;
          transaction.update(docRef, {'isFavorite': !currentValue});
        }
      });
    } catch (e) {
      print('クラウドでのお気に入り状態変更エラー: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<String>> getAllTags() async {
    try {
      final snapshot = await _firebase.userCollection(_collectionPath).get();
      
      // すべてのノートからタグを抽出して重複を排除
      final Set<String> uniqueTags = {};
      
      for (var doc in snapshot.docs) {
        final tags = List<String>.from(doc.data()['tags'] ?? []);
        uniqueTags.addAll(tags);
      }
      
      return uniqueTags.toList();
    } catch (e) {
      print('クラウドからのタグ取得エラー: $e');
      return [];
    }
  }
  
  @override
  String get storageType => 'cloud';
  
  @override
  Future<Map<String, dynamic>> exportData() async {
    try {
      final notes = await getNotes();
      final notesJson = notes.map((note) => note.toJson()).toList();
      
      // ユーザー設定を取得
      final userSettingsDoc = await _firebase.firestore
          .collection('users')
          .doc(_firebase.currentUserId)
          .collection('settings')
          .doc('userSettings')
          .get();
      
      final settings = userSettingsDoc.exists 
          ? userSettingsDoc.data() ?? {} 
          : <String, dynamic>{};
      
      return {
        'notes': notesJson,
        'settings': settings,
        'exportDate': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('クラウドデータのエクスポートエラー: $e');
      return {
        'error': e.toString(),
        'exportDate': DateTime.now().toIso8601String(),
      };
    }
  }
  
  @override
  Future<bool> importData(Map<String, dynamic> data) async {
    try {
      // バッチ処理を使用して一括更新
      final batch = _firebase.firestore.batch();
      
      // ノートをインポート
      if (data.containsKey('notes')) {
        final notesJson = List<Map<String, dynamic>>.from(data['notes']);
        
        // 既存のノートを参照するためのコレクション
        final notesCollection = _firebase.userCollection(_collectionPath);
        
        // 各ノートをバッチに追加
        for (final noteJson in notesJson) {
          final note = Note.fromJson(noteJson);
          final docRef = notesCollection.doc(note.id);
          batch.set(docRef, note.toJson());
        }
      }
      
      // 設定をインポート
      if (data.containsKey('settings')) {
        final settings = Map<String, dynamic>.from(data['settings']);
        final settingsDocRef = _firebase.firestore
            .collection('users')
            .doc(_firebase.currentUserId)
            .collection('settings')
            .doc('userSettings');
        
        batch.set(settingsDocRef, settings);
      }
      
      // バッチコミット
      await batch.commit();
      
      return true;
    } catch (e) {
      print('クラウドデータのインポートエラー: $e');
      return false;
    }
  }
  
  // クラウド固有のメソッド：ローカルデータとクラウドデータの同期
  Future<void> syncWithLocalStorage(StorageService localStorageService) async {
    try {
      // ローカルのノートを取得
      final localNotes = await localStorageService.getNotes();
      
      // クラウドのノートを取得
      final cloudNotes = await getNotes();
      
      // IDをキーとしたマップを作成
      final localNotesMap = {for (var note in localNotes) note.id: note};
      final cloudNotesMap = {for (var note in cloudNotes) note.id: note};
      
      // バッチ処理のためのリファレンス
      final batch = _firebase.firestore.batch();
      final notesCollection = _firebase.userCollection(_collectionPath);
      
      // 1. クラウドにしかないノートはローカルに追加（ダウンロード）
      // 2. ローカルにしかないノートはクラウドに追加（アップロード）
      // 3. 両方にあるノートは更新日時が新しい方を採用
      
      for (final cloudNote in cloudNotes) {
        if (!localNotesMap.containsKey(cloudNote.id)) {
          // クラウドにしかないノート → ローカルに追加
          await localStorageService.saveNote(cloudNote);
        } else {
          // 両方にあるノート → 更新日時を比較
          final localNote = localNotesMap[cloudNote.id]!;
          if (cloudNote.updatedAt.isAfter(localNote.updatedAt)) {
            // クラウドの方が新しい → ローカルを更新
            await localStorageService.saveNote(cloudNote);
          } else if (localNote.updatedAt.isAfter(cloudNote.updatedAt)) {
            // ローカルの方が新しい → クラウドを更新
            final docRef = notesCollection.doc(localNote.id);
            batch.set(docRef, localNote.toJson());
          }
        }
      }
      
      for (final localNote in localNotes) {
        if (!cloudNotesMap.containsKey(localNote.id)) {
          // ローカルにしかないノート → クラウドに追加
          final docRef = notesCollection.doc(localNote.id);
          batch.set(docRef, localNote.toJson());
        }
      }
      
      // バッチコミット
      await batch.commit();
    } catch (e) {
      print('同期エラー: $e');
      rethrow;
    }
  }
}