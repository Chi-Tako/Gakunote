// lib/features/notes/presentation/pages/note_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/note.dart';
import '../../../../core/services/note_service.dart';
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
  bool _isLoading = true;
  bool _hasChanges = false;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNote();
    });
  }

  @override
  void dispose() {
    // 保存されていない変更があれば保存
    _saveIfNeeded();
    
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

  // ノートを読み込む
  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteService = Provider.of<NoteService>(context, listen: false);
      final note = await noteService.getNoteById(widget.noteId);

      if (note != null) {
        setState(() {
          _note = note;
          _titleController = TextEditingController(text: _note.title);
          _initializeBlockControllers();
          _isLoading = false;
        });
      } else {
        // ノートが見つからない場合は新規作成
        final newNote = noteService.createNewNote();
        setState(() {
          _note = newNote;
          _titleController = TextEditingController(text: _note.title);
          _initializeBlockControllers();
          _isLoading = false;
        });
        // 新規ノートをすぐに保存
        await noteService.saveNote(_note);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ノートの読み込み中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ブロックコントローラーとフォーカスノードを初期化
  void _initializeBlockControllers() {
    _blockControllers.clear();
    _blockFocusNodes.clear();
    _blockEditingStates.clear();

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
        setState(() {
          _hasChanges = true;
        });
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
            // すべてのブロックの編集状態をリセット
            for (var key in _blockEditingStates.keys) {
              _blockEditingStates[key] = false;
            }
            // フォーカスされたブロックを編集状態にする
            _blockEditingStates[block.id] = true;
            _hasChanges = true;
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
          _hasChanges = true;
        });
      }
    });
  }

  // 変更があれば保存
  Future<void> _saveIfNeeded() async {
    if (_hasChanges && mounted) {
      await _saveChanges();
    }
  }

  // 変更内容を保存
  Future<void> _saveChanges() async {
    if (!mounted) return; // マウントされていない場合は処理しない
    
    setState(() {
      _isLoading = true;
    });

    try {
      // タイトルの更新
      _note.title = _titleController.text;
      
      // ブロックの内容を更新
      for (int i = 0; i < _note.blocks.length && i < _blockControllers.length; i++) {
        _note.blocks[i].content = _blockControllers[i].text;
      }

      final noteService = Provider.of<NoteService>(context, listen: false);
      await noteService.saveNote(_note);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasChanges = false;
        });
        
        // 保存成功メッセージ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ノートを保存しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ノートの保存中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 編集モードの切り替え
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

  // オプションメニューを表示
  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('ノートを削除'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation();
              },
            ),
            ListTile(
              leading: Icon(
                _note.isFavorite ? Icons.star : Icons.star_border,
              ),
              title: Text(
                _note.isFavorite ? 'お気に入りから削除' : 'お気に入りに追加',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('共有'),
              onTap: () {
                Navigator.pop(context);
                // 共有機能（後で実装）
              },
            ),
          ],
        );
      },
    );
  }

  // 削除確認ダイアログを表示
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ノートを削除'),
          content: const Text('このノートを削除してもよろしいですか？このアクションは元に戻せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteNote();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  // ノートを削除
  Future<void> _deleteNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteService = Provider.of<NoteService>(context, listen: false);
      await noteService.deleteNote(_note.id);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        Navigator.pop(context); // 前の画面に戻る
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ノートの削除中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // お気に入り状態を切り替え
  Future<void> _toggleFavorite() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteService = Provider.of<NoteService>(context, listen: false);
      await noteService.toggleFavorite(_note.id);

      setState(() {
        _note.isFavorite = !_note.isFavorite;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('お気に入り状態の変更中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('読み込み中...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: NoteAppBar(
        title: _note.title,
        isEditing: _isEditing,
        titleController: _titleController,
        titleFocusNode: _titleFocusNode,
        onEditToggle: _toggleEditMode,
        onOptionsPressed: _showOptionsMenu,
        showBackButton: true,
      ),
      body: _buildNoteContent(),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              mini: true,
              onPressed: () => _blockOperations.addNewBlock(),
              child: const Icon(Icons.add),
            )
          : FloatingActionButton(
              mini: true,
              onPressed: _saveChanges,
              child: const Icon(Icons.save),
            ),
    );
  }

  Widget _buildNoteContent() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _note.blocks.length,
      itemBuilder: (context, index) {
        final block = _note.blocks[index];
        final bool isBlockEditing = _blockEditingStates[block.id] ?? false;

        // 表示モードまたは編集中でないブロック
        if (!_isEditing || !isBlockEditing) {
          return InkWell(
            onTap: () {
              setState(() {
                // 表示モードの場合は編集モードに切り替える
                if (!_isEditing) {
                  _isEditing = true;
                }

                // すべてのブロックの編集状態をリセット
                for (var key in _blockEditingStates.keys) {
                  _blockEditingStates[key] = false;
                }

                // タップされたブロックを編集状態にする
                _blockEditingStates[block.id] = true;

                // フォーカスを設定
                _focusedBlockIndex = index;
                _blockFocusNodes[index].requestFocus();
                
                _hasChanges = true;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: renderBlockContent(context, block),
            ),
          );
        }

        // 編集モードで編集中のブロック
        return BlockEditor(
          block: block,
          index: index,
          blockControllers: _blockControllers,
          blockFocusNodes: _blockFocusNodes,
          onTypeChanged: (newType) {
            setState(() {
              block.type = newType;
              _hasChanges = true;
            });
          },
          onConfirm: () {
            setState(() {
              // ブロックの内容を保存
              block.content = _blockControllers[index].text;
              // 編集状態を解除
              _blockEditingStates[block.id] = false;
              _hasChanges = true;
            });
          },
          onMoveUp: index > 0
              ? () {
                  _blockOperations.moveBlockUp(index);
                  _hasChanges = true;
                }
              : null,
          onMoveDown: index < _note.blocks.length - 1
              ? () {
                  _blockOperations.moveBlockDown(index);
                  _hasChanges = true;
                }
              : null,
          onDelete: () {
            _blockOperations.deleteBlock(index);
            _hasChanges = true;
          },
          onAddAfter: () {
            _blockOperations.addNewBlockAfter(index);
            _hasChanges = true;
          },
        );
      },
    );
  }
}
