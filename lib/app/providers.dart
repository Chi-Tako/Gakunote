import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/note_service.dart';

/// アプリケーションで使用するProviderを提供するためのクラス
class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // AuthServiceの提供
        ChangeNotifierProvider(
          create: (_) => AuthService()..initialize(),
        ),
        // NoteServiceの提供
        ChangeNotifierProxyProvider<AuthService, NoteService>(
          create: (_) => NoteService(),
          update: (_, authService, noteService) {
            // ユーザーがログインしている場合のみ初期化
            if (authService.isLoggedIn && noteService != null) {
              noteService.initialize();
              noteService.loadNotes();
              noteService.loadFavoriteNotes();
            }
            return noteService ?? NoteService();
          },
        ),
      ],
      child: child,
    );
  }
}