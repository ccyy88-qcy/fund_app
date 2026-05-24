import 'package:flutter/material.dart';

/// 指标卡片（涨跌染色）
class MetricCard extends StatelessWidget {
  final String label;
  final dynamic value; // double? or null
  final String suffix;
  final String prefix;
  final bool large;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = value is double && value >= 0;
    final isNegative = value is double && value < 0;
    
    Color? valueColor;
    if (isPositive) valueColor = Colors.red[700];
    if (isNegative) valueColor = Colors.green[700];
    
    final displayVal = value != null 
        ? '$prefix${value.toStringAsFixed(2)}$suffix'
        : '—';
    
    return Container(
      width: large ? 160 : 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isPositive 
            ? Colors.red.withOpacity(0.05) 
            : isNegative 
                ? Colors.green.withOpacity(0.05) 
                : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            displayVal,
            style: TextStyle(
              fontSize: large ? 16 : 13,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
