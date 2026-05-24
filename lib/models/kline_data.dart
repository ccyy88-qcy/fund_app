/// K线数据点（ETF专用）
class KlineData {
  final String day;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  KlineData({
    required this.day,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  factory KlineData.fromSinaJson(Map<String, dynamic> json) {
    return KlineData(
      day: json['day'] ?? '',
      open: (json['open'] ?? 0).toDouble(),
      high: (json['high'] ?? 0).toDouble(),
      low: (json['low'] ?? 0).toDouble(),
      close: (json['close'] ?? 0).toDouble(),
      volume: (json['volume'] ?? 0).toDouble(),
    );
  }

  /// 从基金净值数据转换（只有收盘价）
  factory KlineData.fromNav(Map<String, dynamic> json) {
    double nav = (json['nav'] ?? json['y'] ?? 0).toDouble();
    return KlineData(
      day: json['day'] ?? '',
      open: nav,
      high: nav,
      low: nav,
      close: nav,
      volume: 0,
    );
  }
}
