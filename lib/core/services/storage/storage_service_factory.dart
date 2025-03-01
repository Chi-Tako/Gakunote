// lib/core/services/storage/storage_service_factory.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'storage_service.dart';
import 'local_storage_service.dart';
import 'cloud_storage_service.dart';
import '../subscription_service.dart';
import '../../models/note.dart';

/// ユーザーの状態に応じたストレージサービスを提供するファクトリー
class StorageServiceFactory {
  final SubscriptionService _subscriptionService;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // シングルトンインスタンス
  static final StorageServiceFactory _instance = StorageServiceFactory._internal();

  // キャッシュしたサービスインスタンス
  final LocalStorageService _localStorageService = LocalStorageService();
  CloudStorageService? _cloudStorageService;

  // 現在のモード
  bool _useCloudStorage = false;

  // プライベートコンストラクタ
  StorageServiceFactory._internal() : _subscriptionService = SubscriptionService();

  // ファクトリコンストラクタ
  factory StorageServiceFactory() {
    return _instance;
  }

  /// 初期化処理
  Future<void> initialize() async {
    // ローカルストレージの初期化
    await _localStorageService.initialize();

    // サブスクリプションサービスの初期化
    await _subscriptionService.initialize();

    // 現在のモードを決定
    _useCloudStorage = await _shouldUseCloudStorage();

    // クラウドモードが有効で、ユーザーがログインしている場合はクラウドストレージを初期化
    if (_useCloudStorage && _auth.currentUser != null) {
      _cloudStorageService = CloudStorageService();
      await _cloudStorageService!.initialize();
    }
  }

  /// 適切なストレージサービスを取得
  StorageService getStorageService() {
    if (_useCloudStorage && _cloudStorageService != null) {
      return _cloudStorageService!;
    }
    return _localStorageService;
  }

  /// ローカルストレージサービスを取得
  LocalStorageService getLocalStorageService() {
    return _localStorageService;
  }

  /// クラウドストレージサービスを取得（存在しない場合は新規作成）
  Future<CloudStorageService?> getCloudStorageService() async {
    if (_auth.currentUser == null) {
      return null;
    }

    if (_cloudStorageService == null) {
      _cloudStorageService = CloudStorageService();
      await _cloudStorageService!.initialize();
    }

    return _cloudStorageService;
  }

  /// クラウドストレージを使用すべきかを判断
  Future<bool> _shouldUseCloudStorage() async {
    // ユーザーがプレミアムプランに加入しているか
    final isPremium = await _subscriptionService.isPremiumUser();

    // ユーザーがログインしているか
    final isLoggedIn = _auth.currentUser != null;

    // ユーザー設定でクラウド同期が有効になっているか
    // ローカルストレージから設定を直接取得する
    final cloudSyncNote = await _localStorageService.getNoteById('cloudSyncEnabled');
    final cloudSyncEnabled = cloudSyncNote?.content == 'true';

    return isPremium && isLoggedIn && cloudSyncEnabled;
  }

  /// ストレージモードを切り替え
  /// このメソッドは課金状態が変わった時や、ユーザーがログインした時に呼び出される
  Future<void> updateStorageMode() async {
    final shouldUseCloud = await _shouldUseCloudStorage();

    if (shouldUseCloud != _useCloudStorage) {
      _useCloudStorage = shouldUseCloud;

      if (_useCloudStorage) {
        if (_cloudStorageService == null) {
          _cloudStorageService = CloudStorageService();
          await _cloudStorageService!.initialize();
        }

        // クラウド同期を有効にした場合は、ローカルデータをクラウドに同期
        await syncData();
      }
    }
  }

  /// クラウドとローカルのデータを同期
  Future<void> syncData() async {
    if (_cloudStorageService != null) {
      await _cloudStorageService!.syncWithLocalStorage(_localStorageService);
    }
  }

  /// クラウド同期の有効/無効を切り替え
  Future<void> setCloudSyncEnabled(bool enabled) async {
    // ローカルストレージに設定を直接保存する
    await _localStorageService.saveNote(Note(id: 'cloudSyncEnabled', title: '', content: enabled.toString()));
    await updateStorageMode();
  }

  /// クラウド同期が有効かどうか
  bool get isCloudSyncEnabled => _useCloudStorage;

  /// 現在のストレージタイプ
  String get currentStorageType => _useCloudStorage ? 'cloud' : 'local';
}