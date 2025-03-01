import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'router.dart';

class GakunoteApp extends StatelessWidget {
  const GakunoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // createAppRouter を使用してルーターを作成
    final router = createAppRouter(context);
    
    return MaterialApp.router(
      title: 'Gakunote',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}