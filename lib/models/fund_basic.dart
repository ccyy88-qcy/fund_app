/// 基金基本信息
class FundBasic {
  final String code;
  final String name;
  final String type; // ETF-行业指数 / 混合型-灵活 / ETF-QDII / etc
  final String? manager; // 基金经理
  final String? inceptionDate; // 成立日期
  final String? bench; // 业绩基准

  FundBasic({
    required this.code,
    required this.name,
    this.type = '',
    this.manager,
    this.inceptionDate,
    this.bench,
  });

  factory FundBasic.fromJson(Map<String, dynamic> json) {
    return FundBasic(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      manager: json['manager'],
      inceptionDate: json['inceptionDate'],
      bench: json['bench'],
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'type': type,
    'manager': manager,
    'inceptionDate': inceptionDate,
    'bench': bench,
  };

  bool get isEtf => type.startsWith('ETF');
  bool get isActiveFund => type.contains('混合') || type.contains('偏股');
  bool get isQdii => type.contains('QDII');
}
