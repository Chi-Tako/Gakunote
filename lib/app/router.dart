// app/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../features/notes/presentation/pages/notes_page.dart';
import '../features/notes/presentation/pages/note_detail_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../core/services/auth_service.dart';
import 'guards/auth_guard.dart';

GoRouter createAppRouter(BuildContext context) {
  final authService = Provider.of<AuthService>(context, listen: false);
  final authGuard = AuthGuard(authService);

  return GoRouter(
    initialLocation: '/notes',
    redirect: authGuard.protectedRouteGuard,
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
    // 以下を追加
    redirectLimit: 10, // リダイレクト制限
    debugLogDiagnostics: true, // デバッグログを有効化（開発時に便利）
  );
}