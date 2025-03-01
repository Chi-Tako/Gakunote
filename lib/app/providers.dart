// lib/app/providers.dart
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../core/services/auth_service.dart';
import '../core/services/note_service.dart';
import '../core/services/app_settings_service.dart';
import '../core/services/subscription_service.dart';

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
        // アプリ設定のプロバイダー
        ChangeNotifierProvider(
          create: (_) => AppSettingsService()..initialize(),
        ),
        
        // サブスクリプションサービスのプロバイダー
        ChangeNotifierProvider(
          create: (_) => SubscriptionService()..initialize(),
        ),
        
        // 認証サービスのプロバイダー
        ChangeNotifierProvider(
          create: (_) => AuthService()..initialize(),
        ),
        
        // ノートサービスのプロバイダー
        ChangeNotifierProvider(
          create: (_) => NoteService()..initialize(),
          lazy: false, // アプリ起動時に即座に初期化
        ),
      ],
      child: child,
    );
  }
}