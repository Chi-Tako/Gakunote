// app/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/notes/presentation/pages/notes_page.dart';
import '../features/notes/presentation/pages/note_detail_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';

/// アプリケーションのルーティングを設定
GoRouter createAppRouter() {
  return GoRouter(
    initialLocation: '/notes',
    routes: [
      // ノート一覧画面
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesPage(),
      ),
      // ノート詳細画面（編集画面）
      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final noteId = state.pathParameters['id']!;
          return NoteDetailPage(noteId: noteId);
        },
      ),
      // 設定画面
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      // ログイン画面
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      // サインアップ画面
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
    ],
    // エラーハンドリング
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('エラー')),
      body: Center(
        child: Text('ページが見つかりません: ${state.matchedLocation}'),
      ),
    ),
    // デバッグログを有効化（開発時に便利）
    debugLogDiagnostics: true,
  );
}