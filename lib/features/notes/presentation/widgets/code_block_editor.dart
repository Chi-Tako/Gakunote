// lib/features/notes/presentation/widgets/code_block_editor.dart
import 'package:flutter/material.dart';
import '../../../../core/models/note.dart';

class CodeBlockEditor extends StatelessWidget {
  final NoteBlock block;
  final int index;
  final TextEditingController controller;
  final FocusNode focusNode;

  const CodeBlockEditor({
    Key? key,
    required this.block,
    required this.index,
    required this.controller,
    required this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 言語選択 (後で実装)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '言語:',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 4),
                DropdownButton<String>(
                  value: block.metadata['language'] as String? ?? 'plaintext',
                  isDense: true,
                  underline: Container(),
                  items: const [
                    DropdownMenuItem(value: 'plaintext', child: Text('プレーンテキスト')),
                    DropdownMenuItem(value: 'dart', child: Text('Dart')),
                    DropdownMenuItem(value: 'python', child: Text('Python')),
                    DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                    DropdownMenuItem(value: 'html', child: Text('HTML')),
                    DropdownMenuItem(value: 'css', child: Text('CSS')),
                    DropdownMenuItem(value: 'json', child: Text('JSON')),
                  ],
                  onChanged: (value) {
                    // 言語の変更
                    if (value != null) {
                      block.metadata['language'] = value;
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // コードエディタ
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: null,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'コードを入力...',
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) {
                block.content = value;
              },
            ),
          ),
        ],
      ),
    );
  }
}