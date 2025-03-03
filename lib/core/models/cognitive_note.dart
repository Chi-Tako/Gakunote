import 'package:gakunote/core/models/note.dart';
import 'package:uuid/uuid.dart';

class CognitiveNote extends Note {
  late Map<String, dynamic> cognitiveMetadata;

  CognitiveNote({
    String? id,
    required String title,
    required String content,
    List<NoteBlock>? blocks,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    bool isFavorite = false,
    Map<String, dynamic>? cognitiveMetadata,
  }) : super(
          id: id,
          title: title,
          content: content,
          blocks: blocks,
          createdAt: createdAt,
          updatedAt: updatedAt,
          tags: tags,
          isFavorite: isFavorite,
        ) {
    cognitiveMetadata = cognitiveMetadata ?? {};
  }

  factory CognitiveNote.fromNote(Note note) {
    return CognitiveNote(
      id: note.id,
      title: note.title,
      content: note.content,
      blocks: note.blocks,
      createdAt: note.createdAt,
      updatedAt: note.updatedAt,
      tags: note.tags,
      isFavorite: note.isFavorite,
      cognitiveMetadata: {},
    );
  }

  // キーコンセプトを抽出するメソッド
  List<NoteBlock> extractKeyConcepts() {
    // 実際の実装では、ノートの内容を解析してキーコンセプトを抽出する
    // ここでは簡単なデモとして、最初の数ブロックを返す
    return blocks.take(3).toList();
  }

  // 概念マップを生成するメソッド
  Map<String, dynamic> generateConceptMap() {
    // 実際の実装では、ノートの内容を解析して概念マップを生成する
    // ここでは簡単なデモとして、空のマップを返す
    return {};
  }

  // ブロックを概念としてマークする
  void initConceptMetadata() {
    // 概念メタデータを初期化
    cognitiveMetadata['isConcept'] = true;
  }

  // 関係を追加する
  void addRelation(String sourceBlockId, String targetBlockId, BlockRelationType type) {
    // 関係を追加する処理を実装
    cognitiveMetadata['relations'] ??= {};
    cognitiveMetadata['relations'][sourceBlockId] ??= {};
    cognitiveMetadata['relations'][sourceBlockId][targetBlockId] = type.toString();
  }
}

enum BlockRelationType {
  reference, // 参照する
  explains, // 説明する
  examples, // 例示する
  depends, // 依存する
  contrasts, // 対比する
  sequence, // 順序関係
}

class CognitiveBlock extends NoteBlock {
  Map<String, dynamic> cognitiveMetadata;

  CognitiveBlock({
    String? id,
    required BlockType type,
    required String content,
    Map<String, dynamic>? metadata,
    Map<String, dynamic>? cognitiveMetadata,
  }) : super(
          id: id,
          type: type,
          content: content,
          metadata: metadata,
        ) {
    this.cognitiveMetadata = cognitiveMetadata ?? {};
  }

  void initConceptMetadata() {
    // 概念メタデータを初期化
    cognitiveMetadata['isConcept'] = true;
  }
}