import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase初期化
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebaseの初期化に失敗しました: $e");
  }
  
  try {
    runApp(const GakunoteApp());
  } catch (e) {
    print("アプリの実行中にエラーが発生しました: $e");
  }
}
