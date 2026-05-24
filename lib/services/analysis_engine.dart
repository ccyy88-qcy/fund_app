import 'dart:math';
import '../models/fund_analysis.dart';
import '../models/fund_basic.dart';
import '../models/nav_data.dart';
import '../models/kline_data.dart';
import '../models/technical_data.dart';

/// 基金分析引擎 - 移植自Python fund_report_v4.py + build_report_v4.py
class AnalysisEngine {
  // ─── 均线 ───
  static double? computeMa10(List<double> closes) {
    if (closes.length < 10) return null;
    return closes.sublist(closes.length - 10).reduce((a, b) => a + b) / 10;
  }

  static double? computeMa60(List<double> closes) {
    if (closes.length < 60) return null;
    return closes.sublist(closes.length - 60).reduce((a, b) => a + b) / 60;
  }

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
      ma10: ma10, ma60: ma60, position: position,
      deviationPercent: deviationPercent, isGoldenCross: isGoldenCross, isDeathCross: isDeathCross,
    );
  }

  // ─── 回报 ───
  static double? calcReturn(List<double> closes, int days) {
    if (closes.length < days + 1) return null;
    return (closes.last / closes[closes.length - 1 - days] - 1) * 100;
  }

  static double? calcYtdReturn(List<NavData> navData) {
    if (navData.isEmpty) return null;
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    int startIdx = -1;
    for (int i = 0; i < navData.length; i++) {
      final date = DateTime.tryParse(navData[i].date);
      if (date != null && !date.isBefore(yearStart)) { startIdx = i; break; }
    }
    if (startIdx <= 0 || startIdx >= navData.length) return null;
    return (navData.last.nav / navData[startIdx - 1].nav - 1) * 100;
  }

  static double? calcAnnualReturn(List<double> closes) {
    if (closes.length < 20) return null;
    final totalRet = closes.last / closes.first - 1;
    final years = closes.length / 250;
    if (years <= 0) return null;
    return (pow(1 + totalRet, 1 / years) - 1) * 100;
  }

  // ─── 风险 ───
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

  static double? calcMaxDrawdown(List<double> closes) {
    if (closes.isEmpty) return null;
    double peak = closes[0], maxDd = 0;
    for (final c in closes) { peak = max(peak, c); maxDd = max(maxDd, (peak - c) / peak); }
    return -maxDd * 100;
  }

  static double? calcCurrentDrawdown(List<double> closes) {
    if (closes.length < 10) return null;
    return (closes.last - closes.reduce(max)) / closes.reduce(max) * 100;
  }

  static double? calcWindowDrawdown(List<double> closes, int window) {
    if (closes.length < window) return null;
    final subset = closes.sublist(closes.length - window);
    double peak = subset[0], maxDd = 0;
    for (final c in subset) { peak = max(peak, c); maxDd = max(maxDd, (peak - c) / peak); }
    return -maxDd * 100;
  }

  static double? calcSharpe(List<double> closes, {double riskFreeRate = 2.5}) {
    if (closes.length < 252) return null;
    final returns = <double>[];
    for (int i = 1; i < closes.length; i++) returns.add((closes[i] - closes[i - 1]) / closes[i - 1]);
    if (returns.isEmpty) return null;
    final mean = returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.map((r) => pow(r - mean, 2)).reduce((a, b) => a + b) / returns.length;
    final std = sqrt(variance);
    if (std == 0) return 0;
    final annualReturn = (closes.last / closes.first - 1) / (closes.length / 250);
    return (annualReturn - riskFreeRate / 100) / (std * sqrt(250));
  }

  static double? calcWinRate(List<double> closes) {
    if (closes.length < 20) return null;
    int wins = 0;
    for (int i = 1; i < closes.length; i++) if (closes[i] > closes[i - 1]) wins++;
    return wins / (closes.length - 1) * 100;
  }

  static double? calcPlRatio(List<double> closes) {
    if (closes.length < 20) return null;
    double totalWin = 0, totalLoss = 0;
    int winCnt = 0, lossCnt = 0;
    for (int i = 1; i < closes.length; i++) {
      final ret = (closes[i] - closes[i - 1]) / closes[i - 1];
      if (ret > 0) { totalWin += ret; winCnt++; }
      else if (ret < 0) { totalLoss += ret.abs(); lossCnt++; }
    }
    if (lossCnt == 0) return winCnt > 0 ? double.infinity : 0;
    final avgWin = winCnt > 0 ? totalWin / winCnt * 100 : 0;
    final avgLoss = lossCnt > 0 ? totalLoss / lossCnt * 100 : 1;
    return avgLoss > 0 ? avgWin / avgLoss : 0;
  }

  // ─── CCI 指标 ───
  /// CCI = (TP - SMA(TP)) / (0.015 × MD), 周期默认 20
  static double? calcCCI(List<double> closes, {int period = 20}) {
    if (closes.length < period) return null;
    final subset = closes.sublist(closes.length - period);
    final sma = subset.reduce((a, b) => a + b) / period;
    final md = subset.map((c) => (c - sma).abs()).reduce((a, b) => a + b) / period;
    if (md == 0) return 0;
    return (subset.last - sma) / (0.015 * md);
  }

  /// 带 K 线数据的 CCI（使用真实 High/Low/Close）
  static double? calcCCIWithKline(List<KlineData> kline, {int period = 20}) {
    if (kline.length < period) return null;
    final subset = kline.sublist(kline.length - period);
    final tps = subset.map((k) => (k.high + k.low + k.close) / 3).toList();
    final sma = tps.reduce((a, b) => a + b) / period;
    final md = tps.map((t) => (t - sma).abs()).reduce((a, b) => a + b) / period;
    if (md == 0) return 0;
    return (tps.last - sma) / (0.015 * md);
  }

  // ─── RSI(14) ───
  static double? calcRSI(List<double> closes, {int period = 14}) {
    if (closes.length < period + 1) return null;
    double gain = 0, loss = 0;
    for (int i = closes.length - period; i < closes.length; i++) {
      final diff = closes[i] - closes[i - 1];
      if (diff > 0) gain += diff; else loss -= diff;
    }
    if (loss == 0) return 100;
    final rs = gain / loss;
    return 100 - (100 / (1 + rs));
  }

  // ─── MACD(12,26,9) ───
  static double _ema(List<double> data, int period) {
    if (data.length < period) return data.last;
    final multiplier = 2.0 / (period + 1);
    double ema = data.sublist(0, period).reduce((a,b)=>a+b)/period;
    for (int i = period; i < data.length; i++) { ema = (data[i] - ema) * multiplier + ema; }
    return ema;
  }

  static MacdData? calcMACD(List<double> closes) {
    if (closes.length < 35) return null;
    final ema12 = _ema(closes, 12);
    final ema26 = _ema(closes, 26);
    final macdVal = ema12 - ema26;
    // Signal: EMA9 of MACD values - simplified
    final macdVals = <double>[];
    for (int i = 26; i < closes.length; i++) {
      final e12 = _ema(closes.sublist(0, i+1), 12);
      final e26 = _ema(closes.sublist(0, i+1), 26);
      macdVals.add(e12 - e26);
    }
    final signal = macdVals.length >= 9 ? _ema(macdVals, 9) : macdVal;
    return MacdData(macd: macdVal, signal: signal, histogram: macdVal - signal);
  }

  // ─── 布林带(20,2) ───
  static BollingerData? calcBollinger(List<double> closes) {
    if (closes.length < 20) return null;
    final subset = closes.sublist(closes.length - 20);
    final ma = subset.reduce((a,b)=>a+b)/20;
    final variance = subset.map((c)=> (c-ma)*(c-ma)).reduce((a,b)=>a+b)/20;
    final std = sqrt(variance);
    final upper = ma + 2*std;
    final lower = ma - 2*std;
    final bw = ma > 0 ? (upper-lower)/ma*100 : 0.0;
    return BollingerData(upper: upper, middle: ma, lower: lower, bandwidth: bw);
  }

  // ─── KDJ(9,3,3) ───
  static KdjData? calcKDJ(List<double> closes, {int n=9, int k1=3, int d1=3}) {
    if (closes.length < n) return null;
    final subset = closes.sublist(closes.length - n);
    final hh = subset.reduce(max);
    final ll = subset.reduce(min);
    final close = subset.last;
    final range = hh - ll;
    if (range == 0) return KdjData(k: 50, d: 50, j: 50);
    final rsv = (close - ll) / range * 100;
    final k = (2.0/3)*50 + (1.0/3)*rsv;
    final d = (2.0/3)*50 + (1.0/3)*k;
    final j = 3*k - 2*d;
    return KdjData(k: k, d: d, j: j);
  }

  // ─── 最大连涨/跌天数 ───
  static int calcMaxConsecutiveUp(List<double> closes) {
    int maxCnt = 0, cnt = 0;
    for (int i = 1; i < closes.length; i++) {
      if (closes[i] > closes[i-1]) { cnt++; maxCnt = max(maxCnt, cnt); }
      else cnt = 0;
    }
    return maxCnt;
  }

  static int calcMaxConsecutiveDown(List<double> closes) {
    int maxCnt = 0, cnt = 0;
    for (int i = 1; i < closes.length; i++) {
      if (closes[i] < closes[i-1]) { cnt++; maxCnt = max(maxCnt, cnt); }
      else cnt = 0;
    }
    return maxCnt;
  }

  // ─── 年度回报 ───
  static List<YearlyReturn> calcYearlyReturns(List<NavData> navData) {
    final Map<int, List<double>> yearNavs = {};
    for (final n in navData) {
      final y = int.tryParse(n.date.substring(0,4));
      if (y != null) { yearNavs.putIfAbsent(y, () => []).add(n.nav); }
    }
    final results = <YearlyReturn>[];
    for (final y in yearNavs.keys.toList()..sort()) {
      final vals = yearNavs[y]!;
      if (vals.length >= 2) {
        final ret = (vals.last / vals.first - 1) * 100;
        results.add(YearlyReturn(year: y, return_: ret));
      }
    }
    return results;
  }

  // ─── 回撤恢复天数 ───
  static int? calcRecoveryDays(List<double> closes) {
    if (closes.length < 30) return null;
    double peak = closes[0];
    int peakIdx = 0, maxRecDays = 0;
    for (int i = 1; i < closes.length; i++) {
      if (closes[i] > peak) {
        peak = closes[i];
        peakIdx = i;
      } else if (closes[i] >= peak) {
        maxRecDays = max(maxRecDays, i - peakIdx);
      }
    }
    return maxRecDays > 0 ? maxRecDays : null;
  }

  // ─── 图表序列 ───
  /// RSI 历史序列（最近 N 个交易日）
  static List<RsiPoint> calcRSISeries(List<double> closes, {int period = 14, int maxPoints = 60}) {
    if (closes.length < period + 1) return [];
    final start = max(0, closes.length - maxPoints - period);
    final pts = <RsiPoint>[];
    for (int i = start + period; i < closes.length; i++) {
      final rsi = calcRSI(closes.sublist(0, i + 1), period: period);
      if (rsi != null) pts.add(RsiPoint(index: i - start, value: rsi));
    }
    return pts;
  }

  /// MACD 历史序列
  static List<MacdPoint> calcMACDSeries(List<double> closes, {int maxPoints = 60}) {
    if (closes.length < 35) return [];
    final start = max(0, closes.length - maxPoints - 26);
    final pts = <MacdPoint>[];
    for (int i = start + 26; i < closes.length; i++) {
      final sub = closes.sublist(0, i + 1);
      final md = calcMACD(sub);
      if (md != null) pts.add(MacdPoint(index: i - start, macd: md.macd, signal: md.signal, histogram: md.histogram));
    }
    return pts;
  }

  /// 布林带历史序列
  static List<BollingerPoint> calcBollingerSeries(List<double> closes, {int period = 20, int maxPoints = 60}) {
    if (closes.length < period) return [];
    final start = max(0, closes.length - maxPoints);
    final pts = <BollingerPoint>[];
    for (int i = max(start + period, period); i < closes.length; i++) {
      final sub = closes.sublist(i - period + 1, i + 1);
      final ma = sub.reduce((a,b)=>a+b)/period;
      final variance = sub.map((c)=> (c-ma)*(c-ma)).reduce((a,b)=>a+b)/period;
      final std = sqrt(variance);
      pts.add(BollingerPoint(index: i - start, upper: ma + 2*std, middle: ma, lower: ma - 2*std));
    }
    return pts;
  }

  /// KDJ 历史序列
  static List<KdjPoint> calcKDJSeries(List<double> closes, {int n = 9, int maxPoints = 60}) {
    if (closes.length < n) return [];
    final start = max(0, closes.length - maxPoints);
    final pts = <KdjPoint>[];
    for (int i = max(start + n, n); i < closes.length; i++) {
      final sub = closes.sublist(i - n + 1, i + 1);
      final hh = sub.reduce(max);
      final ll = sub.reduce(min);
      final range = hh - ll;
      if (range > 0) {
        final rsv = (sub.last - ll) / range * 100;
        final k = (2.0/3)*50 + (1.0/3)*rsv;
        final d = (2.0/3)*50 + (1.0/3)*k;
        final j = 3*k - 2*d;
        pts.add(KdjPoint(index: i - start, k: k, d: d, j: j));
      }
    }
    return pts;
  }

  /// 生成完整图表数据
  static ChartData buildChartData(List<double> closes) {
    return ChartData(
      rsiSeries: calcRSISeries(closes),
      macdSeries: calcMACDSeries(closes),
      bollingerSeries: calcBollingerSeries(closes),
      kdjSeries: calcKDJSeries(closes),
    );
  }

  // ─── 量比 / 回落 ───
  static double? calcVolumeRatio(List<KlineData> kline) {
    if (kline.length < 21) return null;
    final vols = kline.map((k) => k.volume).toList();
    if (vols.reduce(max) == 0) return 0;
    final v5 = vols.sublist(vols.length - 5).reduce((a, b) => a + b) / 5;
    final v20 = vols.sublist(vols.length - 20).reduce((a, b) => a + b) / 20;
    return v20 > 0 ? v5 / v20 : 0;
  }

  static double? calcRecentHighDrop(List<double> closes) {
    if (closes.length < 20) return null;
    final subset = closes.sublist(max(0, closes.length - 60));
    final high = subset.reduce(max);
    return (high - subset.last) / high * 100;
  }

  // ─── 估值 ───
  static ValuationGrade gradeValuation(int? percentile, {String source = 'PE'}) {
    if (percentile == null) return ValuationGrade(percentile: 50, grade: 'N/A', source: source);
    return ValuationGrade(percentile: percentile, grade: ValuationGrade.gradeFromPercentile(percentile), source: source);
  }

  // ─── 信号 ───
  static TradeSignal generateSignal({
    required bool isActiveFund, required int? pePercentile, required int? pbPercentile,
    required String maPosition, required double? ma10, required double? ma60,
    required double? volumeRatio, required double? recentDrop,
  }) {
    final isExempt = (pePercentile != null && pePercentile <= 30) || (pbPercentile != null && pbPercentile <= 30);
    if (isActiveFund) {
      if (isExempt) return TradeSignal.hold('估值低位·禁止卖出');
      if (maPosition == 'above' && ma10 != null && ma60 != null && ma10 > ma60) return TradeSignal.hold('趋势良好·持有');
      return TradeSignal.watch('趋势偏弱·观望');
    }
    int buyCnt = 0;
    if (isExempt) buyCnt++;
    if (maPosition == 'above' && ma10 != null && ma60 != null && ma10 > ma60) buyCnt++;
    if (volumeRatio != null && volumeRatio > 1.0) buyCnt++;
    if (volumeRatio == 0) buyCnt++;

    final isOver = (pePercentile != null && pePercentile >= 70) || (pbPercentile != null && pbPercentile >= 70);
    final isMid = (pePercentile != null && pePercentile >= 50) || (pbPercentile != null && pbPercentile >= 50);
    if (!isExempt && isOver) return TradeSignal.sell('止盈卖出·高估');
    if (!isExempt && isMid && maPosition == 'below' && ma10 != null && ma60 != null && ma10 < ma60) return TradeSignal.sell('趋势减仓·回撤信号');
    if (!isExempt && recentDrop != null && recentDrop >= 10 && isMid) return TradeSignal.sell('高位回落止盈');
    if (buyCnt >= 3) return TradeSignal.buy(isExempt ? '低估买入' : '趋势买入');
    if (isExempt && buyCnt >= 1) return TradeSignal.hold('估值低位·禁止卖出');
    if (buyCnt >= 2) return TradeSignal.hold('部分达标·持有观望');
    return TradeSignal.watch('条件不足·继续观望');
  }

  // ─── 全量分析 ───
  static FundAnalysis analyze(
    FundBasic basic,
    List<NavData> navData,
    List<KlineData>? klineData,
    Map<String, dynamic>? estimationData,
    double? dailyChange,
    int? pePercentile,
    int? pbPercentile,
    {double? apiRet1m,
     double? apiRet3m,
     double? apiRet6m,
     double? apiRet1y,
     List<Holding>? holdings,}
  ) {
    final closes = navData.map((n) => n.nav).toList();
    final isSame = klineData != null && klineData.length == navData.length;
    final klineCloses = isSame ? klineData!.map((k) => k.close).toList() : closes;
    final latestNav = closes.isNotEmpty ? closes.last : null;
    final latestAccNav = navData.isNotEmpty ? navData.last.accNav : null;

    // CCI（ETF有K线用真实TP，基金用Close）
    final cci = klineData != null && klineData.length >= 20
        ? calcCCIWithKline(klineData)
        : calcCCI(closes);

    // RSI
    final rsi = calcRSI(closes);

    // MACD
    final macd = calcMACD(closes);

    // 布林带
    final bollinger = calcBollinger(closes);

    // KDJ
    final kdj = calcKDJ(closes);

    // 统计
    final maxConsecutiveUp = calcMaxConsecutiveUp(closes);
    final maxConsecutiveDown = calcMaxConsecutiveDown(closes);
    final recoveryDays = calcRecoveryDays(closes);

    // 年度回报
    final yearlyReturns = calcYearlyReturns(navData);
    
    // 图表数据
    final chartData = buildChartData(closes);

    // 回报（优先用API数据，与东方财富/支付宝一致）
    final ret1m = apiRet1m ?? calcReturn(closes, 22);
    final ret3m = apiRet3m ?? calcReturn(closes, 66);
    final ret6m = apiRet6m ?? calcReturn(closes, 132);
    final ret1y = apiRet1y ?? calcReturn(closes, 252);
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

    // 量比 + 回落
    final volRatio = klineData != null ? calcVolumeRatio(klineData) : 0.0;
    final drop = calcRecentHighDrop(klineCloses);

    // 信号
    final signal = generateSignal(
      isActiveFund: basic.isActiveFund, pePercentile: pePercentile, pbPercentile: pbPercentile,
      maPosition: ma?.position ?? 'unknown', ma10: ma?.ma10, ma60: ma?.ma60,
      volumeRatio: volRatio, recentDrop: drop,
    );

    // 估算数据
    double? estNav, estChange;
    if (estimationData != null) {
      estNav = double.tryParse(estimationData['gsz']?.toString() ?? '');
      if (estChange == null) {
        estChange = double.tryParse(estimationData['gszzl']?.toString() ?? '');
      }
    }

    return FundAnalysis(
      basic: basic,
      navHistory: navData,
      klineData: klineData,
      latestNav: latestNav,
      latestAccNav: latestAccNav,
      dailyChange: dailyChange ?? estChange, // 优先用传入的，其次用估值
      estimatedNav: estNav,
      estimatedChange: estChange,
      dataDate: navData.isNotEmpty ? navData.last.date : null,
      ret1m: ret1m, ret3m: ret3m, ret6m: ret6m, ret1y: ret1y,
      ret2y: ret2y, ret3y: ret3y, retYtd: retYtd, annualReturn: annualReturn,
      risk: risk, ma: ma,
      peGrade: peGrade, pbGrade: pbGrade,
      signal: signal,
      cci: cci,
      rsi: rsi,
      macd: macd,
      bollinger: bollinger,
      kdj: kdj,
      maxConsecutiveUp: maxConsecutiveUp,
      maxConsecutiveDown: maxConsecutiveDown,
      recoveryDays: recoveryDays,
      yearlyReturns: yearlyReturns,
      holdings: holdings,
      chartData: chartData,
      isFromNetwork: navData.isNotEmpty && navData.length > 5,
    );
  }
}
