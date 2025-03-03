// lib/features/notes/services/context_prediction_engine.dart
import 'package:flutter/material.dart';
import '../../../core/models/note.dart';
import '../../../core/models/cognitive_note.dart';

/// コンテンツ予測の種類
enum PredictionType {
  blockType,     // 次に必要なブロックタイプ
  content,       // 関連するコンテンツ提案
  action,        // 次に取るべきアクション
  resource,      // 関連リソースの提案
}

/// 予測結果を表すクラス
class Prediction {
  final PredictionType type;
  final String title;
  final String description;
  final IconData icon;
  final double confidence; // 0.0 〜 1.0 の信頼度
  final Map<String, dynamic> data; // 予測に関連する追加データ
  
  Prediction({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    this.confidence = 0.5,
    Map<String, dynamic>? data,
  }) : data = data ?? {};
  
  // 信頼度に基づいた色を取得
  Color getConfidenceColor() {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

/// コンテキスト予測エンジン
/// ノートの内容や編集状態から次のアクションや必要なコンテンツを予測
class ContextPredictionEngine {
  // シングルトンパターン
  static final ContextPredictionEngine _instance = ContextPredictionEngine._internal();
  
  factory ContextPredictionEngine() {
    return _instance;
  }
  
  ContextPredictionEngine._internal();
  
  // ユーザーの行動パターンデータ（実際にはより複雑なモデルが必要）
  final Map<String, double> _patternWeights = {
    'heading_text': 0.8,        // 見出しの後にテキストブロック
    'text_example': 0.7,        // テキストの後に例示
    'concept_definition': 0.9,  // 概念ブロックの後に定義
    'math_graph': 0.6,          // 数式の後にグラフ
    'code_output': 0.75,        // コードの後に実行結果
  };
  
  // 科目別キーワード（実際にはより包括的なデータが必要）
  final Map<String, List<String>> _subjectKeywords = {
    'math': ['方程式', '関数', '積分', '微分', '行列', 'ベクトル', '集合'],
    'physics': ['力学', '電磁気', '熱力学', '相対性理論', '量子力学'],
    'chemistry': ['元素', '反応', '分子', '化合物', '溶液'],
    'biology': ['細胞', '遺伝子', 'タンパク質', '生態系', '進化'],
    'computer_science': ['アルゴリズム', 'データ構造', 'プログラミング', 'ネットワーク'],
  };
  
  // 現在のノートコンテキスト
  Note? _currentNote;
  int _focusedBlockIndex = -1;
  List<String> _recentActions = [];
  String _detectedSubject = '';
  
  // コンテキストの更新
  void updateContext(Note note, int focusedBlockIndex) {
    _currentNote = note;
    _focusedBlockIndex = focusedBlockIndex;
    _detectSubject();
  }
  
  // ユーザーアクションの記録
  void recordAction(String action) {
    _recentActions.add(action);
    if (_recentActions.length > 10) {
      _recentActions.removeAt(0);
    }
  }
  
  // 科目検出
  void _detectSubject() {
    if (_currentNote == null) return;
    
    final text = _currentNote!.blocks
        .map((block) => block.content)
        .join(' ');
    
    final Map<String, int> subjectScores = {};
    
    // 各科目のキーワードをカウント
    for (final entry in _subjectKeywords.entries) {
      final subject = entry.key;
      final keywords = entry.value;
      
      int score = 0;
      for (final keyword in keywords) {
        final pattern = RegExp(keyword, caseSensitive: false);
        score += pattern.allMatches(text).length;
      }
      
      subjectScores[subject] = score;
    }
    
    // 最も高いスコアの科目を検出
    if (subjectScores.isNotEmpty) {
      final topSubject = subjectScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      _detectedSubject = topSubject;
    }
  }
  
  // 次のブロックタイプを予測
  List<Prediction> predictNextBlockType() {
    if (_currentNote == null || _focusedBlockIndex < 0) {
      return _getDefaultBlockPredictions();
    }
    
    final predictions = <Prediction>[];
    final focusedBlock = _currentNote!.blocks[_focusedBlockIndex];
    
    // 見出しの後には通常テキストや箇条書きがよく続く
    if (focusedBlock.type == BlockType.heading1 || 
        focusedBlock.type == BlockType.heading2 ||
        focusedBlock.type == BlockType.heading3) {
      
      predictions.add(Prediction(
        type: PredictionType.blockType,
        title: 'テキストブロック',
        description: '見出しの内容を説明するテキストを追加',
        icon: Icons.text_fields,
        confidence: _patternWeights['heading_text'] ?? 0.5,
        data: {'blockType': BlockType.text},
      ));
      
      predictions.add(Prediction(
        type: PredictionType.blockType,
        title: 'リストブロック',
        description: '見出しに関連する項目をリスト化',
        icon: Icons.format_list_bulleted,
        confidence: 0.7,
        data: {'blockType': BlockType.list},
      ));
    }
    
    // 数式ブロックの後にはグラフやシミュレーションが役立つ
    else if (focusedBlock.type == BlockType.math) {
      predictions.add(Prediction(
        type: PredictionType.blockType,
        title: 'グラフ/図表',
        description: '数式を視覚的に表現',
        icon: Icons.insert_chart,
        confidence: _patternWeights['math_graph'] ?? 0.5,
        data: {'extendedType': 'graph'},
      ));
      
      predictions.add(Prediction(
        type: PredictionType.blockType,
        title: 'シミュレーション',
        description: '数式の動的な挙動を確認',
        icon: Icons.play_circle_filled,
        confidence: 0.65,
        data: {'extendedType': 'simulation'},
      ));
    }
    
    // コードブロックの後には実行結果や説明が役立つ
    else if (focusedBlock.type == BlockType.code) {
      predictions.add(Prediction(
        type: PredictionType.blockType,
        title: '実行結果',
        description: 'コードの出力を表示',
        icon: Icons.terminal,
        confidence: _patternWeights['code_output'] ?? 0.5,
        data: {'extendedType': 'codeOutput'},
      ));
      
      predictions.add(Prediction(
        type: PredictionType.blockType,
        title: '説明テキスト',
        description: 'コードの説明を追加',
        icon: Icons.text_fields,
        confidence: 0.6,
        data: {'blockType': BlockType.text},
      ));
    }
    
    // 科目に基づいた予測を追加
    _addSubjectSpecificPredictions(predictions);
    
    // 十分な予測がない場合はデフォルトの予測を追加
    if (predictions.length < 2) {
      predictions.addAll(_getDefaultBlockPredictions());
    }
    
    return predictions;
  }
  
  // 科目特有の予測を追加
  void _addSubjectSpecificPredictions(List<Prediction> predictions) {
    switch (_detectedSubject) {
      case 'math':
        predictions.add(Prediction(
          type: PredictionType.blockType,
          title: '数式ブロック',
          description: '数学的表現を追加',
          icon: Icons.functions,
          confidence: 0.8,
          data: {'blockType': BlockType.math},
        ));
        break;
        
      case 'physics':
        predictions.add(Prediction(
          type: PredictionType.blockType,
          title: 'シミュレーション',
          description: '物理現象をシミュレート',
          icon: Icons.science,
          confidence: 0.75,
          data: {'extendedType': 'simulation', 'simulationType': 'physics'},
        ));
        break;
        
      case 'computer_science':
        predictions.add(Prediction(
          type: PredictionType.blockType,
          title: 'コードブロック',
          description: 'プログラムコードを追加',
          icon: Icons.code,
          confidence: 0.85,
          data: {'blockType': BlockType.code},
        ));
        break;
    }
  }
  
  // デフォルトのブロック予測
  List<Prediction> _getDefaultBlockPredictions() {
    return [
      Prediction(
        type: PredictionType.blockType,
        title: 'テキストブロック',
        description: '通常のテキストを追加',
        icon: Icons.text_fields,
        confidence: 0.6,
        data: {'blockType': BlockType.text},
      ),
      Prediction(
        type: PredictionType.blockType,
        title: '見出しブロック',
        description: '新しいセクションを開始',
        icon: Icons.title,
        confidence: 0.5,
        data: {'blockType': BlockType.heading1},
      ),
      Prediction(
        type: PredictionType.blockType,
        title: 'マインドマップ',
        description: 'アイデアを視覚的に整理',
        icon: Icons.account_tree,
        confidence: 0.4,
        data: {'extendedType': 'mindMap'},
      ),
    ];
  }
  
  // 関連コンテンツの予測
  List<Prediction> predictRelatedContent() {
    if (_currentNote == null) return [];
    
    final predictions = <Prediction>[];
    
    // ノートの既存コンテンツから関連キーワードを抽出
    final contentText = _currentNote!.blocks
        .map((block) => block.content)
        .join(' ');
    
    // 科目に基づいた関連コンテンツの提案
    switch (_detectedSubject) {
      case 'math':
        if (contentText.contains('方程式') || contentText.contains('equation')) {
          predictions.add(Prediction(
            type: PredictionType.content,
            title: '方程式の解法',
            description: '一般的な方程式の解法テクニック',
            icon: Icons.auto_fix_high,
            confidence: 0.7,
          ));
        }
        if (contentText.contains('積分') || contentText.contains('integral')) {
          predictions.add(Prediction(
            type: PredictionType.content,
            title: '積分テクニック',
            description: '一般的な積分のパターンと解法',
            icon: Icons.functions,
            confidence: 0.75,
          ));
        }
        break;
        
      case 'physics':
        if (contentText.contains('力学') || contentText.contains('mechanics')) {
          predictions.add(Prediction(
            type: PredictionType.content,
            title: 'ニュートンの法則',
            description: '運動の基本法則',
            icon: Icons.science,
            confidence: 0.8,
          ));
        }
        break;
        
      case 'computer_science':
        if (contentText.contains('アルゴリズム') || contentText.contains('algorithm')) {
          predictions.add(Prediction(
            type: PredictionType.content,
            title: '一般的なアルゴリズム',
            description: '基本的なアルゴリズムとその複雑性',
            icon: Icons.code,
            confidence: 0.75,
          ));
        }
        break;
    }
    
    // 十分な予測がない場合はデフォルトの関連コンテンツを提案
    if (predictions.isEmpty) {
      predictions.add(Prediction(
        type: PredictionType.content,
        title: '関連概念の整理',
        description: '現在のノートに関連する概念をマインドマップで整理',
        icon: Icons.account_tree,
        confidence: 0.5,
      ));
    }
    
    return predictions;
  }
  
  // 次のアクションの予測
  List<Prediction> predictNextAction() {
    if (_currentNote == null) return [];
    
    final predictions = <Prediction>[];
    
    // ノートの完成度に基づく提案
    final blockCount = _currentNote!.blocks.length;
    final hasHeading = _currentNote!.blocks.any((block) => 
        block.type == BlockType.heading1 || 
        block.type == BlockType.heading2);
    
    if (blockCount < 3) {
      // ノートがまだ短い場合
      predictions.add(Prediction(
        type: PredictionType.action,
        title: '基本構造を作成',
        description: '見出しとセクションで基本構造を設計',
        icon: Icons.build,
        confidence: 0.85,
      ));
    } else if (!hasHeading && blockCount > 5) {
      // 長いノートだが見出しがない場合
      predictions.add(Prediction(
        type: PredictionType.action,
        title: '見出しを追加',
        description: 'ノートを整理するために見出しを追加',
        icon: Icons.title,
        confidence: 0.8,
      ));
    }
    
    // ノートの内容に基づく提案
    final allContent = _currentNote!.blocks
        .map((block) => block.content)
        .join(' ');
    
    if (allContent.length > 500 && !_currentNote!.tags.any((tag) => tag.contains('重要'))) {
      predictions.add(Prediction(
        type: PredictionType.action,
        title: 'キーポイントをタグ付け',
        description: '重要な概念や情報にタグを付ける',
        icon: Icons.label,
        confidence: 0.7,
      ));
    }
    
    // 最近のアクションに基づく提案
    if (_recentActions.contains('edit_math') && 
        !_recentActions.contains('add_graph')) {
      predictions.add(Prediction(
        type: PredictionType.action,
        title: 'グラフを追加',
        description: '数式の視覚的表現としてグラフを追加',
        icon: Icons.insert_chart,
        confidence: 0.75,
      ));
    }
    
    // デフォルトの提案を追加
    if (predictions.isEmpty) {
      predictions.add(Prediction(
        type: PredictionType.action,
        title: 'ノートを要約',
        description: '主要ポイントをまとめたサマリーを作成',
        icon: Icons.summarize,
        confidence: 0.6,
      ));
    }
    
    return predictions;
  }
  
  // 関連リソースの予測
  List<Prediction> predictRelatedResources() {
    if (_currentNote == null) return [];
    
    final predictions = <Prediction>[];
    
    // 科目に基づいた関連リソースの提案
    switch (_detectedSubject) {
      case 'math':
        predictions.add(Prediction(
          type: PredictionType.resource,
          title: '数学リソース',
          description: 'Khan Academyの関連講座',
          icon: Icons.school,
          confidence: 0.7,
          data: {'url': 'https://www.khanacademy.org/math'},
        ));
        break;
        
      case 'physics':
        predictions.add(Prediction(
          type: PredictionType.resource,
          title: '物理シミュレーター',
          description: 'PhETインタラクティブシミュレーション',
          icon: Icons.science,
          confidence: 0.75,
          data: {'url': 'https://phet.colorado.edu/'},
        ));
        break;
        
      case 'computer_science':
        predictions.add(Prediction(
          type: PredictionType.resource,
          title: 'コーディング演習',
          description: 'LeetCodeの関連問題',
          icon: Icons.code,
          confidence: 0.8,
          data: {'url': 'https://leetcode.com/'},
        ));
        break;
    }
    
    // ノートの内容に基づいた関連書籍やリソース
    final allContent = _currentNote!.blocks
        .map((block) => block.content)
        .join(' ');
    
    // 内容からキーワードを抽出（実際にはもっと高度なNLPが必要）
    final simpleKeywords = _extractSimpleKeywords(allContent);
    
    if (simpleKeywords.contains('algorithm') || 
        simpleKeywords.contains('データ構造')) {
      predictions.add(Prediction(
        type: PredictionType.resource,
        title: 'アルゴリズムの参考書',
        description: 'アルゴリズムイントロダクション',
        icon: Icons.menu_book,
        confidence: 0.65,
      ));
    }
    
    // デフォルトの提案
    if (predictions.isEmpty) {
      predictions.add(Prediction(
        type: PredictionType.resource,
        title: '一般的な参考文献',
        description: '分野の基本文献を探す',
        icon: Icons.bookmark,
        confidence: 0.5,
      ));
    }
    
    return predictions;
  }
  
  // シンプルなキーワード抽出（実際の実装ではNLPライブラリを使用）
  List<String> _extractSimpleKeywords(String text) {
    final normalized = text.toLowerCase();
    final words = normalized.split(RegExp(r'\s+|\.|,|;|:|\(|\)'));
    
    // 出現頻度カウント
    final wordCounts = <String, int>{};
    for (final word in words) {
      if (word.length > 3) { // 短すぎる単語を除外
        wordCounts[word] = (wordCounts[word] ?? 0) + 1;
      }
    }
    
    // 頻度でソート
    final sortedWords = wordCounts.keys.toList()
      ..sort((a, b) => (wordCounts[b] ?? 0) - (wordCounts[a] ?? 0));
    
    // 上位のキーワードを返す
    return sortedWords.take(10).toList();
  }
  
  // すべての予測を取得
  List<Prediction> getAllPredictions() {
    final predictions = <Prediction>[];
    
    predictions.addAll(predictNextBlockType());
    predictions.addAll(predictRelatedContent());
    predictions.addAll(predictNextAction());
    predictions.addAll(predictRelatedResources());
    
    // 信頼度でソート
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return predictions;
  }
  
  // 特定のタイプの予測を取得
  List<Prediction> getPredictionsByType(PredictionType type) {
    switch (type) {
      case PredictionType.blockType:
        return predictNextBlockType();
      case PredictionType.content:
        return predictRelatedContent();
      case PredictionType.action:
        return predictNextAction();
      case PredictionType.resource:
        return predictRelatedResources();
    }
  }
  
  // 現在検出されている科目を取得
  String getDetectedSubject() {
    return _detectedSubject;
  }
}