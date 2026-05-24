import 'package:flutter/material.dart';

/// 信号徽章
class SignalBadge extends StatelessWidget {
  final dynamic signal; // TradeSignal

  const SignalBadge({super.key, required this.signal});

  Color get _color {
    final action = signal.action as String;
    switch (action) {
      case '买入':
        return Colors.green;
      case '卖出':
        return Colors.red;
      case '持有':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _iconForAction(signal.action as String),
            size: 16,
            color: _color,
          ),
          const SizedBox(width: 4),
          Text(
            signal.action as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForAction(String action) {
    switch (action) {
      case '买入':
        return Icons.trending_up;
      case '卖出':
        return Icons.trending_down;
      case '持有':
        return Icons.pause_circle_outline;
      default:
        return Icons.remove_red_eye_outlined;
    }
  }
}
