// lib/app/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'router.dart';
import '../core/services/app_settings_service.dart';

class GakunoteApp extends StatelessWidget {
  const GakunoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // アプリ設定サービスからテーマモードを取得
    final appSettings = Provider.of<AppSettingsService>(context);
    final themeMode = appSettings.themeMode;
    
    // ルーターを作成
    final router = createAppRouter();
    
    return MaterialApp.router(
      title: 'Gakunote',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}