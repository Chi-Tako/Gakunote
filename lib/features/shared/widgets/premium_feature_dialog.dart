// lib/features/shared/widgets/premium_feature_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/subscription_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// プレミアム機能を使用しようとした時に表示するダイアログ
class PremiumFeatureDialog extends StatelessWidget {
  final String featureName;
  final String description;
  final VoidCallback? onClose;
  
  const PremiumFeatureDialog({
    Key? key,
    required this.featureName,
    required this.description,
    this.onClose,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 36,
              backgroundColor: Color(0xFFF57C00),
              child: Icon(
                Icons.star,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'プレミアム機能',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '「$featureName」はプレミアム会員限定の機能です',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSubscriptionOptions(context);
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                backgroundColor: const Color(0xFF1A73E8),
              ),
              child: const Text(
                'プレミアムを購入',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (onClose != null) {
                  onClose!();
                }
              },
              child: const Text('キャンセル'),
            ),
          ],
        ),
      ),
    );
  }
  
  // サブスクリプションの選択画面を表示
  void _showSubscriptionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _SubscriptionOptionsSheet(),
    );
  }
  
  // プレミアム機能へのアクセスを試みたときに表示するヘルパーメソッド
  static Future<bool> checkAccess(
    BuildContext context,
    String featureId, {
    String? featureName,
    String? description,
  }) async {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    // 機能を使用できるかチェック
    final canUse = await subscriptionService.canUseFeature(featureId);
    if (canUse) {
      return true;
    }
    
    // 使用できない場合はダイアログ表示
    if (context.mounted) {
      await showDialog(
        context: context,
        builder: (context) => PremiumFeatureDialog(
          featureName: featureName ?? _getFeatureName(featureId),
          description: description ?? _getFeatureDescription(featureId),
        ),
      );
    }
    
    return false;
  }
  
  // 機能IDから機能名を取得
  static String _getFeatureName(String featureId) {
    switch (featureId) {
      case 'cloud_sync':
        return 'クラウド同期';
      case 'advanced_math':
        return '高度な数式エディタ';
      case 'handwriting_recognition':
        return '手書き認識';
      case 'pdf_export':
        return 'PDF書き出し';
      case 'custom_themes':
        return 'カスタムテーマ';
      default:
        return 'プレミアム機能';
    }
  }
  
  // 機能IDから機能説明を取得
  static String _getFeatureDescription(String featureId) {
    switch (featureId) {
      case 'cloud_sync':
        return 'クラウド同期を使用すると、複数のデバイス間でノートを同期できます。また、万が一の時のバックアップとしても機能します。';
      case 'advanced_math':
        return '高度な数式エディタを使用すると、より複雑な数式や図形を作成することができます。';
      case 'handwriting_recognition':
        return '手書き認識機能を使用すると、手書きのノートをテキストに変換することができます。';
      case 'pdf_export':
        return 'ノートをPDF形式で書き出すことができます。レポートや論文の提出にも便利です。';
      case 'custom_themes':
        return 'アプリのテーマをカスタマイズできます。お好みの色や配色にして、より快適にノートが取れます。';
      default:
        return 'プレミアム会員になると、より多くの高度な機能を使用できるようになります。';
    }
  }
}

/// サブスクリプション選択のボトムシート
class _SubscriptionOptionsSheet extends StatelessWidget {
  const _SubscriptionOptionsSheet();
  
  @override
  Widget build(BuildContext context) {
    final subscriptionService = Provider.of<SubscriptionService>(context);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'プレミアムプラン',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'すべての機能を利用して、より快適にノートを取りましょう',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // プラン選択
          _SubscriptionPlanCard(
            title: '1ヶ月プラン',
            price: '¥480 / 月',
            isPopular: false,
            onTap: () => _purchaseSubscription(context, 1),
          ),
          const SizedBox(height: 12),
          _SubscriptionPlanCard(
            title: '1年プラン',
            price: '¥4,800 / 年',
            description: '(¥400 / 月 相当)',
            isPopular: true,
            onTap: () => _purchaseSubscription(context, 12),
          ),
          const SizedBox(height: 16),
          
          // 機能一覧
          const _FeatureList(),
          const SizedBox(height: 16),
          
          // プライバシーポリシーなど
          const Text(
            'お支払いは Apple/Google アカウントに請求されます。定期購入は自動的に更新されますが、いつでもキャンセルできます。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // 復元ボタン
          TextButton(
            onPressed: () async {
              await subscriptionService.restorePurchases();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('購入を復元'),
          ),
          
          // デバッグ用
          if (kDebugMode) ...[
            const Divider(),
            TextButton(
              onPressed: () async {
                await subscriptionService.togglePremiumForTesting();
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text('テスト用：プレミアム状態を切り替え'),
            ),
          ],
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  // サブスクリプション購入処理
  Future<void> _purchaseSubscription(BuildContext context, int months) async {
    final subscriptionService = Provider.of<SubscriptionService>(context, listen: false);
    
    // 購入処理
    final success = await subscriptionService.purchasePremium(months: months);
    
    // 購入成功時はダイアログを閉じる
    if (success && context.mounted) {
      Navigator.pop(context);
      
      // 購入完了メッセージ
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('プレミアムプランの購入が完了しました。'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

/// サブスクリプションプランカード
class _SubscriptionPlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String? description;
  final bool isPopular;
  final VoidCallback onTap;

  const _SubscriptionPlanCard({
    required this.title,
    required this.price,
    this.description,
    required this.isPopular,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPopular
            ? const BorderSide(color: Color(0xFF1A73E8), width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (description != null)
                      Text(
                        description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A73E8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'おすすめ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// プレミアム機能リスト
class _FeatureList extends StatelessWidget {
  const _FeatureList();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'プレミアム特典',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildFeatureItem('クラウド同期（複数デバイス対応）'),
        _buildFeatureItem('高度な数式エディタ'),
        _buildFeatureItem('手書き認識機能'),
        _buildFeatureItem('PDF書き出し'),
        _buildFeatureItem('カスタムテーマ'),
        _buildFeatureItem('広告表示なし'),
      ],
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF1A73E8),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }
}