import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../../../../core/models/note.dart';

class MathBlockEditor extends StatelessWidget {
  final NoteBlock block;
  final int index;
  final List<TextEditingController> blockControllers;
  final List<FocusNode> blockFocusNodes;
  final Function(String) onMathSymbolTap;

  const MathBlockEditor({
    Key? key,
    required this.block,
    required this.index,
    required this.blockControllers,
    required this.blockFocusNodes,
    required this.onMathSymbolTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: blockControllers[index],
            focusNode: blockFocusNodes[index],
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'LaTeX形式で数式を入力（例: \\sum_{i=0}^n i^2 = \\frac{n(n+1)(2n+1)}{6}）',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              block.content = value;
            },
          ),
          if (blockControllers[index].text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Math.tex(
                blockControllers[index].text,
                textStyle: Theme.of(context).textTheme.bodyLarge!,
                onErrorFallback: (err) => Text(
                  'エラー: $err',
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _mathSymbolButton('\\sum', context),
                _mathSymbolButton('\\int', context),
                _mathSymbolButton('\\frac{a}{b}', context),
                _mathSymbolButton('\\sqrt{x}', context),
                _mathSymbolButton('x^2', context),
                _mathSymbolButton('\\infty', context),
                _mathSymbolButton('\\alpha', context),
                _mathSymbolButton('\\beta', context),
                _mathSymbolButton('\\pi', context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mathSymbolButton(String symbol, BuildContext context) {
    return InkWell(
      onTap: () {
        onMathSymbolTap(symbol);
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
