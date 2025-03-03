// lib/features/notes/presentation/widgets/thought_map_navigator.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/models/cognitive_note.dart';

/// 思考マップナビゲーターウィジェット
class ThoughtMapNavigator extends StatefulWidget {
  final CognitiveNote note;
  final Map<String, dynamic> conceptMap;
  final Function(String blockId) onNodeTap;

  const ThoughtMapNavigator({
    Key? key,
    required this.note,
    required this.conceptMap,
    required this.onNodeTap,
  }) : super(key: key);

  @override
  State<ThoughtMapNavigator> createState() => _ThoughtMapNavigatorState();
}

class _ThoughtMapNavigatorState extends State<ThoughtMapNavigator> {
  // マップの表示形式
  bool _showGraph = true;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset? _startPanPosition;
  Offset? _lastFocalPoint;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 表示切替タブ
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showGraph = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _showGraph
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'グラフ表示',
                      style: TextStyle(
                        color: _showGraph
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: _showGraph ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _showGraph = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: !_showGraph
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'リスト表示',
                      style: TextStyle(
                        color: !_showGraph
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: !_showGraph ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        // 検索バー
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '思考マップを検索...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        // グラフ/リスト表示エリア
        Expanded(
          child: _showGraph
              ? _buildGraphView()
              : _buildListView(),
        ),
      ],
    );
  }

  // グラフ表示ビルダー
  Widget _buildGraphView() {
    // ノードとエッジの情報
    final nodes = widget.conceptMap['nodes'] as List;
    final edges = widget.conceptMap['edges'] as List;
    
    if (nodes.isEmpty) {
      return const Center(
        child: Text('表示するノードがありません'),
      );
    }
    
    // ズームとパンが可能なインタラクティブビュー
    return GestureDetector(
      onScaleStart: (details) {
        _startPanPosition = details.focalPoint;
        _lastFocalPoint = details.focalPoint;
      },
      onScaleUpdate: (details) {
        setState(() {
          if (details.scale == 1.0) {
            // パンのみ
            final delta = details.focalPoint - (_lastFocalPoint ?? Offset.zero);
            _offset += delta / _scale;
            _lastFocalPoint = details.focalPoint;
          } else {
            // ズーム
            final newScale = (_scale * details.scale).clamp(0.5, 3.0);
            final focalPoint = details.focalPoint;
            final focalPointDelta = focalPoint - (_startPanPosition ?? Offset.zero);
            
            // ズーム時のオフセット調整
            _offset = _offset + focalPointDelta / (_scale * 100);
            _scale = newScale;
          }
        });
      },
      child: ClipRect(
        child: CustomPaint(
          painter: ConceptGraphPainter(
            nodes: nodes,
            edges: edges,
            scale: _scale,
            offset: _offset,
            selectedNodeId: widget.note.blocks.isNotEmpty && widget.note.blocks.length > 0
                ? widget.note.blocks[0].id
                : null,
          ),
          child: Stack(
            children: [
              // ノードを表示
              ...nodes.map((node) {
                final nodeId = node['id'] as String;
                final label = node['label'] as String;
                final type = node['type'] as String;
                
                // 各ノードの位置を計算（実際の実装ではもっと複雑なレイアウトアルゴリズムを使用）
                final index = nodes.indexOf(node);
                final totalNodes = nodes.length;
                
                // 円形レイアウト
                final angle = 2 * 3.14159 * index / totalNodes;
                const radius = 100.0;
                final x = radius * _scale * Math.cos(angle) + 150 * _scale + _offset.dx;
                final y = radius * _scale * Math.sin(angle) + 150 * _scale + _offset.dy;
                
                // ノードの色（タイプによって異なる）
                Color nodeColor;
                switch (type) {
                  case 'heading1':
                  case 'heading2':
                  case 'heading3':
                    nodeColor = Colors.blue;
                    break;
                  case 'text':
                    nodeColor = Colors.green;
                    break;
                  case 'markdown':
                    nodeColor = Colors.purple;
                    break;
                  case 'code':
                    nodeColor = Colors.grey;
                    break;
                  case 'math':
                    nodeColor = Colors.orange;
                    break;
                  default:
                    nodeColor = Colors.blueGrey;
                }
                
                return Positioned(
                  left: x,
                  top: y,
                  child: GestureDetector(
                    onTap: () => widget.onNodeTap(nodeId),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: nodeColor.withOpacity(0.2),
                        border: Border.all(
                          color: nodeColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        maxWidth: 120,
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          color: nodeColor.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // リスト表示ビルダー
  Widget _buildListView() {
    // ブロックをキーコンセプト順にソート
    final keyConcepts = widget.note.extractKeyConcepts();
    final conceptIds = keyConcepts.map((block) => block.id).toList();
    
    // 残りのブロックも追加
    final remainingBlocks = widget.note.blocks
        .where((block) => !conceptIds.contains(block.id))
        .toList();
    
    final allBlocks = [...keyConcepts, ...remainingBlocks];
    
    return ListView.builder(
      itemCount: allBlocks.length,
      itemBuilder: (context, index) {
        final block = allBlocks[index];
        final isKeyConcept = index < keyConcepts.length;
        
        return ListTile(
          title: Text(
            block.content.isNotEmpty
                ? (block.content.length > 50
                    ? '${block.content.substring(0, 50)}...'
                    : block.content)
                : 'ブロック ${index + 1}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_getBlockTypeName(block.type)),
          leading: Icon(
            _getBlockTypeIcon(block.type),
            color: isKeyConcept ? Colors.amber : null,
          ),
          trailing: isKeyConcept
              ? const Icon(Icons.star, color: Colors.amber, size: 16)
              : null,
          onTap: () => widget.onNodeTap(block.id),
        );
      },
    );
  }

  // ブロックタイプ名の取得
  String _getBlockTypeName(BlockType type) {
    switch (type) {
      case BlockType.heading1:
        return '見出し 1';
      case BlockType.heading2:
        return '見出し 2';
      case BlockType.heading3:
        return '見出し 3';
      case BlockType.text:
        return 'テキスト';
      case BlockType.markdown:
        return 'Markdown';
      case BlockType.code:
        return 'コード';
      case BlockType.image:
        return '画像';
      case BlockType.math:
        return '数式';
      default:
        return type.toString().split('.').last;
    }
  }

  // ブロックタイプアイコンの取得
  IconData _getBlockTypeIcon(BlockType type) {
    switch (type) {
      case BlockType.heading1:
      case BlockType.heading2:
      case BlockType.heading3:
        return Icons.title;
      case BlockType.text:
        return Icons.text_fields;
      case BlockType.markdown:
        return Icons.notes;
      case BlockType.code:
        return Icons.code;
      case BlockType.image:
        return Icons.image;
      case BlockType.math:
        return Icons.functions;
      default:
        return Icons.block;
    }
  }
}

/// 概念グラフのカスタムペインター
class ConceptGraphPainter extends CustomPainter {
  final List nodes;
  final List edges;
  final double scale;
  final Offset offset;
  final String? selectedNodeId;

  ConceptGraphPainter({
    required this.nodes,
    required this.edges,
    required this.scale,
    required this.offset,
    this.selectedNodeId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // エッジ（関係性）を描画
    for (final edge in edges) {
      final sourceId = edge['source'] as String;
      final targetId = edge['target'] as String;
      final label = edge['label'] as String? ?? '';
      
      // ソースとターゲットのノードを検索
      final sourceNode = nodes.firstWhere(
        (node) => node['id'] == sourceId,
        orElse: () => null,
      );
      final targetNode = nodes.firstWhere(
        (node) => node['id'] == targetId,
        orElse: () => null,
      );
      
      if (sourceNode == null || targetNode == null) continue;
      
      // ノードの位置を計算
      final sourceIndex = nodes.indexOf(sourceNode);
      final targetIndex = nodes.indexOf(targetNode);
      final totalNodes = nodes.length;
      
      final sourceAngle = 2 * 3.14159 * sourceIndex / totalNodes;
      final targetAngle = 2 * 3.14159 * targetIndex / totalNodes;
      
      const radius = 100.0;
      final sourceX = radius * scale * Math.cos(sourceAngle) + 150 * scale + offset.dx;
      final sourceY = radius * scale * Math.sin(sourceAngle) + 150 * scale + offset.dy;
      final targetX = radius * scale * Math.cos(targetAngle) + 150 * scale + offset.dx;
      final targetY = radius * scale * Math.sin(targetAngle) + 150 * scale + offset.dy;
      
      // エッジの始点と終点
      final start = Offset(sourceX, sourceY);
      final end = Offset(targetX, targetY);
      
      // エッジの色
      Color color;
      switch (label) {
        case 'reference':
          color = Colors.blue;
          break;
        case 'explains':
          color = Colors.green;
          break;
        case 'examples':
          color = Colors.orange;
          break;
        case 'depends':
          color = Colors.red;
          break;
        case 'contrasts':
          color = Colors.purple;
          break;
        case 'sequence':
          color = Colors.teal;
          break;
        default:
          color = Colors.grey;
      }
      
      // 矢印を描画
      _drawArrow(canvas, start, end, color);
      
      // ラベルを描画（実際の実装ではもっと複雑になる）
      if (label.isNotEmpty) {
        final midpoint = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final textSpan = TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 10 * scale,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          midpoint - Offset(textPainter.width / 2, textPainter.height / 2),
        );
      }
    }
  }

  // 矢印を描画するヘルパーメソッド
  void _drawArrow(Canvas canvas, Offset start, Offset end, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.stroke;
    
    // 線を描画
    canvas.drawLine(start, end, paint);
    
    // 矢印の先端を描画
    final direction = (end - start).normalize();
    final arrowSize = 5.0 * scale;
    
    final tip = end;
    final arrowP1 = tip - direction.scale(arrowSize, arrowSize) + direction.scale(arrowSize, -arrowSize);
    final arrowP2 = tip - direction.scale(arrowSize, arrowSize) - direction.scale(arrowSize, -arrowSize);
    
    final arrowPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5 * scale
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(arrowP1.dx, arrowP1.dy)
      ..lineTo(arrowP2.dx, arrowP2.dy)
      ..close();
    
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // 必要に応じて再描画
    if (oldDelegate is ConceptGraphPainter) {
      return oldDelegate.scale != scale ||
          oldDelegate.offset != offset ||
          oldDelegate.selectedNodeId != selectedNodeId;
    }
    return true;
  }
}

/// 数学計算用のヘルパークラス
class Math {
  static double cos(double angle) {
    return math.cos(angle);
  }
  
  static double sin(double angle) {
    return math.sin(angle);
  }
}