// lib/features/notes/presentation/services/block_operations.dart
import 'package:flutter/material.dart';
import '../../../../core/models/note.dart';

/// ブロック操作の責任を持つサービスクラス
class BlockOperationsService {
  final Note note;
  final List<TextEditingController> blockControllers;
  final List<FocusNode> blockFocusNodes;
  final Map<String, bool> blockEditingStates;
  final Function(int) onFocusChanged;
  final VoidCallback onStateChanged;

  BlockOperationsService({
    required this.note,
    required this.blockControllers,
    required this.blockFocusNodes,
    required this.blockEditingStates,
    required this.onFocusChanged,
    required this.onStateChanged,
  });

  /// 新しいブロックを追加
  void addNewBlock() {
    final newBlock = NoteBlock(
      type: BlockType.text,
      content: '',
    );
    note.addBlock(newBlock);
    
    // TextEditingControllerの作成
    final controller = TextEditingController();
    blockControllers.add(controller);
    
    // FocusNodeの作成
    final newFocusNode = FocusNode();
    
    // リスナー追加
    newFocusNode.addListener(() {
      if (newFocusNode.hasFocus) {
        onFocusChanged(blockFocusNodes.indexOf(newFocusNode));
      }
    });
    
    // リストに追加
    blockFocusNodes.add(newFocusNode);
    
    // 新しいブロックは自動的に編集状態に
    blockEditingStates[newBlock.id] = true;
    
    // 新しいブロックにフォーカスを移動
    onFocusChanged(note.blocks.length - 1);
    newFocusNode.requestFocus();
    
    onStateChanged();
  }
  
  /// 指定インデックスの後に新しいブロックを追加
  void addNewBlockAfter(int index) {
    final newBlock = NoteBlock(
      type: BlockType.text,
      content: '',
    );
    
    // ブロックをindexの後ろに挿入
    note.blocks.insert(index + 1, newBlock);
    
    // コントローラーを作成・挿入
    final controller = TextEditingController();
    blockControllers.insert(index + 1, controller);
    
    // FocusNodeを作成
    final newFocusNode = FocusNode();
    
    // リスナー追加
    newFocusNode.addListener(() {
      if (newFocusNode.hasFocus) {
        onFocusChanged(blockFocusNodes.indexOf(newFocusNode));
      }
    });
    
    // フォーカスノードを挿入
    blockFocusNodes.insert(index + 1, newFocusNode);
    
    // 新しいブロックは自動的に編集状態に
    blockEditingStates[newBlock.id] = true;
    
    // 新しいブロックにフォーカスを移動
    onFocusChanged(index + 1);
    newFocusNode.requestFocus();
    
    onStateChanged();
  }
  
  /// ブロックを上に移動
  void moveBlockUp(int index) {
    if (index <= 0) return;
    
    note.reorderBlocks(index, index - 1);
    
    final controller = blockControllers.removeAt(index);
    blockControllers.insert(index - 1, controller);
    
    final focusNode = blockFocusNodes.removeAt(index);
    blockFocusNodes.insert(index - 1, focusNode);
    
    // フォーカスを移動
    onFocusChanged(index - 1);
    focusNode.requestFocus();
    
    onStateChanged();
  }
  
  /// ブロックを下に移動
  void moveBlockDown(int index) {
    if (index >= note.blocks.length - 1) return;
    
    note.reorderBlocks(index, index + 1);
    
    final controller = blockControllers.removeAt(index);
    blockControllers.insert(index + 1, controller);
    
    final focusNode = blockFocusNodes.removeAt(index);
    blockFocusNodes.insert(index + 1, focusNode);
    
    // フォーカスを移動
    onFocusChanged(index + 1);
    focusNode.requestFocus();
    
    onStateChanged();
  }
  
  /// ブロックを削除
  void deleteBlock(int index) {
    final block = note.blocks[index];
    note.removeBlock(block.id);
    
    blockControllers.removeAt(index).dispose();
    blockFocusNodes.removeAt(index).dispose();
    blockEditingStates.remove(block.id);
    
    // 削除後はフォーカスを外す
    onFocusChanged(-1);
    
    onStateChanged();
  }
  
  /// 指定したシンボルをMathブロックに挿入
  void insertMathSymbol(int blockIndex, String symbol) {
    final controller = blockControllers[blockIndex];
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
    note.blocks[blockIndex].content = controller.text;
    onStateChanged();
  }
}