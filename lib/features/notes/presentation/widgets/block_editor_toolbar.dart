import 'package:flutter/material.dart';
import '../../../../core/models/note.dart';

class BlockEditorToolbar extends StatelessWidget {
  final BlockType blockType;
  final Function(BlockType?) onBlockTypeChanged;
  final VoidCallback onConfirmPressed;
  final VoidCallback onArrowUpPressed;
  final VoidCallback onArrowDownPressed;
  final VoidCallback onDeletePressed;
  final VoidCallback onAddPressed;
  final bool isFirstBlock;
  final bool isLastBlock;

  const BlockEditorToolbar({
    Key? key,
    required this.blockType,
    required this.onBlockTypeChanged,
    required this.onConfirmPressed,
    required this.onArrowUpPressed,
    required this.onArrowDownPressed,
    required this.onDeletePressed,
    required this.onAddPressed,
    required this.isFirstBlock,
    required this.isLastBlock,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
      child: Row(
        children: [
          // ブロックタイプ選択
          DropdownButton<BlockType>(
            value: blockType,
            isDense: true,
            underline: Container(), // 下線を非表示
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            onChanged: onBlockTypeChanged,
            items: BlockType.values
                .where((type) => type != BlockType.sketch) // 手書きは別途実装
                .map<DropdownMenuItem<BlockType>>((BlockType value) {
              return DropdownMenuItem<BlockType>(
                value: value,
                child: Text(_getBlockTypeName(value),
                    style: const TextStyle(fontSize: 12)),
              );
            }).toList(),
          ),
          const Spacer(),
          // 確定ボタン
          OutlinedButton.icon(
            onPressed: onConfirmPressed,
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
            onPressed: isFirstBlock ? null : onArrowUpPressed,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: isLastBlock ? null : onArrowDownPressed,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onDeletePressed,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: onAddPressed,
          ),
        ],
      ),
    );
  }

  String _getBlockTypeName(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'テキスト';
      case BlockType.markdown:
        return 'Markdown';
      case BlockType.heading1:
        return '見出し 1';
      case BlockType.heading2:
        return '見出し 2';
      case BlockType.heading3:
        return '見出し 3';
      case BlockType.code:
        return 'コード';
      case BlockType.image:
        return '画像';
      case BlockType.sketch:
        return '手書き';
      case BlockType.table:
        return '表';
      case BlockType.list:
        return 'リスト';
      case BlockType.math:
        return '数式';
      default:
        return type.toString().split('.').last;
    }
  }
}
