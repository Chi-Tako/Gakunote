// lib/features/notes/presentation/widgets/prediction_suggestion_card.dart
import 'package:flutter/material.dart';
import '../../services/context_prediction_engine.dart';

/// 予測提案カードウィジェット
class PredictionSuggestionCard extends StatelessWidget {
  final Prediction prediction;
  final VoidCallback onTap;

  const PredictionSuggestionCard({
    Key? key,
    required this.prediction,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 予測タイプと信頼度のバッジ
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTypeBadge(),
                  _buildConfidenceBadge(),
                ],
              ),
              const SizedBox(height: 8),
              // 予測アイコンとタイトル
              Row(
                children: [
                  Icon(
                    prediction.icon,
                    size: 16,
                    color: _getIconColor(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prediction.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // 説明文
              Expanded(
                child: Text(
                  prediction.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // 「適用」ボタン
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '適用',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 予測タイプに応じたバッジ
  Widget _buildTypeBadge() {
    String label;
    Color backgroundColor;

    switch (prediction.type) {
      case PredictionType.blockType:
        label = 'ブロック';
        backgroundColor = Colors.blue.shade100;
        break;
      case PredictionType.content:
        label = 'コンテンツ';
        backgroundColor = Colors.green.shade100;
        break;
      case PredictionType.action:
        label = 'アクション';
        backgroundColor = Colors.orange.shade100;
        break;
      case PredictionType.resource:
        label = 'リソース';
        backgroundColor = Colors.purple.shade100;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: backgroundColor.withBlue(200).withRed(100).withGreen(100),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 信頼度バッジ
  Widget _buildConfidenceBadge() {
    // 信頼度に応じた色
    final color = prediction.getConfidenceColor();
    
    // 信頼度をパーセント表示
    final percentage = (prediction.confidence * 100).round();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$percentage%',
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 予測タイプに応じたアイコン色
  Color _getIconColor() {
    switch (prediction.type) {
      case PredictionType.blockType:
        return Colors.blue;
      case PredictionType.content:
        return Colors.green;
      case PredictionType.action:
        return Colors.orange;
      case PredictionType.resource:
        return Colors.purple;
    }
  }

  // 予測タイプに応じたボーダー色
  Color _getBorderColor() {
    switch (prediction.type) {
      case PredictionType.blockType:
        return Colors.blue.withOpacity(0.3);
      case PredictionType.content:
        return Colors.green.withOpacity(0.3);
      case PredictionType.action:
        return Colors.orange.withOpacity(0.3);
      case PredictionType.resource:
        return Colors.purple.withOpacity(0.3);
    }
  }
}