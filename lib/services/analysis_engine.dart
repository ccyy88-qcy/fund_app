import 'dart:math';
import '../models/fund_analysis.dart';
import '../models/fund_basic.dart';
import '../models/nav_data.dart';
import '../models/kline_data.dart';

/// 基金分析引擎 - 移植自Python fund_report_v4.py + build_report_v4.py
class AnalysisEngine {
  /// 计算MA10
  static double? computeMa10(List<double> closes) {
    if (closes.length < 10) return null;
    return closes.sublist(closes.length - 10).reduce((a, b) => a + b) / 10;
  }

  /// 计算MA60
  static double? computeMa60(List<double> closes) {
    if (closes.length < 60) return null;
    return closes.sublist(closes.length - 60).reduce((a, b) => a + b) / 60;
  }

  /// 均线分析
  static MaAnalysis analyzeMa(List<double> closes, double latestNav) {
    final ma10 = computeMa10(closes);
    final ma60 = computeMa60(closes);
    
    String position = 'unknown';
    double? deviationPercent;
    
    if (ma10 != null) {
      position = latestNav >= ma10 ? 'above' : 'below';
      deviationPercent = ((latestNav / ma10) - 1) * 100;
    }
    
    final isGoldenCross = ma10 != null && ma60 != null && ma10 > ma60;
    final isDeathCross = ma10 != null && ma60 != null && ma10 < ma60;
    
    return MaAnalysis(
      ma10: ma10,
      ma60: ma60,
      position: position,
      deviationPercent: deviationPercent,
      isGoldenCross: isGoldenCross,
      isDeathCross: isDeathCross,
    );
  }

  /// 计算回报率
  /// closes: 正序（从旧到新）
  static double? calcReturn(List<double> closes, int days) {
    if (closes.length < days + 1) return null;
    final cur = closes.last;
    final prev = closes[closes.length - 1 - days];
    return (cur / prev - 1) * 100;
  }

  /// 计算年初至今回报
  static double? calcYtdReturn(List<NavData> navData) {
    if (navData.isEmpty) return null;
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    
    // 找到年初的第一个数据点
    int startIdx = -1;
    for (int i = 0; i < navData.length; i++) {
      final date = DateTime.tryParse(navData[i].date);
      if (date != null && !date.isBefore(yearStart)) {
        startIdx = i;
        break;
      }
    }
    if (startIdx <= 0 || startIdx >= navData.length) return null;
    
    final startNav = navData[startIdx - 1].nav; // 取年初最近的前一个交易日
    final curNav = navData.last.nav;
    return (curNav / startNav - 1) * 100;
  }

  /// 计算年化波动率
  static double? calcAnnualVolatility(List<double> closes) {
    if (closes.length < 252) return null;
    final returns = <double>[];
    for (int i = 1; i < closes.length; i++) {
      returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
    }
    if (returns.isEmpty) return null;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    return sqrt(variance) * sqrt(252) * 100;
  }

  /// 计算最大回撤
  static double? calcMaxDrawdown(List<double> closes) {
    if (closes.isEmpty) return null;
    double peak = closes[0];
    double maxDd = 0;
    for (final c in closes) {
      peak = max(peak, c);
      final dd = (peak - c) / peak * 100;
      maxDd = max(maxDd, dd);
    }
    return maxDd;
  }

  /// 计算当前回撤
  static double? calcCurrentDrawdown(List<double> closes) {
    if (closes.length < 10) return null;
    final ath = closes.reduce(max);
    final current = closes.last;
    return (current - ath) / ath * 100;
  }

  /// 计算窗口内最大回撤
  static double? calcWindowDrawdown(List<double> closes, int window) {
    if (closes.length < window) return null;
    final subset = closes.sublist(closes.length - window);
    double peak = subset[0];
    double maxDd = 0;
    for (final c in subset) {
      peak = max(peak, c);
      final dd = (peak - c) / peak * 100;
      maxDd = max(maxDd, dd);
    }
    return maxDd;
  }

  /// 计算夏普比率
  static double? calcSharpe(List<double> closes, {double riskFreeRate = 2.5}) {
    if (closes.length < 252) return null;
    final returns = <double>[];
    for (int i = 1; i < closes.length; i++) {
      returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
    }
    if (returns.isEmpty) return null;
    
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    final std = sqrt(variance);
    
    if (std == 0) return 0;
    final annualReturn = (closes.last / closes.first - 1) / (closes.length / 250);
    return (annualReturn - riskFreeRate / 100) / (std * sqrt(250));
  }

  /// 计算胜率
  static double? calcWinRate(List<double> closes) {
    if (closes.length < 20) return null;
    int wins = 0;
    for (int i = 1; i < closes.length; i++) {
      if (closes[i] > closes[i - 1]) wins++;
    }
    return wins / (closes.length - 1) * 100;
  }

  /// 计算盈亏比
  static double? calcPlRatio(List<double> closes) {
    if (closes.length < 20) return null;
    double totalWin = 0, totalLoss = 0;
    int winCnt = 0, lossCnt = 0;
    for (int i = 1; i < closes.length; i++) {
      final ret = (closes[i] - closes[i - 1]) / closes[i - 1];
      if (ret > 0) {
        totalWin += ret;
        winCnt++;
      } else if (ret < 0) {
        totalLoss += ret.abs();
        lossCnt++;
      }
    }
    if (lossCnt == 0) return winCnt > 0 ? double.infinity : 0;
    final avgWin = winCnt > 0 ? totalWin / winCnt * 100 : 0;
    final avgLoss = lossCnt > 0 ? totalLoss / lossCnt * 100 : 1;
    return avgLoss > 0 ? avgWin / avgLoss : 0;
  }

  /// 计算年化收益
  static double? calcAnnualReturn(List<double> closes) {
    if (closes.length < 20) return null;
    final totalRet = closes.last / closes.first - 1;
    final years = closes.length / 250;
    if (years <= 0) return null;
    return (pow(1 + totalRet, 1 / years) - 1) * 100;
  }

  /// 量比计算
  static double? calcVolumeRatio(List<KlineData> kline) {
    if (kline.length < 21) return null;
    final vols = kline.map((k) => k.volume).toList();
    if (vols.reduce(max) == 0) return 0; // fund has no volume
    final v5 = vols.sublist(vols.length - 5).reduce((a, b) => a + b) / 5;
    final v20 = vols.sublist(vols.length - 20).reduce((a, b) => a + b) / 20;
    return v20 > 0 ? v5 / v20 : 0;
  }

  /// 近期最高回落
  static double? calcRecentHighDrop(List<double> closes) {
    if (closes.length < 20) return null;
    final subset = closes.sublist(max(0, closes.length - 60));
    final high = subset.reduce(max);
    return (high - subset.last) / high * 100;
  }

  /// 估值评级
  static ValuationGrade gradeValuation(int? percentile, {String source = 'PE'}) {
    if (percentile == null) {
      return ValuationGrade(percentile: 50, grade: 'N/A', source: source);
    }
    return ValuationGrade(
      percentile: percentile,
      grade: ValuationGrade.gradeFromPercentile(percentile),
      source: source,
    );
  }

  /// 生成交易信号（移植自Python calc_signal）
  static TradeSignal generateSignal({
    required bool isActiveFund,
    required int? pePercentile,
    required int? pbPercentile,
    required String maPosition, // 'above' / 'below'
    required double? ma10,
    required double? ma60,
    required double? volumeRatio,
    required double? recentDrop, // 近60日最高回落
  }) {
    final isPeExempt = pePercentile != null && pePercentile <= 30;
    final isPbExempt = pbPercentile != null && pbPercentile <= 30;
    final isExempt = isPeExempt || isPbExempt;
    
    if (isActiveFund) {
      // 主动基金规则
      if (isExempt) {
        return TradeSignal.hold('估值低位·禁止卖出');
      }
      if (maPosition == 'above' && ma10 != null && ma60 != null && ma10 > ma60) {
        return TradeSignal.hold('趋势良好·持有');
      } else {
        return TradeSignal.watch('趋势偏弱·观望');
      }
    }
    
    // ETF规则
    int buyCnt = 0;
    
    // 买入条件1：估值≤30%
    if (isExempt) buyCnt++;
    
    // 买入条件2：站稳MA10且MA10>MA60
    if (maPosition == 'above' && ma10 != null && ma60 != null && ma10 > ma60) buyCnt++;
    
    // 买入条件3：量比>1.0
    if (volumeRatio != null && volumeRatio > 1.0) buyCnt++;
    if (volumeRatio == 0) buyCnt++; // fund无成交量放宽
    
    // 卖出判定
    // 条件1：估值≥70%止盈
    final isPeOvervalued = pePercentile != null && pePercentile >= 70;
    final isPbOvervalued = pbPercentile != null && pbPercentile >= 70;
    
    if (!isExempt && (isPeOvervalued || isPbOvervalued)) {
      return TradeSignal.sell('止盈卖出·高估');
    }
    
    // 条件2：估值≥50% + 死叉
    final isPeMid = pePercentile != null && pePercentile >= 50;
    final isPbMid = pbPercentile != null && pbPercentile >= 50;
    if (!isExempt && (isPeMid || isPbMid)) {
      if (maPosition == 'below' && ma10 != null && ma60 != null && ma10 < ma60) {
        return TradeSignal.sell('趋势减仓·回撤信号');
      }
    }
    
    // 条件3：回落10%+估值≥50%
    if (!isExempt && recentDrop != null && recentDrop >= 10 && (isPeMid || isPbMid)) {
      return TradeSignal.sell('高位回落止盈');
    }
    
    // 综合买入判定
    if (buyCnt >= 3) return TradeSignal.buy(isExempt ? '低估买入' : '趋势买入');
    if (isExempt && buyCnt >= 1) return TradeSignal.hold('估值低位·禁止卖出');
    if (buyCnt >= 2) return TradeSignal.hold('部分达标·持有观望');
    
    return TradeSignal.watch('条件不足·继续观望');
  }

  /// 完全分析管道：传入净值数据 → 输出 FundAnalysis
  static FundAnalysis analyze(
    FundBasic basic,
    List<NavData> navData, // 正序
    List<KlineData>? klineData,
    Map<String, dynamic>? estimationData, // 实时估值
    double? dailyChange,
    int? pePercentile,
    int? pbPercentile,
  ) {
    final closes = navData.map((n) => n.nav).toList();
    final isSame = klineData != null && klineData.length == navData.length;
    final klineCloses = isSame 
        ? klineData!.map((k) => k.close).toList()
        : closes;
    
    final latestNav = closes.isNotEmpty ? closes.last : null;
    final latestAccNav = navData.isNotEmpty ? navData.last.accNav : null;
    
    // 回报
    final ret1m = calcReturn(closes, 22);
    final ret3m = calcReturn(closes, 66);
    final ret6m = calcReturn(closes, 132);
    final ret1y = calcReturn(closes, 252);
    final ret2y = calcReturn(closes, 504);
    final ret3y = calcReturn(closes, 756);
    final retYtd = calcYtdReturn(navData);
    final annualReturn = calcAnnualReturn(closes);
    
    // 风险
    final risk = RiskMetrics(
      annualVolatility: calcAnnualVolatility(closes),
      maxDrawdown: calcMaxDrawdown(closes),
      m1Drawdown: calcWindowDrawdown(closes, 22),
      m3Drawdown: calcWindowDrawdown(closes, 66),
      sharpeRatio: calcSharpe(closes),
      winRate: calcWinRate(closes),
      plRatio: calcPlRatio(closes),
      currentDrawdown: calcCurrentDrawdown(closes),
    );
    
    // 均线
    final ma = latestNav != null ? analyzeMa(closes, latestNav) : null;
    
    // 估值
    final peGrade = pePercentile != null ? gradeValuation(pePercentile, source: 'PE') : null;
    final pbGrade = pbPercentile != null ? gradeValuation(pbPercentile, source: 'PB') : null;
    
    // 量比
    final volRatio = klineData != null ? calcVolumeRatio(klineData) : 0.0;
    
    // 回落
    final drop = calcRecentHighDrop(klineCloses);
    
    // 信号
    final signal = generateSignal(
      isActiveFund: basic.isActiveFund,
      pePercentile: pePercentile,
      pbPercentile: pbPercentile,
      maPosition: ma?.position ?? 'unknown',
      ma10: ma?.ma10,
      ma60: ma?.ma60,
      volumeRatio: volRatio,
      recentDrop: drop,
    );
    
    // 估算数据
    double? estNav, estChange;
    if (estimationData != null) {
      estNav = double.tryParse(estimationData['gsz']?.toString() ?? '');
      estChange = double.tryParse(estimationData['gszzl']?.toString() ?? '');
    }
    
    return FundAnalysis(
      basic: basic,
      navHistory: navData,
      klineData: klineData,
      latestNav: latestNav,
      latestAccNav: latestAccNav,
      dailyChange: dailyChange,
      estimatedNav: estNav,
      estimatedChange: estChange,
      dataDate: navData.isNotEmpty ? navData.last.date : null,
      ret1m: ret1m,
      ret3m: ret3m,
      ret6m: ret6m,
      ret1y: ret1y,
      ret2y: ret2y,
      ret3y: ret3y,
      retYtd: retYtd,
      annualReturn: annualReturn,
      risk: risk,
      ma: ma,
      peGrade: peGrade,
      pbGrade: pbGrade,
      signal: signal,
    );
  }
}
