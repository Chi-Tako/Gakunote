import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'app/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase初期化
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebaseの初期化に成功しました');
  } catch (e) {
    print('Firebaseの初期化に失敗しました: $e');
  }
  
  try {
    runApp(const AppProviders(
      child: GakunoteApp(),
    ));
  } catch (e) {
    print('アプリの実行中にエラーが発生しました: $e');
  }
}