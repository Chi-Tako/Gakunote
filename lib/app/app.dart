import 'package:flutter/material.dart';
import 'theme.dart';
import 'router.dart';

class GakunoteApp extends StatelessWidget {
  const GakunoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gakunote',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}