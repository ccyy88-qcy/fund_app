/// 净值数据点
class NavData {
  final String date;
  final double nav; // 单位净值
  final double accNav; // 累计净值

  NavData({required this.date, required this.nav, required this.accNav});

  factory NavData.fromJson(Map<String, dynamic> json) {
    return NavData(
      date: json['day'] ?? json['date'] ?? '',
      nav: (json['nav'] ?? json['y'] ?? 0).toDouble(),
      accNav: (json['accNav'] ?? json['acc_nav'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {'day': date, 'nav': nav, 'accNav': accNav};
}
