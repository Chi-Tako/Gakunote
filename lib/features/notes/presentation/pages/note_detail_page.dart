// lib/features/notes/presentation/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/models/note.dart';

class NoteDetailPage extends StatefulWidget {
  final String noteId;

  const NoteDetailPage({
    Key? key,
    required this.noteId,
  }) : super(key: key);

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late Note _note;
  late TextEditingController _titleController;
  final List<TextEditingController> _blockControllers = [];
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    // 実際のアプリではデータベースから取得
    // ここではダミーデータを使用
    _note = _getDummyNote(widget.noteId);
    _titleController = TextEditingController(text: _note.title);
    
    // 各ブロックのコントローラーを初期化
    for (var block in _note.blocks) {
      _blockControllers.add(TextEditingController(text: block.content));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _blockControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // ダミーノートの取得（実際のアプリではデータベースから取得）
  Note _getDummyNote(String id) {
    return Note(
      id: id,
      title: 'ノート $id',
      blocks: [
        NoteBlock(
          type: BlockType.heading1,
          content: 'ノート $id の見出し',
        ),
        NoteBlock(
          type: BlockType.text,
          content: 'これはサンプルテキストです。実際のアプリでは、このノートの内容はデータベースから取得されます。',
        ),
        NoteBlock(
          type: BlockType.markdown,
          content: '# Markdownの見出し\n\n- リスト項目1\n- リスト項目2\n\n**太字**と*斜体*のテキスト。',
        ),
      ],
      tags: ['サンプル', 'テスト'],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'タイトルを入力',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
              )
            : Text(_note.title),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // 編集内容を保存
                  _saveChanges();
                }
                _isEditing = !_isEditing;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showOptions(context);
            },
          ),
        ],
      ),
      body: _buildNoteContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addNewBlock();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteContent() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _note.blocks.length,
      itemBuilder: (context, index) {
        final block = _note.blocks[index];
        return _buildBlockWidget(block, index);
      },
    );
  }

  Widget _buildBlockWidget(NoteBlock block, int index) {
    if (_isEditing) {
      // 編集モード
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ブロックタイプ選択
              DropdownButton<BlockType>(
                value: block.type,
                onChanged: (BlockType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      block.type = newValue;
                    });
                  }
                },
                items: BlockType.values
                    .where((type) => type != BlockType.sketch) // 手書きは別途実装
                    .map<DropdownMenuItem<BlockType>>((BlockType value) {
                  return DropdownMenuItem<BlockType>(
                    value: value,
                    child: Text(_getBlockTypeName(value)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // ブロック内容の編集フィールド
              TextField(
                controller: _blockControllers[index],
                maxLines: null,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: _getBlockHint(block.type),
                ),
                onChanged: (value) {
                  block.content = value;
                },
              ),
              // ブロック操作ボタン
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: index > 0
                        ? () {
                            setState(() {
                              _note.reorderBlocks(index, index - 1);
                              final controller = _blockControllers.removeAt(index);
                              _blockControllers.insert(index - 1, controller);
                            });
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: index < _note.blocks.length - 1
                        ? () {
                            setState(() {
                              _note.reorderBlocks(index, index + 1);
                              final controller = _blockControllers.removeAt(index);
                              _blockControllers.insert(index + 1, controller);
                            });
                          }
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _note.removeBlock(block.id);
                        _blockControllers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // 表示モード
      return GestureDetector(
        onTap: () {
          setState(() {
            _isEditing = true;
          });
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _renderBlockContent(block),
          ),
        ),
      );
    }
  }

  Widget _renderBlockContent(NoteBlock block) {
    switch (block.type) {
      case BlockType.heading1:
        return Text(
          block.content,
          style: Theme.of(context).textTheme.headlineMedium,
        );
      case BlockType.heading2:
        return Text(
          block.content,
          style: Theme.of(context).textTheme.titleLarge,
        );
      case BlockType.heading3:
        return Text(
          block.content,
          style: Theme.of(context).textTheme.titleMedium,
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
        // 手書きスケッチはまだ実装されていないため、プレースホルダーを表示
        return Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(
            child: Text('手書きスケッチ（準備中）'),
          ),
        );
      case BlockType.table:
      case BlockType.list:
        // 実装予定
        return Text(block.content);
      case BlockType.text:
      default:
        return Text(block.content);
    }
  }

  String _getBlockTypeName(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'テキスト';
      case BlockType.markdown:
        return 'Markdown';
      case BlockType.heading1:
        return '見出し1';
      case BlockType.heading2:
        return '見出し2';
      case BlockType.heading3:
        return '見出し3';
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
      default:
        return type.toString().split('.').last;
    }
  }

  String _getBlockHint(BlockType type) {
    switch (type) {
      case BlockType.text:
        return 'テキストを入力';
      case BlockType.markdown:
        return 'Markdownを入力';
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        return '見出しを入力';
      case BlockType.code:
        return 'コードを入力';
      case BlockType.image:
        return '画像URLを入力';
      default:
        return '内容を入力';
    }
  }

  void _addNewBlock() {
    setState(() {
      final newBlock = NoteBlock(
        type: BlockType.text,
        content: '',
      );
      _note.addBlock(newBlock);
      _blockControllers.add(TextEditingController());
      _isEditing = true;
    });
  }

  void _saveChanges() {
    _note.title = _titleController.text;
    for (int i = 0; i < _note.blocks.length; i++) {
      _note.blocks[i].content = _blockControllers[i].text;
    }
    // 実際のアプリではこの時点でデータベースに保存
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('共有'),
              onTap: () {
                Navigator.pop(context);
                // 共有機能の実装
              },
            ),
            ListTile(
              leading: const Icon(Icons.tag),
              title: const Text('タグ編集'),
              onTap: () {
                Navigator.pop(context);
                _showTagEditor(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('削除'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        );
      },
    );
  }

  void _showTagEditor(BuildContext context) {
    final TextEditingController tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タグ編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tagController,
                decoration: const InputDecoration(
                  labelText: '新しいタグ',
                  hintText: 'タグを入力してEnterキーを押してください',
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_note.tags.contains(value)) {
                    setState(() {
                      _note.tags.add(value);
                    });
                    tagController.clear();
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _note.tags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _note.tags.remove(tag);
                      });
                      Navigator.pop(context);
                      _showTagEditor(context);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ノートの削除'),
          content: const Text('このノートを削除しますか？この操作は元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // ノート一覧画面に戻る
                Navigator.pop(context);
                // 実際のアプリではここでノートを削除
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }
}
