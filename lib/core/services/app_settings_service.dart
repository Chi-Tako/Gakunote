// lib/core/services/app_settings_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// アプリの設定を管理するサービス
class AppSettingsService extends ChangeNotifier {
  // 設定キー
  static const String _themeKey = 'themeMode';
  static const String _fontSizeKey = 'fontSize';
  static const String _useSansSerifKey = 'useSansSerif';
  static const String _enableAutoSaveKey = 'enableAutoSave';
  static const String _autoSaveIntervalKey = 'autoSaveInterval';
  static const String _showWordCountKey = 'showWordCount';
  
  // デフォルト値
  static const ThemeMode _defaultThemeMode = ThemeMode.system;
  static const double _defaultFontSize = 16.0;
  static const bool _defaultUseSansSerif = true;
  static const bool _defaultEnableAutoSave = true;
  static const int _defaultAutoSaveInterval = 30; // 秒
  static const bool _defaultShowWordCount = false;
  
  // フィールド
  late final SharedPreferences _prefs;
  ThemeMode _themeMode = _defaultThemeMode;
  double _fontSize = _defaultFontSize;
  bool _useSansSerif = _defaultUseSansSerif;
  bool _enableAutoSave = _defaultEnableAutoSave;
  int _autoSaveInterval = _defaultAutoSaveInterval;
  bool _showWordCount = _defaultShowWordCount;
  
  // ゲッター
  ThemeMode get themeMode => _themeMode;
  double get fontSize => _fontSize;
  bool get useSansSerif => _useSansSerif;
  bool get enableAutoSave => _enableAutoSave;
  int get autoSaveInterval => _autoSaveInterval;
  bool get showWordCount => _showWordCount;
  
  /// 初期化処理
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
  }
  
  /// 設定の読み込み
  void _loadSettings() {
    // テーマモード
    final themeModeIndex = _prefs.getInt(_themeKey);
    if (themeModeIndex != null) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }
    
    // フォントサイズ
    _fontSize = _prefs.getDouble(_fontSizeKey) ?? _defaultFontSize;
    
    // サンセリフフォント使用
    _useSansSerif = _prefs.getBool(_useSansSerifKey) ?? _defaultUseSansSerif;
    
    // 自動保存設定
    _enableAutoSave = _prefs.getBool(_enableAutoSaveKey) ?? _defaultEnableAutoSave;
    _autoSaveInterval = _prefs.getInt(_autoSaveIntervalKey) ?? _defaultAutoSaveInterval;
    
    // 単語数表示
    _showWordCount = _prefs.getBool(_showWordCountKey) ?? _defaultShowWordCount;
    
    notifyListeners();
  }
  
  /// テーマモードの設定
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setInt(_themeKey, mode.index);
      notifyListeners();
    }
  }
  
  /// フォントサイズの設定
  Future<void> setFontSize(double size) async {
    if (_fontSize != size) {
      _fontSize = size;
      await _prefs.setDouble(_fontSizeKey, size);
      notifyListeners();
    }
  }
  
  /// サンセリフフォント使用の設定
  Future<void> setUseSansSerif(bool use) async {
    if (_useSansSerif != use) {
      _useSansSerif = use;
      await _prefs.setBool(_useSansSerifKey, use);
      notifyListeners();
    }
  }
  
  /// 自動保存の設定
  Future<void> setEnableAutoSave(bool enable) async {
    if (_enableAutoSave != enable) {
      _enableAutoSave = enable;
      await _prefs.setBool(_enableAutoSaveKey, enable);
      notifyListeners();
    }
  }
  
  /// 自動保存間隔の設定
  Future<void> setAutoSaveInterval(int seconds) async {
    if (_autoSaveInterval != seconds) {
      _autoSaveInterval = seconds;
      await _prefs.setInt(_autoSaveIntervalKey, seconds);
      notifyListeners();
    }
  }
  
  /// 単語数表示の設定
  Future<void> setShowWordCount(bool show) async {
    if (_showWordCount != show) {
      _showWordCount = show;
      await _prefs.setBool(_showWordCountKey, show);
      notifyListeners();
    }
  }
  
  /// 設定をデフォルトにリセット
  Future<void> resetToDefaults() async {
    _themeMode = _defaultThemeMode;
    _fontSize = _defaultFontSize;
    _useSansSerif = _defaultUseSansSerif;
    _enableAutoSave = _defaultEnableAutoSave;
    _autoSaveInterval = _defaultAutoSaveInterval;
    _showWordCount = _defaultShowWordCount;
    
    await _prefs.remove(_themeKey);
    await _prefs.remove(_fontSizeKey);
    await _prefs.remove(_useSansSerifKey);
    await _prefs.remove(_enableAutoSaveKey);
    await _prefs.remove(_autoSaveIntervalKey);
    await _prefs.remove(_showWordCountKey);
    
    notifyListeners();
  }
  
  /// フォントサイズの変更
  Future<void> increaseFontSize() async {
    // 最大サイズを28.0にする
    if (_fontSize < 28.0) {
      await setFontSize(_fontSize + 1.0);
    }
  }
  
  Future<void> decreaseFontSize() async {
    // 最小サイズを10.0にする
    if (_fontSize > 10.0) {
      await setFontSize(_fontSize - 1.0);
    }
  }
}