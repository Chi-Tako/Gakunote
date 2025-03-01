// lib/features/notes/presentation/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import '../../../../core/models/note.dart';
import '../widgets/note_app_bar.dart';
import '../widgets/block_editor.dart';
import '../services/block_operations.dart';

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
    _note = BlockOperations.getDummyNote(widget.noteId);
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
          });
        }
      });
      _blockFocusNodes.add(newFocusNode);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: NoteAppBar(
        isEditing: _isEditing,
        titleController: _titleController,
        noteTitle: _note.title,
        titleFocusNode: _titleFocusNode,
        onEditPressed: () {
          setState(() {
            _isEditing = !_isEditing;
          });
        },
        onMoreVertPressed: () {
          // _showOptions(context);
        },
      ),
      body: BlockEditor(
        note: _note,
        blockControllers: _blockControllers,
        blockFocusNodes: _blockFocusNodes,
        focusedBlockIndex: _focusedBlockIndex,
        onBlockFocused: (index) {
          setState(() {
            _focusedBlockIndex = index;
          });
        },
        onReorderBlock: (oldIndex, newIndex) {
          setState(() {
            final controller = _blockControllers.removeAt(oldIndex);
            _blockControllers.insert(newIndex, controller);
            final focusNode = _blockFocusNodes.removeAt(oldIndex);
            _blockFocusNodes.insert(newIndex, focusNode);
            _focusedBlockIndex = newIndex;
            focusNode.requestFocus();
          });
        },
        onRemoveBlock: (blockId) {
          setState(() {
            _note.removeBlock(blockId);
            _blockControllers.removeAt(_note.blocks.indexWhere((block) => block.id == blockId));
            _blockFocusNodes.removeAt(_note.blocks.indexWhere((block) => block.id == blockId)).dispose();
          });
        },
        onAddNewBlockAfter: (index) {
          setState(() {
            final newBlock = NoteBlock(
              type: BlockType.text,
              content: '',
            );
            _note.blocks.insert(index + 1, newBlock);

            final controller = TextEditingController();
            _blockControllers.insert(index + 1, controller);

            final newFocusNode = FocusNode();
            newFocusNode.addListener(() {
              if (newFocusNode.hasFocus) {
                setState(() {
                  _focusedBlockIndex = _blockFocusNodes.indexOf(newFocusNode);
                });
              }
            });
            _blockFocusNodes.insert(index + 1, newFocusNode);
            _focusedBlockIndex = index + 1;
            newFocusNode.requestFocus();
          });
        },
        blockEditingStates: _blockEditingStates,
        onBlockContentChanged: (blockId, content) {
          setState(() {
            _note.blocks.firstWhere((block) => block.id == blockId).content = content;
          });
        },
        onBlockTypeChanged: (blockId, blockType) {
          setState(() {
            _note.blocks.firstWhere((block) => block.id == blockId).type = blockType;
          });
        },
      ),
      floatingActionButton: _isEditing ? FloatingActionButton(
        mini: true,
        onPressed: () {
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
