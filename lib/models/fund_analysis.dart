import 'fund_basic.dart';
import 'nav_data.dart';
import 'kline_data.dart';
import 'technical_data.dart';

/// 交易信号
class TradeSignal {
  final String action; // 买入 / 持有 / 卖出 / 观望
  final String reason;
  final String color; // hex color

  TradeSignal({required this.action, required this.reason, this.color = '#FF9800'});

  factory TradeSignal.buy(String reason) => TradeSignal(action: '买入', reason: reason, color: '#4CAF50');
  factory TradeSignal.hold(String reason) => TradeSignal(action: '持有', reason: reason, color: '#FF9800');
  factory TradeSignal.sell(String reason) => TradeSignal(action: '卖出', reason: reason, color: '#F44336');
  factory TradeSignal.watch(String reason) => TradeSignal(action: '观望', reason: reason, color: '#9E9E9E');
}

/// 估值评级
class ValuationGrade {
  final int percentile; // 0-100
  final String grade; // 极度低估/低估/中性/高估/极度高估
  final String? source; // PE / PB

  ValuationGrade({required this.percentile, required this.grade, this.source});

  static String gradeFromPercentile(int p) {
    if (p <= 15) return '极度低估';
    if (p <= 30) return '低估';
    if (p <= 50) return '中性';
    if (p <= 70) return '高估';
    return '极度高估';
  }
}

/// 风险指标
class RiskMetrics {
  final double? annualVolatility; // 年化波动率
  final double? maxDrawdown; // 历史最大回撤
  final double? m1Drawdown; // 近1月回撤
  final double? m3Drawdown; // 近3月回撤
  final double? sharpeRatio; // 夏普比率
  final double? winRate; // 胜率
  final double? plRatio; // 盈亏比
  final double? currentDrawdown; // 当前回撤率

  RiskMetrics({
    this.annualVolatility,
    this.maxDrawdown,
    this.m1Drawdown,
    this.m3Drawdown,
    this.sharpeRatio,
    this.winRate,
    this.plRatio,
    this.currentDrawdown,
  });
}

/// 均线分析
class MaAnalysis {
  final double? ma10;
  final double? ma60;
  final String position; // above / below
  final double? deviationPercent; // 乖离率
  final bool isGoldenCross; // MA10 > MA60 (金叉)
  final bool isDeathCross; // MA10 < MA60 (死叉)

  MaAnalysis({
    this.ma10,
    this.ma60,
    this.position = 'unknown',
    this.deviationPercent,
    this.isGoldenCross = false,
    this.isDeathCross = false,
  });
}

/// 基金完整分析结果
class FundAnalysis {
  final FundBasic basic;
  final List<NavData>? navHistory;
  final List<KlineData>? klineData;

  // 实时数据
  final double? latestNav;
  final double? latestAccNav;
  final double? dailyChange; // 日涨跌幅 %
  final double? estimatedNav; // 估算净值
  final double? estimatedChange; // 估算涨幅
  final String? dataDate;
  final bool isFromNetwork; // 是否从网络获取到真实数据

  // 回报
  final double? ret1m;
  final double? ret3m;
  final double? ret6m;
  final double? ret1y;
  final double? ret2y;
  final double? ret3y;
  final double? retYtd;
  final double? annualReturn; // 年化收益

  // 风险
  final RiskMetrics? risk;

  // 均线
  final MaAnalysis? ma;

  // 估值（仅ETF）
  final ValuationGrade? peGrade;
  final ValuationGrade? pbGrade;

  // 信号
  final TradeSignal? signal;

  // 规模&仓位
  final double? fundSize; // 规模(亿)
  final double? stockPosition; // 股票仓位 %

  // 费率
  final double? managementFee;
  final double? custodyFee;
  
  // 技术指标
  final double? cci; // CCI指标（周期20）
  final double? rsi; // RSI(14)
  final MacdData? macd;
  final BollingerData? bollinger;
  final KdjData? kdj;
  
  // 持仓穿透
  final List<Holding>? holdings;
  
  // 排名
  final CategoryRank? categoryRank;
  
  // 年度回报
  final List<YearlyReturn>? yearlyReturns;
  
  // 统计
  final int? maxConsecutiveUp;  // 最大连涨天数
  final int? maxConsecutiveDown; // 最大连跌天数
  final int? recoveryDays; // 回撤恢复天数

  FundAnalysis({
    required this.basic,
    this.navHistory,
    this.klineData,
    this.latestNav,
    this.latestAccNav,
    this.dailyChange,
    this.estimatedNav,
    this.estimatedChange,
    this.dataDate,
    this.ret1m,
    this.ret3m,
    this.ret6m,
    this.ret1y,
    this.ret2y,
    this.ret3y,
    this.retYtd,
    this.annualReturn,
    this.risk,
    this.ma,
    this.peGrade,
    this.pbGrade,
    this.signal,
    this.fundSize,
    this.stockPosition,
    this.managementFee,
    this.custodyFee,
    this.cci,
    this.rsi,
    this.macd,
    this.bollinger,
    this.kdj,
    this.holdings,
    this.categoryRank,
    this.yearlyReturns,
    this.maxConsecutiveUp,
    this.maxConsecutiveDown,
    this.recoveryDays,
    this.isFromNetwork = false,
  });

  String get ratingDisplay {
    if (peGrade != null && pbGrade != null) {
      return 'PE${peGrade!.grade} | PB${pbGrade!.grade}';
    }
    if (peGrade != null) return 'PE${peGrade!.grade}';
    if (pbGrade != null) return 'PB${pbGrade!.grade}';
    return 'N/A(主动基金)';
  }
}
