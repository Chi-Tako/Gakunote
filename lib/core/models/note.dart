// lib/core/models/note.dart
import 'package:uuid/uuid.dart';

class Note {
  final String id;
  String title;
  List<NoteBlock> blocks;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;
  bool isFavorite;

  Note({
    String? id,
    required this.title,
    List<NoteBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    this.isFavorite = false,
  })  : id = id ?? const Uuid().v4(),
        blocks = blocks ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [];

  // JSON変換用メソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'blocks': blocks.map((block) => block.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  // JSONからのファクトリーメソッド
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'],
      title: json['title'],
      blocks: (json['blocks'] as List)
          .map((blockJson) => NoteBlock.fromJson(blockJson))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      tags: List<String>.from(json['tags']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // ノートを更新するメソッド
  void update({
    String? title,
    List<NoteBlock>? blocks,
    List<String>? tags,
    bool? isFavorite,
  }) {
    if (title != null) this.title = title;
    if (blocks != null) this.blocks = blocks;
    if (tags != null) this.tags = tags;
    if (isFavorite != null) this.isFavorite = isFavorite;
    updatedAt = DateTime.now();
  }

  // ブロックを追加するメソッド
  void addBlock(NoteBlock block) {
    blocks.add(block);
    updatedAt = DateTime.now();
  }

  // ブロックを削除するメソッド
  void removeBlock(String blockId) {
    blocks.removeWhere((block) => block.id == blockId);
    updatedAt = DateTime.now();
  }

  // ブロックを更新するメソッド
  void updateBlock(String blockId, {String? content, BlockType? type}) {
    final index = blocks.indexWhere((block) => block.id == blockId);
    if (index != -1) {
      final block = blocks[index];
      if (content != null) block.content = content;
      if (type != null) block.type = type;
      updatedAt = DateTime.now();
    }
  }

  // ブロックの順序を変更するメソッド
  void reorderBlocks(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final block = blocks.removeAt(oldIndex);
    blocks.insert(newIndex, block);
    updatedAt = DateTime.now();
  }
}

// ノートブロックの種類を定義
enum BlockType {
  text,      // 通常のテキスト
  markdown,  // Markdown
  heading1,  // 見出し1
  heading2,  // 見出し2
  heading3,  // 見出し3
  code,      // コードブロック
  image,     // 画像
  sketch,    // 手書きスケッチ（後で実装）
  table,     // 表（後で実装）
  list,      // リスト（後で実装）
  math,      // 数式ブロック（新規追加）
}

// ノートブロックのデータモデル
class NoteBlock {
  final String id;
  BlockType type;
  String content;
  Map<String, dynamic> metadata;

  NoteBlock({
    String? id,
    required this.type,
    required this.content,
    Map<String, dynamic>? metadata,
  })  : id = id ?? const Uuid().v4(),
        metadata = metadata ?? {};

  // JSON変換用メソッド
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'content': content,
      'metadata': metadata,
    };
  }

  // JSONからのファクトリーメソッド
  factory NoteBlock.fromJson(Map<String, dynamic> json) {
    return NoteBlock(
      id: json['id'],
      type: _blockTypeFromString(json['type']),
      content: json['content'],
      metadata: json['metadata'] ?? {},
    );
  }

  // 文字列からBlockTypeへの変換ヘルパー
  static BlockType _blockTypeFromString(String typeStr) {
    return BlockType.values.firstWhere(
      (e) => e.toString().split('.').last == typeStr,
      orElse: () => BlockType.text,
    );
  }
}

// 後で実装する手書きブロックのメタデータ構造
class SketchMetadata {
  final List<Map<String, dynamic>> strokes; // 各ストロークのデータ
  final Map<String, String> recognizedTextMapping; // 認識されたテキストのマッピング

  SketchMetadata({
    required this.strokes,
    required this.recognizedTextMapping,
  });

  // JSON変換用メソッド
  Map<String, dynamic> toJson() {
    return {
      'strokes': strokes,
      'recognizedTextMapping': recognizedTextMapping,
    };
  }

  // JSONからのファクトリーメソッド
  factory SketchMetadata.fromJson(Map<String, dynamic> json) {
    return SketchMetadata(
      strokes: List<Map<String, dynamic>>.from(json['strokes']),
      recognizedTextMapping: Map<String, String>.from(json['recognizedTextMapping']),
    );
  }
}