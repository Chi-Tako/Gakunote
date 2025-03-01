import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../../core/models/note.dart';

class CodeBlockEditor extends StatefulWidget {
  final NoteBlock block;
  final int index;
  final List<TextEditingController> blockControllers;
  final List<FocusNode> blockFocusNodes;
  final Function(String, String) onBlockContentChanged;

  const CodeBlockEditor({
    Key? key,
    required this.block,
    required this.index,
    required this.blockControllers,
    required this.blockFocusNodes,
    required this.onBlockContentChanged,
  }) : super(key: key);

  @override
  State<CodeBlockEditor> createState() => _CodeBlockEditorState();
}

class _CodeBlockEditorState extends State<CodeBlockEditor> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.blockControllers[widget.index],
            focusNode: widget.blockFocusNodes[widget.index],
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText:
                  'LaTeX形式で数式を入力（例: \\sum_{i=0}^n i^2 = \\frac{n(n+1)(2n+1)}{6}）',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              widget.onBlockContentChanged(widget.block.id, value);
              setState(() {}); // プレビューを更新するために再描画
            },
          ),

          // 数式プレビュー
          if (widget.blockControllers[widget.index].text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Math.tex(
                widget.blockControllers[widget.index].text,
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
                _mathSymbolButton('\\sum', widget.index),
                _mathSymbolButton('\\int', widget.index),
                _mathSymbolButton('\\frac{a}{b}', widget.index),
                _mathSymbolButton('\\sqrt{x}', widget.index),
                _mathSymbolButton('x^2', widget.index),
                _mathSymbolButton('\\infty', widget.index),
                _mathSymbolButton('\\alpha', widget.index),
                _mathSymbolButton('\\beta', widget.index),
                _mathSymbolButton('\\pi', widget.index),
              ],
            ),
          ),
        ],
      ),
    );
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
