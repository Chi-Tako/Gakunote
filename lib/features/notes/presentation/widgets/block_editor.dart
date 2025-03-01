import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/models/note.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'math_block_editor.dart';

class BlockEditor extends StatefulWidget {
  final Note note;
  final List<TextEditingController> blockControllers;
  final List<FocusNode> blockFocusNodes;
  final int focusedBlockIndex;
  final Function(int) onBlockFocused;
  final Function(int, int) onReorderBlock;
  final Function(String) onRemoveBlock;
  final Function(int) onAddNewBlockAfter;
  final Map<String, bool> blockEditingStates;
  final Function(String, String) onBlockContentChanged;
  final Function(String, BlockType) onBlockTypeChanged;

  const BlockEditor({
    Key? key,
    required this.note,
    required this.blockControllers,
    required this.blockFocusNodes,
    required this.focusedBlockIndex,
    required this.onBlockFocused,
    required this.onReorderBlock,
    required this.onRemoveBlock,
    required this.onAddNewBlockAfter,
    required this.blockEditingStates,
    required this.onBlockContentChanged,
    required this.onBlockTypeChanged,
  }) : super(key: key);

  @override
  State<BlockEditor> createState() => _BlockEditorState();
}

class _BlockEditorState extends State<BlockEditor> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.note.blocks.length,
      itemBuilder: (context, index) {
        final block = widget.note.blocks[index];
        return _buildBlockWidget(block, index);
      },
    );
  }

  Widget _buildBlockWidget(NoteBlock block, int index) {
    final bool isBlockFocused = widget.focusedBlockIndex == index;
    final bool isBlockEditing = widget.blockEditingStates[block.id] ?? false;

    // 表示モードまたはフォーカスされていないブロック
    if (!isBlockFocused || !isBlockEditing) {
      return InkWell(
        onTap: () {
          // フォーカスを当該ブロックに移動
          widget.blockFocusNodes[index].requestFocus();
          widget.onBlockFocused(index);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _renderBlockContent(block),
        ),
      );
    }

    // 編集モードでフォーカスされていて編集中のブロック
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ブロック編集コントロール (フォーカス時のみ表示)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
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
                      widget.onBlockTypeChanged(block.id, newValue);
                    }
                  },
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
                  onPressed: () {
                    // ブロックの内容を保存
                    widget.onBlockContentChanged(
                        block.id, widget.blockControllers[index].text);
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('確定', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  onPressed: index > 0
                      ? () {
                          widget.onReorderBlock(index, index - 1);
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: index < widget.note.blocks.length - 1
                      ? () {
                          widget.onReorderBlock(index, index + 1);
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    widget.onRemoveBlock(block.id);
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    widget.onAddNewBlockAfter(index);
                  },
                ),
              ],
            ),
          ),

          // 特殊ブロックタイプの編集UI
          if (block.type == BlockType.math)
            _buildMathBlockEditor(block, index)
          else
            // 通常のブロック編集UI
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: widget.blockControllers[index],
                focusNode: widget.blockFocusNodes[index],
                maxLines: null,
                style: _getTextStyleForBlockType(block.type),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _getBlockHint(block.type),
                  hintStyle: TextStyle(
                    fontSize: _getFontSizeForBlockType(block.type),
                    color: Colors.grey,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) {
                  // リアルタイムで内容を更新
                  widget.onBlockContentChanged(block.id, value);
                },
              ),
            ),
        ],
      ),
    );
  }

  // 数式ブロックのエディタUI
  Widget _buildMathBlockEditor(NoteBlock block, int index) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.blockControllers[index],
            focusNode: widget.blockFocusNodes[index],
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText:
                  'LaTeX形式で数式を入力（例: \\sum_{i=0}^n i^2 = \\frac{n(n+1)(2n+1)}{6}）',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              widget.onBlockContentChanged(block.id, value);
              setState(() {}); // プレビューを更新するために再描画
            },
          ),

          // 数式プレビュー
          if (widget.blockControllers[index].text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Math.tex(
                widget.blockControllers[index].text,
                textStyle: Theme.of(context).textTheme.bodyLarge!,
                onErrorFallback: (err) => Text(
                  'エラー: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),

          // 数式記号パレット
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _mathSymbolButton('\\sum', index),
                _mathSymbolButton('\\int', index),
                _mathSymbolButton('\\frac{a}{b}', index),
                _mathSymbolButton('\\sqrt{x}', index),
                _mathSymbolButton('x^2', index),
                _mathSymbolButton('\\infty', index),
                _mathSymbolButton('\\alpha', index),
                _mathSymbolButton('\\beta', index),
                _mathSymbolButton('\\pi', index),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _renderBlockContent(NoteBlock block) {
    switch (block.type) {
      case BlockType.heading1:
        return Text(
          block.content,
          style: Theme.of(context).textTheme.headlineMedium!,
        );
      case BlockType.heading2:
        return Text(
          block.content,
          style: Theme.of(context).textTheme.titleLarge!,
        );
      case BlockType.heading3:
        return Text(
          block.content,
          style: Theme.of(context).textTheme.titleMedium!,
        );
      case BlockType.markdown:
        return MarkdownBody(
          data: block.content,
          selectable: true,
        );
      case BlockType.code:
        return Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey[200],
          child: Text(
            block.content,
            style: const TextStyle(
              fontFamily: 'monospace',
            ),
          ),
        );
      case BlockType.image:
        return Image.network(
          block.content,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Text('画像を読み込めませんでした'),
            );
          },
        );
      case BlockType.sketch:
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Text('手書きスケッチ（準備中）'),
          ),
        );
      case BlockType.table:
      case BlockType.list:
        return Text(block.content);
      case BlockType.math:
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Math.tex(
            block.content,
            textStyle: Theme.of(context).textTheme.bodyLarge!,
            onErrorFallback: (err) => Text(
              'エラー: $err',
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        );
      case BlockType.text:
      default:
        return Text(
          block.content.isEmpty ? 'タップして編集...' : block.content,
          style: TextStyle(
            color: block.content.isEmpty ? Colors.grey : null,
          ),
        );
    }
  }

  // ブロックタイプに応じたテキストスタイルを取得
  TextStyle _getTextStyleForBlockType(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
      case BlockType.heading2:
        return const TextStyle(fontSize: 20, fontWeight: FontWeight.bold);
      case BlockType.heading3:
        return const TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
      case BlockType.code:
        return const TextStyle(fontFamily: 'monospace');
      default:
        return const TextStyle(fontSize: 16);
    }
  }

  // ブロックタイプに応じたフォントサイズを取得
  double _getFontSizeForBlockType(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return 24;
      case BlockType.heading2:
        return 20;
      case BlockType.heading3:
        return 18;
      default:
        return 16;
    }
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

  String _getBlockHint(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'テキストを入力...';
      case BlockType.markdown:
        return 'Markdownを入力...';
      case BlockType.heading1:
        return '見出し 1';
      case BlockType.heading2:
        return '見出し 2';
      case BlockType.heading3:
        return '見出し 3';
      case BlockType.code:
        return 'コードを入力...';
      case BlockType.image:
        return '画像URLを入力...';
      case BlockType.math:
        return 'LaTeX形式で数式を入力...';
      default:
        return '内容を入力...';
    }
  }

  // 数式記号ボタン
  Widget _mathSymbolButton(String symbol, int blockIndex) {
    return InkWell(
      onTap: () {
        // final controller = _blockControllers[blockIndex];
        // final currentPosition = controller.selection.start;

        // // 選択位置が無効な場合は最後に追加
        // if (currentPosition < 0) {
        //   controller.text = controller.text + symbol;
        //   controller.selection =
        //       TextSelection.collapsed(offset: controller.text.length);
        // } else {
        //   final text = controller.text;
        //   final newText = text.substring(0, currentPosition) +
        //       symbol +
        //       text.substring(currentPosition);
        //   controller.text = newText;
        //   controller.selection = TextSelection.collapsed(
        //       offset: currentPosition + symbol.length);
        // }

        // // ブロックの内容を更新
        // _note.blocks[blockIndex].content = controller.text;
        // setState(() {}); // 数式プレビューを更新
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Math.tex(
          symbol,
          textStyle: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
