// lib/features/notes/presentation/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/models/note.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import '../widgets/math_block_editor.dart';

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
  
  // フォーカス管理のためのノード
  final FocusNode _titleFocusNode = FocusNode();
  final List<FocusNode> _blockFocusNodes = [];
  
  // 現在フォーカスされているブロックのインデックス
  int _focusedBlockIndex = -1;

  // ブロックの編集状態を追跡するマップ
  final Map<String, bool> _blockEditingStates = {};

  @override
  void initState() {
    super.initState();
    // 実際のアプリではデータベースから取得
    // ここではダミーデータを使用
    _note = _getDummyNote(widget.noteId);
    _titleController = TextEditingController(text: _note.title);
    
    // 各ブロックのコントローラーとフォーカスノードを初期化
    for (var block in _note.blocks) {
      _blockControllers.add(TextEditingController(text: block.content));
      
      // 先にFocusNodeを作成してから、リスナーを追加
      final newFocusNode = FocusNode();
      newFocusNode.addListener(() {
        if (newFocusNode.hasFocus) {
          setState(() {
            _focusedBlockIndex = _blockFocusNodes.indexOf(newFocusNode);
            // フォーカスされたら編集状態にする
            _blockEditingStates[block.id] = true;
          });
        }
      });
      _blockFocusNodes.add(newFocusNode);
      
      // 初期状態では編集中ではない
      _blockEditingStates[block.id] = false;
    }
    
    // タイトルにフォーカスがあたったときの処理
    _titleFocusNode.addListener(() {
      if (_titleFocusNode.hasFocus) {
        setState(() {
          _focusedBlockIndex = -1;
        });
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (var controller in _blockControllers) {
      controller.dispose();
    }
    _titleFocusNode.dispose();
    for (var node in _blockFocusNodes) {
      node.dispose();
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
                focusNode: _titleFocusNode,
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
                  // 全てのブロックの編集状態をリセット
                  for (var key in _blockEditingStates.keys) {
                    _blockEditingStates[key] = false;
                  }
                }
                _isEditing = !_isEditing;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // _showOptions(context);
            },
          ),
        ],
      ),
      body: _buildNoteContent(),
      floatingActionButton: _isEditing ? FloatingActionButton(
        mini: true,
        onPressed: _addNewBlock,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildNoteContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _note.blocks.length,
      itemBuilder: (context, index) {
        final block = _note.blocks[index];
        return _buildBlockWidget(block, index);
      },
    );
  }

  Widget _buildBlockWidget(NoteBlock block, int index) {
    final bool isBlockFocused = _isEditing && _focusedBlockIndex == index;
    final bool isBlockEditing = _blockEditingStates[block.id] ?? false;
    
    // 表示モードまたはフォーカスされていないブロック
    if (!_isEditing || !isBlockFocused || !isBlockEditing) {
      return InkWell(
        onTap: () {
          if (!_isEditing) {
            setState(() {
              _isEditing = true;
            });
          }
          // フォーカスを当該ブロックに移動
          _blockFocusNodes[index].requestFocus();
          setState(() {
            _blockEditingStates[block.id] = true;
          });
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
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
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
                      child: Text(_getBlockTypeName(value), style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                ),
                const Spacer(),
                // 確定ボタン
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      // ブロックの内容を保存
                      block.content = _blockControllers[index].text;
                      // 編集状態を解除
                      _blockEditingStates[block.id] = false;
                    });
                  },
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
                  onPressed: index > 0
                      ? () {
                          setState(() {
                            _note.reorderBlocks(index, index - 1);
                            final controller = _blockControllers.removeAt(index);
                            _blockControllers.insert(index - 1, controller);
                            final focusNode = _blockFocusNodes.removeAt(index);
                            _blockFocusNodes.insert(index - 1, focusNode);
                            _focusedBlockIndex = index - 1;
                            // フォーカスを移動
                            focusNode.requestFocus();
                          });
                        }
                      : null,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.arrow_downward, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: index < _note.blocks.length - 1
                      ? () {
                          setState(() {
                            _note.reorderBlocks(index, index + 1);
                            final controller = _blockControllers.removeAt(index);
                            _blockControllers.insert(index + 1, controller);
                            final focusNode = _blockFocusNodes.removeAt(index);
                            _blockFocusNodes.insert(index + 1, focusNode);
                            _focusedBlockIndex = index + 1;
                            // フォーカスを移動
                            focusNode.requestFocus();
                          });
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
                    setState(() {
                      _note.removeBlock(block.id);
                      _blockControllers.removeAt(index);
                      final removedNode = _blockFocusNodes.removeAt(index);
                      removedNode.dispose();
                      _blockEditingStates.remove(block.id);

                      // 削除後はフォーカスを外す（編集状態からの脱出）
                      _focusedBlockIndex = -1;
                      FocusScope.of(context).unfocus();

                      // または必要であれば、次の操作を明示的に選べるようなUIを表示
                      // _showPostDeletionOptions(context);
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _addNewBlockAfter(index);
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
                controller: _blockControllers[index],
                focusNode: _blockFocusNodes[index],
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
                  block.content = value;
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
            controller: _blockControllers[index],
            focusNode: _blockFocusNodes[index],
            maxLines: null,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: 'LaTeX形式で数式を入力（例: \\sum_{i=0}^n i^2 = \\frac{n(n+1)(2n+1)}{6}）',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              block.content = value;
              setState(() {}); // プレビューを更新するために再描画
            },
          ),
          
          // 数式プレビュー
          if (_blockControllers[index].text.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              child: Math.tex(
                _blockControllers[index].text,
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

  void _addNewBlock() {
    setState(() {
      final newBlock = NoteBlock(
        type: BlockType.text,
        content: '',
      );
      _note.addBlock(newBlock);
      
      // TextEditingControllerの作成
      final controller = TextEditingController();
      _blockControllers.add(controller);
      
      // FocusNodeの作成 - 宣言を先に行う
      final newFocusNode = FocusNode();
      
      // リスナー追加
      newFocusNode.addListener(() {
        if (newFocusNode.hasFocus) {
          setState(() {
            _focusedBlockIndex = _blockFocusNodes.indexOf(newFocusNode);
          });
        }
      });
      
      // リストに追加
      _blockFocusNodes.add(newFocusNode);
      
      _isEditing = true;
      
      // 新しいブロックは自動的に編集状態に
      _blockEditingStates[newBlock.id] = true;
      
      // 新しいブロックにフォーカスを移動
      _focusedBlockIndex = _note.blocks.length - 1;
      newFocusNode.requestFocus();
    });
  }
  
  void _addNewBlockAfter(int index) {
    setState(() {
      final newBlock = NoteBlock(
        type: BlockType.text,
        content: '',
      );
      
      // ブロックをindexの後ろに挿入
      _note.blocks.insert(index + 1, newBlock);
      
      // コントローラーを作成・挿入
      final controller = TextEditingController();
      _blockControllers.insert(index + 1, controller);
      
      // FocusNodeを作成 - 宣言を先に行う
      final newFocusNode = FocusNode();
      
      // リスナー追加
      newFocusNode.addListener(() {
        if (newFocusNode.hasFocus) {
          setState(() {
            _focusedBlockIndex = _blockFocusNodes.indexOf(newFocusNode);
          });
        }
      });
      
      // フォーカスノードを挿入
      _blockFocusNodes.insert(index + 1, newFocusNode);
      
      // 新しいブロックは自動的に編集状態に
      _blockEditingStates[newBlock.id] = true;
      
      // 新しいブロックにフォーカスを移動
      _focusedBlockIndex = index + 1;
      newFocusNode.requestFocus();
    });
  }

  void _saveChanges() {
    _note.title = _titleController.text;
    for (int i = 0; i < _note.blocks.length; i++) {
      _note.blocks[i].content = _blockControllers[i].text;
    }
    // 実際のアプリではこの時点でデータベースに保存
  }

  // 数式記号ボタン
  Widget _mathSymbolButton(String symbol, int blockIndex) {
    return InkWell(
      onTap: () {
        final controller = _blockControllers[blockIndex];
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
        _note.blocks[blockIndex].content = controller.text;
        setState(() {}); // 数式プレビューを更新
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
