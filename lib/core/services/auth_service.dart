import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../database/firebase_service.dart';

/// 認証関連の機能と状態管理を提供するサービスクラス
class AuthService extends ChangeNotifier {
  final FirebaseService _firebase = FirebaseService();
  
  // 現在のユーザー
  User? _currentUser;
  
  // ローディング状態
  bool _isLoading = false;
  
  // エラーメッセージ
  String? _errorMessage;
  
  // ゲッター
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  
  // 認証状態の初期化と監視
  void initialize() {
    // 認証状態の変化を監視
    _firebase.auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      notifyListeners();
    });
  }
  
  // メールアドレス・パスワードでサインアップ
  Future<User?> signUpWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final credential = await _firebase.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return null;
    }
  }
  
  // メールアドレス・パスワードでログイン
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final credential = await _firebase.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return null;
    }
  }
  
  // サインアウト
  Future<void> signOut() async {
    _setLoading(true);
    
    try {
      await _firebase.auth.signOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError('サインアウト中にエラーが発生しました: $e');
    }
  }
  
  // パスワードリセットメールを送信
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _firebase.auth.sendPasswordResetEmail(email: email);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    }
  }
  
  // ユーザーアカウントを削除
  Future<bool> deleteAccount() async {
    _setLoading(true);
    _clearError();
    
    try {
      await _firebase.auth.currentUser?.delete();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _setLoading(false);
      _handleAuthError(e);
      return false;
    }
  }
  
  // 認証エラーを処理
  void _handleAuthError(FirebaseAuthException e) {
    String message;
    
    switch (e.code) {
      case 'user-not-found':
        message = 'ユーザーが見つかりません。';
        break;
      case 'wrong-password':
        message = 'パスワードが正しくありません。';
        break;
      case 'email-already-in-use':
        message = 'このメールアドレスは既に使用されています。';
        break;
      case 'weak-password':
        message = 'パスワードが弱すぎます。もっと強力なパスワードを設定してください。';
        break;
      case 'invalid-email':
        message = '無効なメールアドレス形式です。';
        break;
      case 'operation-not-allowed':
        message = 'この操作は許可されていません。';
        break;
      case 'requires-recent-login':
        message = '再度ログインしてからこの操作を行ってください。';
        break;
      default:
        message = 'エラーが発生しました: ${e.message}';
    }
    
    _setError(message);
  }
  
  // ローディング状態を設定
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  // エラーメッセージを設定
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
  
  // エラーメッセージをクリア
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}