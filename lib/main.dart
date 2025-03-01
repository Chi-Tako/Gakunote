import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'app/providers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'dart:io';
import 'package:path_provider/path_provider.dart'
    if (kIsWeb) 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Hive (local storage)
    Directory appDocumentDir;
    if (!kIsWeb) {
      appDocumentDir = await getApplicationDocumentsDirectory();
    } else {
      appDocumentDir = Directory('./'); // Web用の代替パス
    }
    await Hive.initFlutter(appDocumentDir.path);

    // Initialize Firebase (optional, with error handling)
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialization successful');
    } catch (e) {
      print('Firebase initialization failed: $e');
      print('Running in local mode');
    }

    // Register Hive adapters
    Hive.registerAdapter(NoteAdapter());

    runApp(const AppProviders(
      child: GakunoteApp(),
    ));
  } catch (e) {
    print('Application initialization error: $e');
    // Display a minimal UI in case of initialization failure
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Application initialization error: $e'),
        ),
      ),
    ));
  }
}