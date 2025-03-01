// lib/features/notes/presentation/widgets/block_editor.dart
import 'package:flutter/material.dart';
import '../../../../core/models/note.dart';
import 'math_block_editor.dart';
import 'code_block_editor.dart';

/// ブロック編集用ウィジェット
class BlockEditor extends StatelessWidget {
  final NoteBlock block;
  final int index;
  final List<TextEditingController> blockControllers;
  final List<FocusNode> blockFocusNodes;
  final Function(BlockType) onTypeChanged;
  final VoidCallback onConfirm;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onDelete;
  final VoidCallback onAddAfter;

  const BlockEditor({
    super.key,
    required this.block,
    required this.index,
    required this.blockControllers,
    required this.blockFocusNodes,
    required this.onTypeChanged,
    required this.onConfirm,
    this.onMoveUp,
    this.onMoveDown,
    required this.onDelete,
    required this.onAddAfter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToolbar(context),
          _buildEditor(context),
        ],
      ),
    );
  }

  /// ブロック編集ツールバー
  Widget _buildToolbar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      child: Row(
        children: [
          // ブロックタイプ選択
          DropdownButton<BlockType>(
            value: block.type,
            isDense: true,
            underline: Container(), // 下線を非表示
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            onChanged: (BlockType? newValue) {
              if (newValue != null) {
                onTypeChanged(newValue);
              }
            },
            items: BlockType.values
                .where((type) => type != BlockType.sketch) // 手書きは別途実装
                .map<DropdownMenuItem<BlockType>>((BlockType value) {
              return DropdownMenuItem<BlockType>(
                value: value,
                child: Text(getBlockTypeName(value), style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
          const Spacer(),
          // 確定ボタン
          OutlinedButton.icon(
            onPressed: onConfirm,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('確定', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ブロック操作アイコン
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onMoveUp,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onMoveDown,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onDelete,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onAddAfter,
          ),
        ],
      ),
    );
  }

  /// ブロックタイプに応じたエディタを表示
  Widget _buildEditor(BuildContext context) {
    switch (block.type) {
      case BlockType.math:
        return MathBlockEditor(
          block: block,
          index: index,
          blockControllers: blockControllers,
          blockFocusNodes: blockFocusNodes,
          onMathSymbolTap: (symbol) {
            _insertMathSymbol(symbol);
          },
        );
      case BlockType.code:
        return CodeBlockEditor(
          block: block,
          index: index,
          controller: blockControllers[index],
          focusNode: blockFocusNodes[index],
        );
      default:
        return Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: blockControllers[index],
            focusNode: blockFocusNodes[index],
            maxLines: null,
            style: getTextStyleForBlockType(block.type),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: getBlockHint(block.type),
              hintStyle: TextStyle(
                fontSize: getFontSizeForBlockType(block.type),
                color: Colors.grey,
              ),
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              // リアルタイムで内容を更新
              block.content = value;
            },
          ),
        );
    }
  }

  // 数式記号を挿入するヘルパーメソッド
  void _insertMathSymbol(String symbol) {
    final controller = blockControllers[index];
    final currentPosition = controller.selection.start;
    
    // 選択位置が無効な場合は最後に追加
    if (currentPosition < 0) {
      controller.text = controller.text + symbol;
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    } else {
      final text = controller.text;
      final newText = text.substring(0, currentPosition) +
          symbol +
          text.substring(currentPosition);
      controller.text = newText;
      controller.selection = TextSelection.collapsed(offset: currentPosition + symbol.length);
    }
    
    // ブロックの内容を更新
    block.content = controller.text;
  }

  String getBlockTypeName(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return '見出し';
      case BlockType.text:
        return '段落';
      case BlockType.list:
        return '箇条書き';
      case BlockType.list:
        return '番号付きリスト';
      case BlockType.code:
        return 'コード';
      case BlockType.text:
        return '引用';
      case BlockType.math:
        return '数式';
      default:
        return '不明';
    }
  }

  TextStyle getTextStyleForBlockType(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      default:
        return const TextStyle(fontSize: 16);
    }
  }

  String getBlockHint(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return '見出しを入力';
      default:
        return 'テキストを入力';
    }
  }

  double getFontSizeForBlockType(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return 24;
      default:
        return 16;
    }
  }
}