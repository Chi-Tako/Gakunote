import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/models/note.dart';
import 'package:flutter_math_fork/flutter_math.dart';

Widget _renderHeading1(BuildContext context, NoteBlock block) {
  return Text(
    block.content,
    style: Theme.of(context).textTheme.headlineMedium!,
  );
}

Widget _renderHeading2(BuildContext context, NoteBlock block) {
  return Text(
    block.content,
    style: Theme.of(context).textTheme.titleLarge!,
  );
}

Widget _renderHeading3(BuildContext context, NoteBlock block) {
  return Text(
    block.content,
    style: Theme.of(context).textTheme.titleMedium!,
  );
}

Widget _renderMarkdown(BuildContext context, NoteBlock block) {
  return MarkdownBody(
    data: block.content,
    selectable: true,
  );
}

Widget _renderCode(BuildContext context, NoteBlock block) {
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
}

Widget _renderImage(BuildContext context, NoteBlock block) {
  return Image.network(
    block.content,
    errorBuilder: (context, error, stackTrace) {
      return const Center(
        child: Text('画像を読み込めませんでした'),
      );
    },
  );
}

Widget _renderSketch(BuildContext context, NoteBlock block) {
  return Container(
    height: 200,
    color: Colors.grey[200],
    child: const Center(
      child: Text('手書きスケッチ（準備中）'),
    ),
  );
}

Widget _renderTable(BuildContext context, NoteBlock block) {
  return Text(block.content);
}

Widget _renderList(BuildContext context, NoteBlock block) {
  return Text(block.content);
}

Widget _renderMath(BuildContext context, NoteBlock block) {
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
}

Widget _renderText(BuildContext context, NoteBlock block) {
  return Text(
    block.content.isEmpty ? 'タップして編集...' : block.content,
    style: TextStyle(
      color: block.content.isEmpty ? Colors.grey : null,
    ),
  );
}

Widget renderBlockContent(BuildContext context, NoteBlock block) {
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
}

TextStyle getTextStyleForBlockType(BlockType type) {
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

double getFontSizeForBlockType(BlockType type) {
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

String getBlockTypeName(BlockType type) {
  return _getBlockTypeName(type);
}

String _getBlockHintText(BlockType type) {
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

String getBlockHint(BlockType type) {
  return _getBlockHintText(type);
}
