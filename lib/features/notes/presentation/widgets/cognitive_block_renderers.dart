// lib/features/notes/presentation/widgets/cognitive_block_renderers.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/models/note.dart';
import '../../../../core/models/cognitive_note.dart';

/// コグニティブブロックのレンダリングを行うクラス
class CognitiveBlockRenderer extends StatelessWidget {
  final NoteBlock block;
  final bool isSelected;
  final Function(NoteBlock) onTap;
  final Function(NoteBlock)? onLongPress;
  final bool showRelations;

  const CognitiveBlockRenderer({
    Key? key,
    required this.block,
    this.isSelected = false,
    required this.onTap,
    this.onLongPress,
    this.showRelations = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ブロックをCognitiveBlockにキャスト（普通のNoteBlockの場合はデフォルト値を使用）
    final cognitiveBlock = block is CognitiveBlock
        ? block as CognitiveBlock
        : CognitiveBlock.fromNoteBlock(block);

    // ブロックの種類に応じたレンダリング
    return _buildBlockContainer(
      context,
      cognitiveBlock,
      _getBlockContent(context, cognitiveBlock),
    );
  }

  // ブロックのコンテナスタイル
  Widget _buildBlockContainer(
    BuildContext context, 
    CognitiveBlock cognitiveBlock, 
    Widget content
  ) {
    // 選択状態に応じたスタイル
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).dividerColor;
    
    final borderWidth = isSelected ? 2.0 : 1.0;
    
    // ブロック種類に応じた背景色
    Color backgroundColor;
    switch (cognitiveBlock.type) {
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
        break;
      case BlockType.code:
        backgroundColor = Theme.of(context).colorScheme.surface.withOpacity(0.8);
        break;
      case BlockType.math:
        backgroundColor = Colors.lightBlue.withOpacity(0.1);
        break;
      default:
        backgroundColor = Theme.of(context).colorScheme.surface;
    }
    
    // 強調表示が有効になっているかどうか
    if (cognitiveBlock.isHighlighted) {
      backgroundColor = Theme.of(context).colorScheme.secondary.withOpacity(0.2);
    }
    
    return GestureDetector(
      onTap: () => onTap(block),
      onLongPress: onLongPress != null ? () => onLongPress!(block) : null,
      child: Opacity(
        opacity: cognitiveBlock.cognitiveMetadata['hidden'] == true ? 0.5 : 1.0,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: borderWidth,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.2),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ブロック種類のインジケーター（オプション）
            if (isSelected || showRelations)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildBlockTypeChip(context, cognitiveBlock),
                    if (showRelations) 
                      _buildRelationsIndicator(context, cognitiveBlock),
                  ],
                ),
              ),
            
            // 実際のブロックコンテンツ
            content,
          ],
        ),
      ),
    ));
  }

  // 関連性インジケーター
  Widget _buildRelationsIndicator(BuildContext context, CognitiveBlock block) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.link,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          '関連',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  // ブロックタイプに応じたコンテンツを生成
  Widget _getBlockContent(BuildContext context, CognitiveBlock block) {
    // 拡張タイプの確認
    final extendedType = block.cognitiveMetadata['blockType'];
    
    // 拡張ブロックタイプに基づいたレンダリング
    if (extendedType != null) {
      switch (extendedType) {
        case 'concept':
          return _renderConceptBlock(context, block);
        case 'mindMap':
          return _renderMindMapBlock(context, block);
        case 'simulation':
          return _renderSimulationBlock(context, block);
        case 'knowledgeGraph':
          return _renderKnowledgeGraphBlock(context, block);
      }
    }
    
    // 標準ブロックタイプに基づいたレンダリング
    switch (block.type) {
      case BlockType.heading1:
        return _renderHeading1(context, block);
      case BlockType.heading2:
        return _renderHeading2(context, block);
      case BlockType.heading3:
        return _renderHeading3(context, block);
      case BlockType.markdown:
        return _renderMarkdown(context, block);
      case BlockType.code:
        return _renderCode(context, block);
      case BlockType.image:
        return _renderImage(context, block);
      case BlockType.math:
        return _renderMath(context, block);
      case BlockType.text:
      default:
        return _renderText(context, block);
    }
  }

  // 以下、各ブロックタイプ用のレンダリング関数

  Widget _renderHeading1(BuildContext context, NoteBlock block) {
    return Text(
      block.content,
      style: Theme.of(context).textTheme.headlineMedium,
    );
  }

  Widget _renderHeading2(BuildContext context, NoteBlock block) {
    return Text(
      block.content,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _renderHeading3(BuildContext context, NoteBlock block) {
    return Text(
      block.content,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _renderMarkdown(BuildContext context, NoteBlock block) {
    if (block.content.isEmpty) {
      return Text(
        'Markdownを入力...',
        style: TextStyle(
          color: Colors.grey[400],
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    return MarkdownBody(
      data: block.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: Theme.of(context).textTheme.bodyMedium,
        h1: Theme.of(context).textTheme.headlineMedium,
        h2: Theme.of(context).textTheme.titleLarge,
        h3: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _renderCode(BuildContext context, NoteBlock block) {
    final language = block.metadata['language'] as String? ?? 'plaintext';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language != 'plaintext')
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ),
          Text(
            block.content.isEmpty ? 'コードを入力...' : block.content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderImage(BuildContext context, NoteBlock block) {
    if (block.content.isEmpty) {
      return Container(
        height: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '画像URLを入力してください',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        block.content,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 150,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / 
                    (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 150,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey[600], size: 48),
                const SizedBox(height: 8),
                Text(
                  '画像を読み込めませんでした',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _renderMath(BuildContext context, NoteBlock block) {
    // ここで数式レンダリングライブラリを使用する
    // フラッターの数式レンダリングライブラリ（flutter_math_fork等）を利用
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        block.content.isEmpty 
            ? 'LaTeX形式で数式を入力...' 
            : '数式: ${block.content}',
        style: TextStyle(
          fontStyle: block.content.isEmpty ? FontStyle.italic : null,
          color: block.content.isEmpty ? Colors.grey[500] : null,
        ),
      ),
    );
  }

  Widget _renderText(BuildContext context, NoteBlock block) {
    return Text(
      block.content.isEmpty ? 'タップして編集...' : block.content,
      style: TextStyle(
        color: block.content.isEmpty ? Colors.grey[400] : null,
        fontStyle: block.content.isEmpty ? FontStyle.italic : null,
      ),
    );
  }

  // 拡張ブロック: 概念ブロック
  Widget _renderConceptBlock(BuildContext context, CognitiveBlock block) {
    final definition = block.cognitiveMetadata['definition'] ?? '';
    final examples = block.cognitiveMetadata['examples'] ?? <String>[];
    final relatedConcepts = block.cognitiveMetadata['relatedConcepts'] ?? <String>[];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 概念名
        Text(
          block.content,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Divider(),
        // 定義
        if (definition.isNotEmpty) ...[
          const Text(
            '定義:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(definition),
          const SizedBox(height: 8),
        ],
        // 例
        if (examples.isNotEmpty) ...[
          const Text(
            '例:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          ...examples.map((example) => Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text('• $example'),
          )),
          const SizedBox(height: 8),
        ],
        // 関連概念
        if (relatedConcepts.isNotEmpty) ...[
          const Text(
            '関連概念:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Wrap(
            spacing: 4,
            children: relatedConcepts.map((concept) => Chip(
              label: Text(
                concept,
                style: const TextStyle(fontSize: 12),
              ),
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            )).toList(),
          ),
        ],
      ],
    );
  }

  // 拡張ブロック: マインドマップブロック
  Widget _renderMindMapBlock(BuildContext context, CognitiveBlock block) {
    final centralTopic = block.cognitiveMetadata['centralTopic'] ?? '';
    
    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_tree, size: 32, color: Colors.teal),
          const SizedBox(height: 8),
          Text(
            centralTopic.isEmpty ? 'マインドマップ' : centralTopic,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Text(
            '（クリックして編集）',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // 拡張ブロック: シミュレーションブロック
  Widget _renderSimulationBlock(BuildContext context, CognitiveBlock block) {
    final simulationType = block.cognitiveMetadata['simulationType'] ?? 'generic';
    String simulationName;
    
    switch (simulationType) {
      case 'physics':
        simulationName = '物理シミュレーション';
        break;
      case 'chemistry':
        simulationName = '化学シミュレーション';
        break;
      case 'math':
        simulationName = '数学シミュレーション';
        break;
      default:
        simulationName = 'シミュレーション';
    }
    
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.science, size: 32, color: Colors.amber),
          const SizedBox(height: 8),
          Text(
            simulationName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            block.content.isEmpty ? '（クリックして編集）' : block.content,
            style: TextStyle(
              fontSize: 14,
              color: block.content.isEmpty ? Colors.grey[600] : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 拡張ブロック: 知識グラフブロック
  Widget _renderKnowledgeGraphBlock(BuildContext context, CognitiveBlock block) {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.grain, size: 32, color: Colors.indigo),
          const SizedBox(height: 8),
          Text(
            '知識グラフ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            block.content.isEmpty ? '（クリックして編集）' : block.content,
            style: TextStyle(
              fontSize: 14,
              color: block.content.isEmpty ? Colors.grey[600] : null,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  }

  // ブロック種類を示すチップ
  Widget _buildBlockTypeChip(BuildContext context, CognitiveBlock block) {
    String label;
    Color color;
    
    switch (block.type) {
      case BlockType.heading1:
        label = '見出し 1';
        color = Colors.blue;
        break;
      case BlockType.heading2:
        label = '見出し 2';
        color = Colors.blue.shade300;
        break;
      case BlockType.heading3:
        label = '見出し 3';
        color = Colors.blue.shade200;
        break;
      case BlockType.text:
        label = 'テキスト';
        color = Colors.green;
        break;
      case BlockType.markdown:
        label = 'Markdown';
        color = Colors.purple;
        break;
      case BlockType.code:
        label = 'コード';
        color = Colors.grey;
        break;
      case BlockType.image:
        label = '画像';
        color = Colors.orange;
        break;
      case BlockType.math:
        label = '数式';
        color = Colors.lightBlue;
        break;
      default:
        if (block is CognitiveBlock) {
          // 拡張ブロックタイプの処理
          if (block.cognitiveMetadata.containsKey('blockType')) {
            final extendedType = block.cognitiveMetadata['blockType'];
            if (extendedType == 'concept') {
              label = '概念';
              color = Colors.deepPurple;
            } else if (extendedType == 'mindMap') {
              label = 'マインドマップ';
              color = Colors.teal;
            } else if (extendedType == 'simulation') {
              label = 'シミュレーション';
              color = Colors.amber;
            } else {
              label = '拡張ブロック';
              color = Colors.indigo;
            }
          } else {
            label = 'ブロック';
            color = Colors.grey;
          }
        } else {
          label = 'ブロック';
          color = Colors.grey;
        }