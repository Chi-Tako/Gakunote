// lib/features/settings/presentation/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:gakunote/core/services/subscription_service.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/app_settings_service.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/note_service.dart';
import '../../../../core/services/subscription_service.dart';
import '../../../shared/widgets/premium_feature_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appSettings = Provider.of<AppSettingsService>(context);
    final subscriptionService = Provider.of<SubscriptionService>(context);
    final authService = Provider.of<AuthService>(context);
    final noteService = Provider.of<NoteService>(context);
    
    // ユーザーがプレミアムかどうかをチェック（ストリームで監視）
    final isPremium = subscriptionService.currentTier == SubscriptionTier.premium;
    final isLoggedIn = authService.isLoggedIn;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        children: [
          // プレミアム会員セクション
          Card(
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isPremium
                  ? _buildPremiumUserSection(context, subscriptionService)
                  : _buildFreeTierSection(context),
            ),
          ),
          
          // アカウントセクション
          const ListTile(
            title: Text(
              'アカウント',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // ログイン/ログアウト
          isLoggedIn
              ? ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('ログアウト'),
                  subtitle: Text('現在のユーザー: ${authService.currentUser?.email ?? "不明"}'),
                  onTap: () => _showLogoutConfirmationDialog(context),
                )
              : ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('ログイン / 新規登録'),
                  subtitle: const Text('クラウド同期を使用するにはログインが必要です'),
                  onTap: () => _showLoginOptions(context),
                ),
          
          // クラウド同期
          SwitchListTile(
            title: const Text('クラウド同期'),
            subtitle: const Text('複数のデバイスでノートを同期します'),
            value: noteService.isCloudSyncEnabled,
            onChanged: isPremium && isLoggedIn
                ? (value) async {
                    await noteService.toggleCloudSync(value);
                  }
                : (value) async {
                    if (value) {
                      // プレミアム機能なので、購入を促す
                      await PremiumFeatureDialog.checkAccess(
                        context,
                        'cloud_sync',
                      );
                    }
                  },
          ),
          
          // 手動同期ボタン
          if (noteService.isCloudSyncEnabled)
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('手動同期'),
              subtitle: const Text('データを今すぐ同期します'),
              onTap: () async {
                // ローディングを表示
                _showSyncingDialog(context);
                
                try {
                  await noteService.syncWithCloud();
                  
                  // 完了メッセージ
                  if (context.mounted) {
                    Navigator.pop(context); // ローディングダイアログを閉じる
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('同期が完了しました'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  // エラーメッセージ
                  if (context.mounted) {
                    Navigator.pop(context); // ローディングダイアログを閉じる
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('同期中にエラーが発生しました: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          
          const Divider(),
          
          // 表示設定
          const ListTile(
            title: Text(
              '表示設定',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // テーマ選択
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('テーマ'),
            subtitle: Text(_getThemeModeName(appSettings.themeMode)),
            onTap: () => _showThemeSelector(context, appSettings),
          ),
          
          // フォントサイズ
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('フォントサイズ'),
            subtitle: Text('${appSettings.fontSize.toInt()}px'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => appSettings.decreaseFontSize(),
                ),
                Text(
                  appSettings.fontSize.toInt().toString(),
                  style: const TextStyle(fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => appSettings.increaseFontSize(),
                ),
              ],
            ),
          ),
          
          // サンセリフフォント使用
          SwitchListTile(
            title: const Text('サンセリフフォント'),
            subtitle: const Text('使用しない場合はセリフフォント（明朝体など）を使用します'),
            value: appSettings.useSansSerif,
            onChanged: (value) => appSettings.setUseSansSerif(value),
          ),
          
          const Divider(),
          
          // 編集設定
          const ListTile(
            title: Text(
              '編集設定',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // 自動保存
          SwitchListTile(
            title: const Text('自動保存'),
            subtitle: const Text('編集内容を自動的に保存します'),
            value: appSettings.enableAutoSave,
            onChanged: (value) => appSettings.setEnableAutoSave(value),
          ),
          
          // 自動保存間隔
          if (appSettings.enableAutoSave)
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('自動保存間隔'),
              subtitle: Text('${appSettings.autoSaveInterval}秒'),
              onTap: () => _showAutoSaveIntervalSelector(context, appSettings),
            ),
          
          // 単語数表示
          SwitchListTile(
            title: const Text('単語数表示'),
            subtitle: const Text('編集画面に単語数を表示します'),
            value: appSettings.showWordCount,
            onChanged: (value) => appSettings.setShowWordCount(value),
          ),
          
          const Divider(),
          
          // その他
          const ListTile(
            title: Text(
              'その他',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          
          // データのエクスポート
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('データをエクスポート'),
            onTap: () => _exportData(context, noteService),
          ),
          
          // データのインポート
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('データをインポート'),
            onTap: () => _importData(context, noteService),
          ),
          
          // 設定をリセット
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('設定をリセット'),
            onTap: () => _showResetSettingsConfirmation(context, appSettings),
          ),
          
          // バージョン情報
          const ListTile(
            leading: Icon(Icons.info),
            title: Text('バージョン情報'),
            subtitle: Text('Gakunote v1.0.0'),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }
  
  // プレミアムユーザーセクションを表示
  Widget _buildPremiumUserSection(BuildContext context, SubscriptionService subscriptionService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.star,
              color: Color(0xFFF57C00),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              'プレミアム会員',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '有効期限: ${_formatExpiryDate(subscriptionService.subscriptionExpiry)}',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Text(
          'すべての機能を利用できます。ありがとうございます！',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _showCancelSubscriptionConfirmation(context, subscriptionService),
          child: const Text('サブスクリプションをキャンセル'),
        ),
      ],
    );
  }
  
  // 無料ユーザーセクションを表示
  Widget _buildFreeTierSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.star_border,
              color: Color(0xFFF57C00),
              size: 24,
            ),
            SizedBox(width: 8),
            Text(
              '無料プラン',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'プレミアムにアップグレードして、クラウド同期や高度な機能をお使いいただけます。',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => _showSubscriptionOptions(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A73E8),
            foregroundColor: Colors.white,
          ),
          child: const Text('プレミアムを購入'),
        ),
      ],
    );
  }
  
  // 有効期限をフォーマット
  String _formatExpiryDate(DateTime? date) {
    if (date == null) {
      return '不明';
    }
    
    return '${date.year}年${date.month}月${date.day}日';
  }
  
  // テーマモード名を取得
  String _getThemeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'システム設定に合わせる';
      case ThemeMode.light:
        return 'ライトモード';
      case ThemeMode.dark:
        return 'ダークモード';
    }
  }
  
  // テーマ選択ダイアログを表示
  void _showThemeSelector(BuildContext context, AppSettingsService appSettings) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('テーマを選択'),
        children: [
          _buildThemeOption(
            context,
            'システム設定に合わせる',
            ThemeMode.system,
            appSettings,
          ),
          _buildThemeOption(
            context,
            'ライトモード',
            ThemeMode.light,
            appSettings,
          ),
          _buildThemeOption(
            context,
            'ダークモード',
            ThemeMode.dark,
            appSettings,
          ),
        ],
      ),
    );
  }
  
  // テーマオプションを構築
  Widget _buildThemeOption(
    BuildContext context,
    String title,
    ThemeMode mode,
    AppSettingsService appSettings,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        appSettings.setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              appSettings.themeMode == mode
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Text(title),
          ],
        ),
      ),
    );
  }
  
  // 自動保存間隔選択ダイアログを表示
  void _showAutoSaveIntervalSelector(BuildContext context, AppSettingsService appSettings) {
    final currentInterval = appSettings.autoSaveInterval;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自動保存間隔'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('編集内容を自動保存する間隔を選択してください'),
            const SizedBox(height: 16),
            Slider(
              value: currentInterval.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$currentInterval秒',
              onChanged: (value) {
                appSettings.setAutoSaveInterval(value.toInt());
              },
            ),
            Text(
              '${appSettings.autoSaveInterval}秒',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // ログアウト確認ダイアログを表示
  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text(
          'ログアウトしますか？ローカルのデータは保持されますが、クラウド同期は無効になります。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              // ログアウト処理
              final authService = Provider.of<AuthService>(context, listen: false);
              final noteService = Provider.of<NoteService>(context, listen: false);
              
              // クラウド同期を無効に
              noteService.toggleCloudSync(false);
              
              // ログアウト
              authService.signOut();
              
              Navigator.pop(context);
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }
  
  // ログインオプションを表示
  void _showLoginOptions(BuildContext context) {
    // ログイン/サインアップページに遷移
    Navigator.pushNamed(context, '/login');
  }
  
  // サブスクリプションオプションを表示
  void _showSubscriptionOptions(BuildContext context) {
    // プレミアム機能ダイアログから購入画面を表示
    PremiumFeatureDialog.checkAccess(
      context,
      'premium',
      featureName: 'プレミアムプラン',
      description: 'プレミアムプランでは、クラウド同期や高度な機能をご利用いただけます。',
    );
  }
  
  // サブスクリプションキャンセル確認ダイアログを表示
  void _showCancelSubscriptionConfirmation(BuildContext context, SubscriptionService subscriptionService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('サブスクリプションをキャンセル'),
        content: const Text(
          'サブスクリプションをキャンセルしますか？有効期限まではプレミアム機能を引き続き利用できます。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('いいえ'),
          ),
          TextButton(
            onPressed: () async {
              // キャンセル処理
              final success = await subscriptionService.cancelSubscription();
              
              // ダイアログを閉じる
              if (context.mounted) {
                Navigator.pop(context);
                
                // 結果を表示
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'サブスクリプションをキャンセルしました'
                          : 'キャンセルに失敗しました',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('はい'),
          ),
        ],
      ),
    );
  }
  
  // 設定リセット確認ダイアログを表示
  void _showResetSettingsConfirmation(BuildContext context, AppSettingsService appSettings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定をリセット'),
        content: const Text('すべての設定をデフォルトにリセットしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              appSettings.resetToDefaults();
              Navigator.pop(context);
              
              // 結果を表示
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('設定をリセットしました'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('リセット'),
          ),
        ],
      ),
    );
  }
  
  // データエクスポート処理
  void _exportData(BuildContext context, NoteService noteService) {
    // 実際のアプリでは、ファイル選択ダイアログなどを表示して
    // ユーザーが保存先を選択できるようにする
    
    // ここではデモとして簡単なダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データのエクスポート'),
        content: const Text(
          'この機能はデモ版では利用できません。実際のアプリでは、データをJSON形式でエクスポートし、'
          'ファイルとして保存できるようになります。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // データインポート処理
  void _importData(BuildContext context, NoteService noteService) {
    // 実際のアプリでは、ファイル選択ダイアログなどを表示して
    // ユーザーがインポートするファイルを選択できるようにする
    
    // ここではデモとして簡単なダイアログを表示
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('データのインポート'),
        content: const Text(
          'この機能はデモ版では利用できません。実際のアプリでは、JSON形式のデータをインポートし、'
          '現在のデータと統合できるようになります。'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
  // 同期中ダイアログを表示
  void _showSyncingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 24),
            Text('同期中...'),
          ],
        ),
      ),
    );
  }
}