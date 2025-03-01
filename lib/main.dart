// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'app/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Hive初期化（ローカルストレージ用）
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  
  // Firebase初期化（オプション）
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebaseの初期化に成功しました');
  } catch (e) {
    // Firebaseの初期化に失敗してもアプリは起動できるようにする
    print('Firebaseの初期化に失敗しました: $e');
    print('ローカルモードで起動します');
  }
  
  try {
    runApp(const AppProviders(
      child: GakunoteApp(),
    ));
  } catch (e) {
    print('アプリの実行中にエラーが発生しました: $e');
  }
}