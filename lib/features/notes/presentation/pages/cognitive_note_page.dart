import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../../../../core/models/note.dart';
import '../../../../core/models/cognitive_note.dart';
import '../../../../core/services/note_service.dart';
import '../../services/context_prediction_engine.dart';
import '../widgets/cognitive_block_renderers.dart';
import '../widgets/prediction_suggestion_card.dart';
import 'package:pdf/widgets.dart' as pw;
import '../widgets/thought_map_navigator.dart';
import 'package:path_provider/path_provider.dart';

class CognitiveNotePage extends StatefulWidget {
  final String noteId;

  const CognitiveNotePage({
    Key? key,
    required this.noteId,
  }) : super(key: key);

  @override
  State<CognitiveNotePage> createState() => _CognitiveNotePageState();
}

class _CognitiveNotePageState extends State<CognitiveNotePage> {
  // ノートデータ
  CognitiveNote? _note;
  late TextEditingController _titleController;

  // UI状態
  bool _isLoading = true;
  bool _isEditing = false;
  bool _showThoughtMap = false;
  int _selectedBlockIndex = -1;
  bool _showPredictions = true;

  // フォーカス管理
  final FocusNode _titleFocusNode = FocusNode();
  final List<FocusNode> _blockFocusNodes = [];
  final List<TextEditingController> _blockControllers = [];

  // 予測エンジン
  final ContextPredictionEngine _predictionEngine = ContextPredictionEngine();
  List<Prediction> _currentPredictions = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNote();
    });
  }

  @override
  void dispose() {
    // コントローラーとフォーカスノードの解放
    _titleController.dispose();
    for (final controller in _blockControllers) {
      controller.dispose();
    }
    _titleFocusNode.dispose();
    for (final node in _blockFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  // ノートデータの読み込み
  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteService = Provider.of<NoteService>(context, listen: false);
      final note = await noteService.getNoteById(widget.noteId);

      if (note != null) {
        // 通常のノートをコグニティブノートに変換
        final cognitiveNote = note is CognitiveNote
            ? note
            : CognitiveNote.fromNote(note);

        setState(() {
          _note = cognitiveNote;
          _titleController.text = _note!.title;
          _initializeControllers();
          _isLoading = false;
        });

        // 予測エンジンを初期化
        _updatePredictions(-1);
      } else {
        // ノートが見つからない場合は新規作成
        final newNote = noteService.createNewNote();
        final cognitiveNote = CognitiveNote.fromNote(newNote);
        
        setState(() {
          _note = cognitiveNote;
          _titleController.text = _note!.title;
          _initializeControllers();
          _isLoading = false;
          _isEditing = true; // 新規ノートは編集モードで開始
        });
        
        // 新規ノートをすぐに保存
        await noteService.saveNote(_note!);
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

  // コントローラーとフォーカスノードの初期化
  void _initializeControllers() {
    _blockControllers.clear();
    _blockFocusNodes.clear();

    for (final block in _note!.blocks) {
      final controller = TextEditingController(text: block.content);
      _blockControllers.add(controller);

      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          final index = _blockFocusNodes.indexOf(focusNode);
          if (index != -1) {
            setState(() {
              _selectedBlockIndex = index;
            });
            _updatePredictions(index);
          }
        }
      });
      _blockFocusNodes.add(focusNode);
    }
  }

  // 予測の更新
  void _updatePredictions(int blockIndex) {
    if (_note == null) return;
    
    _predictionEngine.updateContext(_note!, blockIndex);
    
    setState(() {
      _currentPredictions = _predictionEngine.getAllPredictions();
    });
  }

  // ノートの保存
  Future<void> _saveNote() async {
    if (_note == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // タイトルを更新
      _note!.title = _titleController.text;
      
      // ブロックの内容を更新
      for (int i = 0; i < _note!.blocks.length && i < _blockControllers.length; i++) {
        _note!.blocks[i].content = _blockControllers[i].text;
      }
      
      // ノートを保存
      final noteService = Provider.of<NoteService>(context, listen: false);
      await noteService.saveNote(_note!);
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ノートを保存しました'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ノートの保存中にエラーが発生しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 新しいブロックを追加
  void _addNewBlock({BlockType? type, Map<String, dynamic>? metadata}) {
    if (_note == null) return;
    
    final newBlock = NoteBlock(
      type: type ?? BlockType.text,
      content: '',
      metadata: metadata,
    );
    
    setState(() {
      _note!.addBlock(newBlock);
      
      // 新しいコントローラーとフォーカスノードを追加
      final controller = TextEditingController();
      _blockControllers.add(controller);
      
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          final index = _blockFocusNodes.indexOf(focusNode);
          if (index != -1) {
            setState(() {
              _selectedBlockIndex = index;
            });
            _updatePredictions(index);
          }
        }
      });
      _blockFocusNodes.add(focusNode);
      
      // 新しいブロックを選択
      _selectedBlockIndex = _note!.blocks.length - 1;
      
      // フォーカスを当てる（少し遅延させる）
      Future.microtask(() {
        focusNode.requestFocus();
      });
    });
    
    // 予測を更新
    _updatePredictions(_note!.blocks.length - 1);
    
    // 変更を記録
    _predictionEngine.recordAction('add_block');
  }

  // ブロックを削除
  void _deleteBlock(int index) {
    if (_note == null || index < 0 || index >= _note!.blocks.length) return;
    
    setState(() {
      // ブロックIDを取得
      final blockId = _note!.blocks[index].id;
      
      // ブロックを削除
      _note!.removeBlock(blockId);
      
      // コントローラーとフォーカスノードを削除
      _blockControllers.removeAt(index).dispose();
      _blockFocusNodes.removeAt(index).dispose();
      
      // 選択インデックスを調整
      if (_selectedBlockIndex >= _note!.blocks.length) {
        _selectedBlockIndex = _note!.blocks.length - 1;
      }
    });
    
    // 予測を更新
    _updatePredictions(_selectedBlockIndex);
    
    // 変更を記録
    _predictionEngine.recordAction('delete_block');
  }

  // 予測を適用
  void _applyPrediction(Prediction prediction) {
    if (_note == null) return;
    
    switch (prediction.type) {
      case PredictionType.blockType:
        // ブロックタイプの予測を適用
        final blockType = prediction.data['blockType'];
        final extendedType = prediction.data['extendedType'];
        
        Map<String, dynamic>? metadata;
        if (extendedType != null) {
          metadata = {'blockType': extendedType};
          if (prediction.data['simulationType'] != null) {
            metadata['simulationType'] = prediction.data['simulationType'];
          }
        }
        
        _addNewBlock(type: blockType, metadata: metadata);
        break;
        
      case PredictionType.content:
        // コンテンツ提案を適用（例：テンプレート内容をブロックに追加）
        // 実際の実装ではさらに複雑になる
        _showContentTemplateDialog(prediction);
        break;
        
      case PredictionType.action:
        // アクション提案を適用
        _executeAction(prediction);
        break;
        
      case PredictionType.resource:
        // リソース提案を表示
        _showResourceDialog(prediction);
        break;
    }
    
    // 予測を適用したことを記録
    _predictionEngine.recordAction('apply_prediction');
  }

  // コンテンツテンプレートダイアログ
  void _showContentTemplateDialog(Prediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prediction.title),
        content: const Text('このテンプレートをノートに追加しますか？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // ここでテンプレートを追加する処理を実装
              // 実際の実装では、予測データに基づいたテンプレートを生成
              _addNewBlock(
                type: BlockType.heading2,
                metadata: {'template': prediction.title},
              );
              _addNewBlock(
                type: BlockType.text,
                metadata: {'template': prediction.description},
              );
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  // リソースダイアログ
  void _showResourceDialog(Prediction prediction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(prediction.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prediction.description),
            const SizedBox(height: 16),
            Text(
              'URL: ${prediction.data['url'] ?? "URL情報がありません"}',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('閉じる'),
          ),
          if (prediction.data['url'] != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // ここでURLを開く処理を実装（実際にはurl_launcherパッケージなどを使用）
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('URLを開きます: ${prediction.data['url']}'),
                  ),
                );
              },
              child: const Text('開く'),
            ),
        ],
      ),
    );
  }

  // タグ追加ダイアログ
  void _showAddTagDialog() {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タグを追加'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: '新しいタグ',
            hintText: '例: 重要, 試験対策, 復習など',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              final tag = textController.text.trim();
              if (tag.isNotEmpty && _note != null) {
                setState(() {
                  if (!_note!.tags.contains(tag)) {
                    _note!.tags.add(tag);
                  }
                });
                _saveNote();
              }
              Navigator.of(context).pop();
            },
            child: const Text('追加'),
          ),
        ],
      ),
    ).then((_) => textController.dispose());
  }

  // 要約ダイアログ
  void _showSummaryDialog() {
    // 実際の実装では、ノートの内容を自動的に要約する処理を追加
    // ここでは簡単なデモとして、見出しと最初の数ブロックを抽出
    
    final summary = StringBuffer();
    
    if (_note != null) {
      // タイトルを追加
      summary.writeln('# ${_note!.title}');
      summary.writeln();
      
      // 見出しを抽出
      for (final block in _note!.blocks) {
        if (block.type == BlockType.heading1 || 
            block.type == BlockType.heading2) {
          summary.writeln('- ${block.content}');
        }
      }
      
      // キーコンセプトを抽出（コグニティブノートの場合）
      if (_note! is CognitiveNote) {
        final cognitiveNote = _note! as CognitiveNote;
        final keyConcepts = cognitiveNote.extractKeyConcepts();
        
        if (keyConcepts.isNotEmpty) {
          summary.writeln('\n## キーコンセプト:');
          for (final concept in keyConcepts) {
            summary.writeln('- ${concept.content}');
          }
        }
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ノート要約'),
        content: Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Text(summary.toString()),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('閉じる'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              
              // 要約をノートの先頭に追加
              if (_note != null) {
                setState(() {
                  final summaryBlock = NoteBlock(
                    type: BlockType.markdown,
                    content: summary.toString(),
                    metadata: {'blockType': 'summary'},
                  );
                  
                  _note!.blocks.insert(0, summaryBlock);
                  
                  // コントローラーとフォーカスノードを追加
                  final controller = TextEditingController(text: summary.toString());
                  _blockControllers.insert(0, controller);
                  
                  final focusNode = FocusNode();
                  _blockFocusNodes.insert(0, focusNode);
                  
                  // インデックスを調整
                  _selectedBlockIndex++;
                });
                
                // 変更を保存
                _saveNote();
              }
            },
            child: const Text('ノートに追加'),
          ),
        ],
      ),
    );
  }

 // PDF形式でエクスポート
 Future<void> _exportToPdf() async {
  if (_note == null) return;

  setState(() {
   _isLoading = true;
  });

  try {
   final pdf = pw.Document();

   pdf.addPage(pw.Page(
    build: (pw.Context context) {
     return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
       pw.Text(_note!.title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
       pw.SizedBox(height: 16),
       for (final block in _note!.blocks)
        pw.Text(block.content),
      ],
     );
    },
   ));

   // 保存先ディレクトリを取得
   final directory = await getApplicationDocumentsDirectory();
   final file = File('${directory.path}/${_note!.title}.pdf');

   // PDFを保存
   await file.writeAsBytes(await pdf.save());

   setState(() {
    _isLoading = false;
   });

   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text('PDFを保存しました: ${file.path}'),
      backgroundColor: Colors.green,
     ),
    );
   }
  } catch (e) {
   setState(() {
    _isLoading = false;
   });

   if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
      content: Text('PDFの保存中にエラーが発生しました: $e'),
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
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _titleController,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'タイトルを入力',
                  hintStyle: TextStyle(
                    color: Colors.white70,
                  ),
                ),
              )
            : Text(_note?.title ?? '無題のノート'),
        actions: [
          // 思考マップ表示/非表示ボタン
          IconButton(
            icon: Icon(
              _showThoughtMap ? Icons.map : Icons.map_outlined,
              color: _showThoughtMap ? Colors.amber : null,
            ),
            tooltip: '思考マップ',
            onPressed: () {
              setState(() {
                _showThoughtMap = !_showThoughtMap;
              });
            },
          ),
          // 予測表示/非表示ボタン
          IconButton(
            icon: Icon(
              _showPredictions ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _showPredictions ? Colors.amber : null,
            ),
            tooltip: '予測と提案',
            onPressed: () {
              setState(() {
                _showPredictions = !_showPredictions;
              });
            },
          ),
          // 編集/保存ボタン
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            tooltip: _isEditing ? '保存' : '編集',
            onPressed: () {
              if (_isEditing) {
                _saveNote();
              }
              setState(() {
                _isEditing = !_isEditing;
              });
            },
          ),
          // メニューボタン
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'tags':
                  _showAddTagDialog();
                  break;
                case 'summary':
                  _showSummaryDialog();
                  break;
                case 'export':
                  // エクスポート機能（実装予定）
                  break;
                case 'delete':
                  // 削除確認ダイアログ（実装予定）
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'tags',
                child: Row(
                  children: const [
                    Icon(Icons.label, size: 20),
                    SizedBox(width: 8),
                    Text('タグを編集'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'summary',
                child: Row(
                  children: const [
                    Icon(Icons.summarize, size: 20),
                    SizedBox(width: 8),
                    Text('要約を生成'),
                  ],
                ),
              ),
    PopupMenuItem( // PDFエクスポートのオプションを追加
     value: 'export_pdf',
     child: Row(
      children: const [
       Icon(Icons.picture_as_pdf, size: 20),
       SizedBox(width: 8),
       Text('PDFとしてエクスポート'),
      ],
     ),
    ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: const [
                    Icon(Icons.upload_file, size: 20),
                    SizedBox(width: 8),
                    Text('エクスポート'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: const [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('ノートを削除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  // ボディビルダー
  Widget _buildBody() {
    return Row(
      children: [
        // メインコンテンツエリア
        Expanded(
          flex: 3,
          child: _buildNoteContent(),
        ),
        
        // 思考マップパネル（条件付き表示）
        if (_showThoughtMap)
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              child: _buildThoughtMapPanel(),
            ),
          ),
      ],
    );
  }

  // ノートコンテンツビルダー
  Widget _buildNoteContent() {
    if (_note == null || _note!.blocks.isEmpty) {
      return Center(
        child: _isEditing
            ? const Text('新規ブロックを追加してください')
            : const Text('このノートにはまだ内容がありません'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // タグ一覧
        if (_note!.tags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _note!.tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: _isEditing
                  ? () {
                      setState(() {
                        _note!.tags.remove(tag);
                      });
                      _saveNote();
                    }
                  : null,
            )).toList(),
          ),
          const SizedBox(height: 16),
        ],
        
        // ブロック一覧
        ...List.generate(_note!.blocks.length, (index) {
          final block = _note!.blocks[index];
          
          if (_isEditing && index == _selectedBlockIndex) {
            // 編集モードで選択されているブロック
            return _buildBlockEditor(index);
          } else {
            // 表示モード、または選択されていないブロック
            return CognitiveBlockRenderer(
              block: block,
              isSelected: index == _selectedBlockIndex,
              showRelations: true,
              onTap: (block) {
                setState(() {
                  _selectedBlockIndex = index;
                });
                
                if (_isEditing) {
                  // フォーカスを設定
                  _blockFocusNodes[index].requestFocus();
                }
                
                _updatePredictions(index);
              },
              onLongPress: _isEditing
                  ? (block) {
                      _showBlockOptionsMenu(context, index);
                    }
                  : null,
            );
          }
        }),
      ],
    );
  }

  // ブロックエディタービルダー
  Widget _buildBlockEditor(int index) {
    final block = _note!.blocks[index];
    
    // 実際の実装では、ブロックタイプに応じた適切なエディタを表示
    // ここでは簡略化のため、基本的なテキストエディタを表示
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // ブロックタイプ選択
          Row(
            children: [
              DropdownButton<BlockType>(
                value: block.type,
                onChanged: (BlockType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      block.type = newValue;
                    });
                  }
                },
                items: BlockType.values.map((BlockType type) {
                  return DropdownMenuItem<BlockType>(
                    value: type,
                    child: Text(_getBlockTypeName(type)),
                  );
                }).toList(),
              ),
              const Spacer(),
              // ブロック操作ボタン
              IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20),
                onPressed: index > 0
                    ? () {
                        // ブロックを上に移動
                        setState(() {
                          _note!.reorderBlocks(index, index - 1);
                          
                          // コントローラとフォーカスノードも移動
                          final tempController = _blockControllers.removeAt(index);
                          _blockControllers.insert(index - 1, tempController);
                          
                          final tempFocusNode = _blockFocusNodes.removeAt(index);
                          _blockFocusNodes.insert(index - 1, tempFocusNode);
                          
                          _selectedBlockIndex = index - 1;
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward, size: 20),
                onPressed: index < _note!.blocks.length - 1
                    ? () {
                        // ブロックを下に移動
                        setState(() {
                          _note!.reorderBlocks(index, index + 1);
                          
                          // コントローラとフォーカスノードも移動
                          final tempController = _blockControllers.removeAt(index);
                          _blockControllers.insert(index + 1, tempController);
                          
                          final tempFocusNode = _blockFocusNodes.removeAt(index);
                          _blockFocusNodes.insert(index + 1, tempFocusNode);
                          
                          _selectedBlockIndex = index + 1;
                        });
                      }
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20),
                onPressed: () => _deleteBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ブロックコンテンツエディタ
          TextField(
            controller: _blockControllers[index],
            focusNode: _blockFocusNodes[index],
            maxLines: null,
            decoration: InputDecoration(
              hintText: _getBlockHint(block.type),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              // リアルタイムで内容を更新
              setState(() {
                block.content = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ブロックオプションメニュー
  void _showBlockOptionsMenu(BuildContext context, int index) {
    final block = _note!.blocks[index];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.content_copy),
            title: const Text('ブロックを複製'),
            onTap: () {
              Navigator.pop(context);
              
              setState(() {
                // ブロックを複製
                final newBlock = NoteBlock(
                  type: block.type,
                  content: block.content,
                  metadata: Map.from(block.metadata),
                );
                
                _note!.blocks.insert(index + 1, newBlock);
                
                // コントローラとフォーカスノードを追加
                final controller = TextEditingController(text: block.content);
                _blockControllers.insert(index + 1, controller);
                
                final focusNode = FocusNode();
                _blockFocusNodes.insert(index + 1, focusNode);
                
                _selectedBlockIndex = index + 1;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('ブロックを削除'),
            onTap: () {
              Navigator.pop(context);
              _deleteBlock(index);
            },
          ),
          if (_note is CognitiveNote) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('ブロックを概念として扱う'),
              onTap: () {
                Navigator.pop(context);
                
                // ブロックを概念としてマーク
                if (block is CognitiveBlock) {
                  setState(() {
                    block.cognitiveMetadata['blockType'] = 'concept';
                    block.initConceptMetadata();
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.connect_without_contact),
              title: const Text('他のブロックと関連付け'),
              onTap: () {
                Navigator.pop(context);
                _showRelationDialog(index);
              },
            ),
          ],
        ],
      ),
    );
  }

  // ブロック関連付けダイアログ
  void _showRelationDialog(int sourceIndex) {
    if (_note == null || !(_note is CognitiveNote)) return;
    
    final cognitiveNote = _note as CognitiveNote;
    final sourceBlock = cognitiveNote.blocks[sourceIndex];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ブロックを関連付け'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: cognitiveNote.blocks.length,
            itemBuilder: (context, index) {
              if (index == sourceIndex) return const SizedBox.shrink();
              
              final targetBlock = cognitiveNote.blocks[index];
              
              return ListTile(
                title: Text(
                  targetBlock.content.isNotEmpty
                      ? (targetBlock.content.length > 30
                          ? '${targetBlock.content.substring(0, 30)}...'
                          : targetBlock.content)
                      : 'ブロック ${index + 1}',
                ),
                subtitle: Text(_getBlockTypeName(targetBlock.type)),
                onTap: () {
                  Navigator.pop(context);
                  _showRelationTypeDialog(sourceBlock.id, targetBlock.id);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  // 関連タイプ選択ダイアログ
  void _showRelationTypeDialog(String sourceBlockId, String targetBlockId) {
    if (_note == null || !(_note is CognitiveNote)) return;
    
    final cognitiveNote = _note as CognitiveNote;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('関連タイプを選択'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: BlockRelationType.values.map((type) => ListTile(
            title: Text(_getRelationTypeName(type)),
            onTap: () {
              Navigator.pop(context);
              
              setState(() {
                cognitiveNote.addRelation(
                  sourceBlockId,
                  targetBlockId,
                  type,
                );
              });
              
              _saveNote();
            },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  // 思考マップパネル
  Widget _buildThoughtMapPanel() {
    if (_note == null || !(_note is CognitiveNote)) {
      return const Center(
        child: Text('思考マップは通常のノートでは利用できません'),
      );
    }
    
    final cognitiveNote = _note as CognitiveNote;
    final conceptMap = cognitiveNote.generateConceptMap();
    
    return Column(
      children: [
        AppBar(
          automaticallyImplyLeading: false,
          title: const Text('思考マップ'),
