import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
// lib/core/models/note.dart

class Note {
  final String id;
  String title;
  String content;
  List<NoteBlock> blocks;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tags;
  bool isFavorite;

  Note({
    String? id,
    required this.title,
    required this.content,
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
      'content': content,
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
      content: json['content'],
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
    String? content,
    List<NoteBlock>? blocks,
    List<String>? tags,
    bool? isFavorite,
  }) {
    if (title != null) this.title = title;
    if (content != null) this.content = content;
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


class NoteAdapter extends TypeAdapter<Note> {
  @override
  final typeId = 0; // 一意なID

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] as String?,
      title: fields[1] as String,
      content: fields[2] as String,
      blocks: (fields[3] as List?)?.cast<NoteBlock>(),
      createdAt: fields[4] as DateTime?,
      updatedAt: fields[5] as DateTime?,
      tags: (fields[6] as List?)?.cast<String>(),
      isFavorite: fields[7] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.blocks.map((e) => e.toJson()).toList())
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.tags)
      ..writeByte(7)
      ..write(obj.isFavorite);
  }
}

class NoteBlockAdapter extends TypeAdapter<NoteBlock> {
  @override
  final typeId = 1; // 一意なID

  @override
  NoteBlock read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NoteBlock(
      id: fields[0] as String?,
      type: fields[1] as BlockType,
      content: fields[2] as String,
      metadata: (fields[3] as Map?)?.cast<String, dynamic>() ?? {},
    );
  }

  @override
  void write(BinaryWriter writer, NoteBlock obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.metadata);
  }
}

class BlockTypeAdapter extends TypeAdapter<BlockType> {
  @override
  final typeId = 2; // 一意なID

  @override
  BlockType read(BinaryReader reader) {
    final index = reader.readByte();
    return BlockType.values[index];
  }

  @override
  void write(BinaryWriter writer, BlockType obj) {
    writer.writeByte(obj.index);
  }
}