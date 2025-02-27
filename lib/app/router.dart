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
  // リダイレクト処理（認証状態に応じて）
  // 認証機能が実装されるまでコメントアウト
  /*
  redirect: (context, state) {
    final isLoggedIn = false; // 認証状態の確認（後で実装）
    final isAuthRoute = state.fullPath == '/login' || state.fullPath == '/signup';
    
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }
    
    if (isLoggedIn && isAuthRoute) {
      return '/notes';
    }
    
    return null;
  },
  */
);
