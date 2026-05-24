// ─── 新增数据结构 ───

/// MACD 数据
class MacdData {
  final double? macd;   // MACD线 = EMA12 - EMA26
  final double? signal; // 信号线 = EMA9 of MACD
  final double? histogram; // 柱状图 = MACD - Signal
  
  MacdData({this.macd, this.signal, this.histogram});
}

/// 布林带
class BollingerData {
  final double? upper;  // 上轨 = MA20 + 2σ
  final double? middle; // 中轨 = MA20
  final double? lower;  // 下轨 = MA20 - 2σ
  final double? bandwidth; // 带宽% = (上轨-下轨)/中轨

  BollingerData({this.upper, this.middle, this.lower, this.bandwidth});
}

/// KDJ 数据
class KdjData {
  final double? k;
  final double? d;
  final double? j;
  KdjData({this.k, this.d, this.j});
}

/// 持仓明细
class Holding {
  final String code;
  final String name;
  final double? ratio; // 占净值比%

  Holding({required this.code, this.name = '', this.ratio});
}

/// 年度回报
class YearlyReturn {
  final int year;
  final double? return_; // 年回报%
  YearlyReturn({required this.year, this.return_});
}

/// 同类排名
class CategoryRank {
  final String category; // 分类名称
  final int rank;        // 排名
  final int total;       // 总数
  String get display => '$rank/$total';
  double get percentile => total > 0 ? rank / total * 100 : 100;

  CategoryRank({required this.category, required this.rank, required this.total});
}
