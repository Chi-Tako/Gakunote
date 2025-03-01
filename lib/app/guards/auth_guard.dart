import 'package:go_router/go_router.dart';
import '../../core/services/auth_service.dart';

/// 認証状態に基づいて画面遷移を制御するガードクラス
class AuthGuard {
  final AuthService _authService;
  
  AuthGuard(this._authService);
  
  /// 認証が必要なルートへのアクセスを制御
  String? protectedRouteGuard(GoRouterState state) {
    // 認証が必要なパスのリスト
    final protectedPaths = [
      '/notes',
      '/notes/', // スラッシュ付きの場合も対応
      if (state.pathParameters.containsKey('id')) '/notes/${state.pathParameters['id']}',
      '/settings',
    ];
    
    // 現在のパス
    final path = state.matchedLocation;
    
    // 認証が必要なパスで、ログインしていない場合はログイン画面にリダイレクト
    if (protectedPaths.any((route) => path.startsWith(route)) && !_authService.isLoggedIn) {
      return '/login';
    }
    
    // 認証済みで、ログインやサインアップページにアクセスした場合はノート一覧にリダイレクト
    if (_authService.isLoggedIn && (path == '/login' || path == '/signup')) {
      return '/notes';
    }
    
    // リダイレクト不要の場合はnullを返す
    return null;
  }
}