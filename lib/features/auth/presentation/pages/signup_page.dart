import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サインアップ'),
        // 戻るボタンを追加
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 明示的にログイン画面に戻る
            context.go('/login');
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
              'サインアップ画面',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // ここにサインアップフォームを追加（実装時に追加）
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('すでにアカウントをお持ちの方はこちら'),
            ),
          ],
        ),
      ),
    );
  }
}
