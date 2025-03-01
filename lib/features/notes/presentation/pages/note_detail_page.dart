// lib/features/notes/presentation/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import '../../../../core/models/note.dart';
import '../services/block_operations.dart';
import '../widgets/note_app_bar.dart';
import '../widgets/block_editor.dart';
import '../widgets/block_renderers.dart';

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
  
  // ブロック操作サービス
  late BlockOperationsService _blockOperations;

  @override
  void initState() {
    super.initState();
    // 実際のアプリではデータベースから取得
    // ここではダミーデータを使用
    _note = _getDummyNote(widget.noteId);
    _titleController = TextEditingController(text: _note.title);
    
    // ブロック操作サービスの初期化
    _blockOperations = BlockOperationsService(
      note: _note,
      blockControllers: _blockControllers,
      blockFocusNodes: _blockFocusNodes,
      blockEditingStates: _blockEditingStates,
      onFocusChanged: (index) {
        setState(() {
          _focusedBlockIndex = index;
        });
      },
      onStateChanged: () {
        setState(() {});
      },
    );
    
    // 各ブロックのコントローラーとフォーカスノードを初期化
    for (var block in _note.blocks) {
      final controller = TextEditingController(text: block.content);
      _blockControllers.add(controller);
      
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

  void _saveChanges() {
    _note.title = _titleController.text;
    for (int i = 0; i < _note.blocks.length; i++) {
      _note.blocks[i].content = _blockControllers[i].text;
    }
    // 実際のアプリではこの時点でデータベースに保存
  }

  void _toggleEditMode() {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NoteAppBar(
        title: _note.title,
        isEditing: _isEditing,
        titleController: _titleController,
        titleFocusNode: _titleFocusNode,
        onEditToggle: _toggleEditMode,
        onOptionsPressed: () {
          // オプションメニューを表示（後で実装）
        },
      ),
      body: _buildNoteContent(),
      floatingActionButton: _isEditing 
        ? FloatingActionButton(
            mini: true,
            onPressed: () => _blockOperations.addNewBlock(),
            child: const Icon(Icons.add),
          ) 
        : null,
    );
  }

  Widget _buildNoteContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _note.blocks.length,
      itemBuilder: (context, index) {
        final block = _note.blocks[index];
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
              child: renderBlockContent(context, block),
            ),
          );
        }
        
        // 編集モードでフォーカスされていて編集中のブロック
        return BlockEditor(
          block: block,
          index: index,
          blockControllers: _blockControllers,
          blockFocusNodes: _blockFocusNodes,
          onTypeChanged: (newType) {
            setState(() {
              block.type = newType;
            });
          },
          onConfirm: () {
            setState(() {
              // ブロックの内容を保存
              block.content = _blockControllers[index].text;
              // 編集状態を解除
              _blockEditingStates[block.id] = false;
            });
          },
          onMoveUp: index > 0
            ? () {
                _blockOperations.moveBlockUp(index);
              }
            : null,
          onMoveDown: index < _note.blocks.length - 1
            ? () {
                _blockOperations.moveBlockDown(index);
              }
            : null,
          onDelete: () {
            _blockOperations.deleteBlock(index);
          },
          onAddAfter: () {
            _blockOperations.addNewBlockAfter(index);
          },
        );
      },
    );
  }
}