import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ログイン'),
        // 戻るボタンを追加
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 安全にノート一覧に戻る
            context.go('/notes');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'ログイン画面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // ここにログインフォームを追加（実装時に追加）
            TextButton(
              onPressed: () => context.go('/signup'),
              child: const Text('アカウントをお持ちでない方はこちら'),
            ),
          ],
        ),
      ),
    );
  }
}
