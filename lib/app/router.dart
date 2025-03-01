// app/router.dart
import 'package:go_router/go_router.dart';
import '../features/notes/presentation/pages/notes_page.dart';
import '../features/notes/presentation/pages/note_detail_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';

final appRouter = GoRouter(
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
  // 以下を追加
  redirectLimit: 10, // リダイレクト制限
  debugLogDiagnostics: true, // デバッグログを有効化（開発時に便利）
);
