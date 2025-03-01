import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Firebaseの各種サービスへのアクセスを提供するユーティリティクラス
class FirebaseService {
  // シングルトンインスタンス
  static final FirebaseService _instance = FirebaseService._internal();
  
  // プライベートコンストラクタ
  FirebaseService._internal();
  
  // ファクトリコンストラクタ
  factory FirebaseService() {
    return _instance;
  }
  
  // Firestoreインスタンス
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Authインスタンス
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Storageインスタンス
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // ゲッター
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  FirebaseStorage get storage => _storage;
  
  // 現在ログイン中のユーザーID
  String? get currentUserId => _auth.currentUser?.uid;
  
  // 現在のユーザーがログインしているかどうか
  bool get isLoggedIn => _auth.currentUser != null;
  
  // コレクション参照を簡単に取得するためのヘルパーメソッド
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }
  
  // ドキュメント参照を簡単に取得するためのヘルパーメソッド
  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }
  
  // タイムスタンプを生成するヘルパーメソッド
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();
  
  // ユーザー固有のコレクション参照を取得するヘルパーメソッド
  CollectionReference<Map<String, dynamic>> userCollection(String collectionPath) {
    if (currentUserId == null) {
      throw Exception('ユーザーがログインしていません');
    }
    return _firestore.collection('users/$currentUserId/$collectionPath');
  }
}