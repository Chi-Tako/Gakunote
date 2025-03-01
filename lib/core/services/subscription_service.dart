// lib/core/services/subscription_service.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage/local_storage_service.dart';

/// 有料機能とサブスクリプション管理を行うサービス
class SubscriptionService extends ChangeNotifier {
  // 定数
  static const String _premiumStatusKey = 'isPremiumUser';
  static const String _subscriptionExpiryKey = 'subscriptionExpiry';
  static const String _subscriptionIdKey = 'subscriptionId';
  static const String _purchaseDateKey = 'purchaseDate';
  static const String _subscriptionTypeKey = 'subscriptionType';
  
  // フィールド
  bool _isPremium = false;
  DateTime? _subscriptionExpiry;
  String? _subscriptionId;
  DateTime? _purchaseDate;
  SubscriptionType _subscriptionType = SubscriptionType.none;
  
  // ローカルストレージサービス
  final LocalStorageService _localStorageService = LocalStorageService();
  
  // Firebase関連
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;
  
  // ゲッター
  bool get isPremium => _isPremium;
  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  String? get subscriptionId => _subscriptionId;
  DateTime? get purchaseDate => _purchaseDate;
  SubscriptionType get subscriptionType => _subscriptionType;
  SubscriptionTier get currentTier => _isPremium ? SubscriptionTier.premium : SubscriptionTier.free;
  bool get isInitialized => _isInitialized;
  
  /// 初期化処理
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // ストレージサービスの初期化
      await _localStorageService.initialize();
      
      // サブスクリプション状態の読み込み
      await _loadSubscriptionStatus();
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('SubscriptionServiceの初期化に失敗しました: $e');
    }
  }
  
  /// サブスクリプション状態の読み込み
  Future<void> _loadSubscriptionStatus() async {
    try {
      // ローカルからサブスクリプション状態を読み込む
      _isPremium = _localStorageService.getSetting(_premiumStatusKey, defaultValue: false);
      
      // サブスクリプション有効期限
      final expiryStr = _localStorageService.getSetting(_subscriptionExpiryKey);
      if (expiryStr != null) {
        try {
          _subscriptionExpiry = DateTime.parse(expiryStr);
        } catch (e) {
          _subscriptionExpiry = null;
        }
      }
      
      // サブスクリプションID
      _subscriptionId = _localStorageService.getSetting(_subscriptionIdKey);
      
      // 購入日
      final purchaseDateStr = _localStorageService.getSetting(_purchaseDateKey);
      if (purchaseDateStr != null) {
        try {
          _purchaseDate = DateTime.parse(purchaseDateStr);
        } catch (e) {
          _purchaseDate = null;
        }
      }
      
      // サブスクリプションタイプ
      final subscriptionTypeInt = _localStorageService.getSetting(_subscriptionTypeKey, defaultValue: 0);
      _subscriptionType = SubscriptionType.values[subscriptionTypeInt];
      
      // 有効期限が切れている場合は無料プランに戻す
      if (_subscriptionExpiry != null && _subscriptionExpiry!.isBefore(DateTime.now())) {
        _isPremium = false;
        _subscriptionExpiry = null;
        _subscriptionType = SubscriptionType.none;
        await _saveSubscriptionStatus();
      }
      
      // ログインしている場合はクラウドから最新情報を取得
      await _syncWithCloud();
      
      notifyListeners();
    } catch (e) {
      debugPrint('サブスクリプション状態の読み込みに失敗しました: $e');
    }
  }
  
  /// クラウドからサブスクリプション情報を取得してローカルと同期
  Future<void> _syncWithCloud() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      // ユーザーのサブスクリプション情報をFirestoreから取得
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // クラウドのサブスクリプション情報で上書き
          final cloudIsPremium = data['isPremium'] ?? false;
          final cloudExpiryDate = data['expiryDate'] != null 
              ? (data['expiryDate'] as Timestamp).toDate() 
              : null;
          final cloudSubscriptionId = data['subscriptionId'] as String?;
          final cloudPurchaseDate = data['purchaseDate'] != null 
              ? (data['purchaseDate'] as Timestamp).toDate() 
              : null;
          final cloudSubscriptionTypeInt = data['subscriptionType'] ?? 0;
          
          // ローカルの方が新しい場合はクラウドを更新
          if (_subscriptionExpiry != null && cloudExpiryDate != null && 
              _subscriptionExpiry!.isAfter(cloudExpiryDate)) {
            await _updateCloudSubscription();
          } else {
            // クラウドの方が新しい場合はローカルを更新
            _isPremium = cloudIsPremium;
            _subscriptionExpiry = cloudExpiryDate;
            _subscriptionId = cloudSubscriptionId;
            _purchaseDate = cloudPurchaseDate;
            _subscriptionType = SubscriptionType.values[cloudSubscriptionTypeInt];
            
            // ローカルに保存
            await _saveSubscriptionStatus();
          }
        }
      } else {
        // クラウドに情報がない場合はローカル情報をアップロード
        if (_isPremium) {
          await _updateCloudSubscription();
        }
      }
    } catch (e) {
      debugPrint('クラウドとの同期に失敗しました: $e');
    }
  }
  
  /// クラウドのサブスクリプション情報を更新
  Future<void> _updateCloudSubscription() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('subscription')
          .doc('current')
          .set({
        'isPremium': _isPremium,
        'expiryDate': _subscriptionExpiry,
        'subscriptionId': _subscriptionId,
        'purchaseDate': _purchaseDate,
        'subscriptionType': _subscriptionType.index,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('クラウドの更新に失敗しました: $e');
    }
  }
  
  /// サブスクリプション状態の保存
  Future<void> _saveSubscriptionStatus() async {
    await _localStorageService.setSetting(_premiumStatusKey, _isPremium);
    
    if (_subscriptionExpiry != null) {
      await _localStorageService.setSetting(
        _subscriptionExpiryKey, 
        _subscriptionExpiry!.toIso8601String()
      );
    } else {
      await _localStorageService.setSetting(_subscriptionExpiryKey, null);
    }
    
    await _localStorageService.setSetting(_subscriptionIdKey, _subscriptionId);
    
    if (_purchaseDate != null) {
      await _localStorageService.setSetting(
        _purchaseDateKey, 
        _purchaseDate!.toIso8601String()
      );
    } else {
      await _localStorageService.setSetting(_purchaseDateKey, null);
    }
    
    await _localStorageService.setSetting(_subscriptionTypeKey, _subscriptionType.index);
  }
  
  /// プレミアムユーザーかどうか
  Future<bool> isPremiumUser() async {
    // 最新の状態を読み込む
    if (!_isInitialized) {
      await initialize();
    }
    return _isPremium;
  }
  
  /// サブスクリプションを購入
  /// 実際のアプリでは課金APIと連携する必要あり
  Future<bool> purchasePremium({int months = 1}) async {
    try {
      // 初期化されていない場合は初期化
      if (!_isInitialized) {
        await initialize();
      }
      
      // 実際のアプリでは、ここで課金APIを呼び出す
      // 例: final purchaseResult = await InAppPurchase.instance.buyNonConsumable(...);
      
      // 購入成功とする（実際には課金APIの結果による）
      _isPremium = true;
      
      // サブスクリプションタイプを設定
      _subscriptionType = months == 12 ? SubscriptionType.yearly : SubscriptionType.monthly;
      
      // 購入日を設定
      _purchaseDate = DateTime.now();
      
      // 有効期限を設定
      final now = DateTime.now();
      _subscriptionExpiry = DateTime(now.year, now.month + months, now.day);
      
      // サブスクリプションIDを生成（実際には課金APIから取得）
      _subscriptionId = 'sub_${DateTime.now().millisecondsSinceEpoch}';
      
      // 状態を保存
      await _saveSubscriptionStatus();
      
      // クラウドにも保存
      await _updateCloudSubscription();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('購入処理エラー: $e');
      return false;
    }
  }
  
  /// サブスクリプションをキャンセル
  /// 実際のアプリでは課金APIと連携する必要あり
  Future<bool> cancelSubscription() async {
    try {
      // 初期化されていない場合は初期化
      if (!_isInitialized) {
        await initialize();
      }
      
      // 実際のアプリでは、ここで課金APIを呼び出す
      // 例: final result = await InAppPurchase.instance.finishTransaction(...);
      
      // キャンセル成功とする（実際には課金APIの結果による）
      // 注意: 有料期間が終了するまではプレミアム状態を維持
      // ここでは即時キャンセルのデモとして実装
      _isPremium = false;
      _subscriptionExpiry = null;
      _subscriptionType = SubscriptionType.none;
      
      // 状態を保存
      await _saveSubscriptionStatus();
      
      // クラウドにも保存
      await _updateCloudSubscription();
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('サブスクリプションキャンセルエラー: $e');
      return false;
    }
  }
  
  /// サブスクリプションを復元
  /// 実際のアプリでは課金APIと連携する必要あり
  Future<bool> restorePurchases() async {
    try {
      // 初期化されていない場合は初期化
      if (!_isInitialized) {
        await initialize();
      }
      
      // 実際のアプリでは、ここで課金APIを呼び出す
      // 例: final purchases = await InAppPurchase.instance.queryPastPurchases();
      
      // ログインしている場合はクラウドから同期
      if (_auth.currentUser != null) {
        await _syncWithCloud();
      } else {
        // デモとして、ここでは前回の状態を復元する
        await _loadSubscriptionStatus();
      }
      
      notifyListeners();
      return _isPremium; // 復元できたかどうかを返す
    } catch (e) {
      debugPrint('購入復元エラー: $e');
      return false;
    }
  }
  
  /// テスト用：プレミアム状態を切り替え
  Future<void> togglePremiumForTesting() async {
    // 初期化されていない場合は初期化
    if (!_isInitialized) {
      await initialize();
    }
    
    _isPremium = !_isPremium;
    
    if (_isPremium) {
      // サブスクリプションタイプを月額に設定
      _subscriptionType = SubscriptionType.monthly;
      
      // 購入日を設定
      _purchaseDate = DateTime.now();
      
      // 有効期限を1ヶ月後に設定
      final now = DateTime.now();
      _subscriptionExpiry = DateTime(now.year, now.month + 1, now.day);
      
      // サブスクリプションIDを生成
      _subscriptionId = 'test_${DateTime.now().millisecondsSinceEpoch}';
    } else {
      _subscriptionExpiry = null;
      _subscriptionId = null;
      _purchaseDate = null;
      _subscriptionType = SubscriptionType.none;
    }
    
    await _saveSubscriptionStatus();
    await _updateCloudSubscription();
    notifyListeners();
  }
  
  /// 特定の機能がプレミアム機能かどうかチェック
  bool isFeaturePremium(String featureId) {
    // プレミアム機能のリスト
    const premiumFeatures = [
      'cloud_sync',
      'advanced_math',
      'handwriting_recognition',
      'pdf_export',
      'custom_themes',
      'premium', // プレミアム全体を表す特別なID
    ];
    
    return premiumFeatures.contains(featureId);
  }
  
  /// 特定の機能を使用できるかどうかチェック
  Future<bool> canUseFeature(String featureId) async {
    // プレミアム機能でなければ、誰でも使用可能
    if (!isFeaturePremium(featureId)) {
      return true;
    }
    
    // プレミアム機能の場合は、プレミアムユーザーのみ使用可能
    return await isPremiumUser();
  }
  
  /// サブスクリプション情報の文字列表現
  String getSubscriptionInfoText() {
    if (!_isPremium) {
      return '無料プラン';
    }
    
    String planType;
    switch (_subscriptionType) {
      case SubscriptionType.monthly:
        planType = '月額プラン';
        break;
      case SubscriptionType.yearly:
        planType = '年額プラン';
        break;
      default:
        planType = 'プレミアムプラン';
    }
    
    String expiryText = '';
    if (_subscriptionExpiry != null) {
      expiryText = '（${_subscriptionExpiry!.year}年${_subscriptionExpiry!.month}月${_subscriptionExpiry!.day}日まで）';
    }
    
    return '$planType$expiryText';
  }
  
  /// ユーザーが利用できる機能のリストを取得
  List<String> getAvailableFeatures() {
    final features = <String>[
      'basic_notes',     // 基本的なノート機能
      'markdown',        // マークダウン
      'basic_math',      // 基本的な数式
      'tags',            // タグ付け
      'search',          // 検索機能
      'export_text',     // テキスト書き出し
    ];
    
    // プレミアムユーザーの場合は、プレミアム機能も追加
    if (_isPremium) {
      features.addAll([
        'cloud_sync',
        'advanced_math',
        'handwriting_recognition',
        'pdf_export',
        'custom_themes',
      ]);
    }
    
    return features;
  }
  
  /// プレミアム特典の説明文を取得
  List<String> getPremiumBenefits() {
    return [
      'クラウド同期（複数デバイス対応）',
      '高度な数式エディタ',
      '手書き認識機能',
      'PDF書き出し',
      'カスタムテーマ',
      '広告表示なし',
    ];
  }
  
  /// プランの価格情報を取得
  Map<String, dynamic> getPricingInfo() {
    return {
      'monthly': {
        'price': 480,
        'currency': 'JPY',
        'display': '¥480 / 月',
        'productId': 'premium_monthly',
      },
      'yearly': {
        'price': 4800,
        'currency': 'JPY',
        'display': '¥4,800 / 年',
        'monthly_equivalent': '¥400 / 月 相当',
        'productId': 'premium_yearly',
        'save_percent': 16, // 月額と比較した節約率
      },
    };
  }
}

// サブスクリプションの種類
enum SubscriptionTier {
  free,     // 無料プラン
  premium,  // プレミアムプラン
}

// サブスクリプションタイプ
enum SubscriptionType {
  none,     // 未契約
  monthly,  // 月額
  yearly,   // 年額
}