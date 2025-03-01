import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ノート詳細画面のAppBar
class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isEditing;
  final TextEditingController titleController;
  final FocusNode titleFocusNode;
  final VoidCallback onEditToggle;
  final VoidCallback onOptionsPressed;
  final bool showBackButton; // 戻るボタン表示フラグを追加

  const NoteAppBar({
    Key? key,
    required this.title,
    required this.isEditing,
    required this.titleController,
    required this.titleFocusNode,
    required this.onEditToggle,
    required this.onOptionsPressed,
    this.showBackButton = true, // デフォルトでは表示する
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // 編集中の場合は確認ダイアログを表示
                if (isEditing) {
                  _showUnsavedChangesDialog(context);
                } else {
                  // 安全に戻る処理
                  _safeGoBack(context);
                }
              },
            )
          : null,
      title: isEditing
          ? TextField(
              controller: titleController,
              focusNode: titleFocusNode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'タイトルを入力',
                hintStyle: TextStyle(color: Colors.white70),
              ),
            )
          : Text(title),
      actions: [
        IconButton(
          icon: Icon(isEditing ? Icons.check : Icons.edit),
          onPressed: onEditToggle,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: onOptionsPressed,
        ),
      ],
    );
  }

  // 安全に戻る処理
  void _safeGoBack(BuildContext context) {
    // CanPopスコープを使用して、バックナビゲーションが可能かチェック
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      // ナビゲーションスタックが空の場合は、明示的に特定のルートに遷移
      context.go('/notes');
    }
  }

  // 未保存の変更がある場合の確認ダイアログ
  void _showUnsavedChangesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('未保存の変更'),
        content: const Text('変更内容が保存されていません。このまま戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // ダイアログを閉じる
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ダイアログを閉じる
              _safeGoBack(context); // 安全な戻る処理を使用
            },
            child: const Text('破棄して戻る'),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
