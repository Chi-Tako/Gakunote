import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/models/note.dart';
import 'package:flutter_math_fork/flutter_math.dart';

Widget _renderHeading1(BuildContext context, NoteBlock block) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      block.content,
      style: Theme.of(context).textTheme.headlineMedium,
    ),
  );
}

Widget _renderHeading2(BuildContext context, NoteBlock block) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Text(
      block.content,
      style: Theme.of(context).textTheme.titleLarge,
    ),
  );
}

Widget _renderHeading3(BuildContext context, NoteBlock block) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Text(
      block.content,
      style: Theme.of(context).textTheme.titleMedium,
    ),
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
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(
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
                  Text(
                    block.content,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

Widget _renderSketch(BuildContext context, NoteBlock block) {
  return Container(
    height: 200,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.draw, color: Colors.grey[600], size: 48),
        const SizedBox(height: 8),
        Text(
          '手書きスケッチ（準備中）',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ],
    ),
  );
}

Widget _renderTable(BuildContext context, NoteBlock block) {
  return Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      block.content.isEmpty ? '表データを入力...' : block.content,
      style: TextStyle(
        color: block.content.isEmpty ? Colors.grey[500] : null,
      ),
    ),
  );
}

Widget _renderList(BuildContext context, NoteBlock block) {
  return Text(
    block.content.isEmpty ? 'リスト項目を入力...' : block.content,
    style: TextStyle(
      color: block.content.isEmpty ? Colors.grey[500] : null,
    ),
  );
}

Widget _renderMath(BuildContext context, NoteBlock block) {
  if (block.content.isEmpty) {
    return Text(
      'LaTeX形式で数式を入力...',
      style: TextStyle(
        fontStyle: FontStyle.italic,
        color: Colors.grey[500],
      ),
    );
  }
  
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Math.tex(
      block.content,
      textStyle: Theme.of(context).textTheme.bodyLarge,
      onErrorFallback: (err) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'エラー: $err',
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            block.content,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _renderText(BuildContext context, NoteBlock block) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Text(
      block.content.isEmpty ? 'タップして編集...' : block.content,
      style: TextStyle(
        color: block.content.isEmpty ? Colors.grey[400] : null,
        fontStyle: block.content.isEmpty ? FontStyle.italic : null,
      ),
    ),
  );
}

Widget renderBlockContent(BuildContext context, NoteBlock block) {
  try {
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
      case BlockType.sketch:
        return _renderSketch(context, block);
      case BlockType.table:
        return _renderTable(context, block);
      case BlockType.list:
        return _renderList(context, block);
      case BlockType.math:
        return _renderMath(context, block);
      case BlockType.text:
      default:
        return _renderText(context, block);
    }
  } catch (e) {
    // エラーが発生した場合のフォールバック表示
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'レンダリングエラー: ${e.toString()}',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 4),
          Text(
            '内容: ${block.content}',
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}
