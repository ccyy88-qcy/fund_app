import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/fund_provider.dart';
import '../models/fund_analysis.dart';
import '../models/nav_data.dart';
import '../models/technical_data.dart';
import '../widgets/metric_card.dart';
import '../widgets/signal_badge.dart';

class FundDetailScreen extends StatelessWidget {
  const FundDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FundProvider>(
          builder: (_, provider, __) {
            if (provider.analysis != null) {
              return Text(provider.analysis!.basic.name);
            }
            return const Text('分析中...');
          },
        ),
      ),
      body: Consumer<FundProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.searchFund(provider.currentCode),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }
          
          final analysis = provider.analysis;
          if (analysis == null) {
            return const Center(child: Text('输入基金代码开始分析'));
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 基金基本信息卡
                _buildBasicInfoCard(context, analysis),
                const SizedBox(height: 12),
                
                // 信号 + 估值
                _buildSignalCard(context, analysis),
                const SizedBox(height: 12),
                
                // 净值走势图
                _buildChartCard(context, analysis),
                const SizedBox(height: 12),
                
                // 回报数据
                _buildReturnCard(context, analysis),
                const SizedBox(height: 12),
                
                // 风险指标
                _buildRiskCard(context, analysis),
                const SizedBox(height: 12),
                
                // 均线分析
                if (analysis.ma != null)
                  _buildMaCard(context, analysis),
                const SizedBox(height: 12),
                
                // RSI
                _buildRsiCard(context, analysis),
                const SizedBox(height: 12),
                
                // MACD
                _buildMacdCard(context, analysis),
                const SizedBox(height: 12),
                
                // 布林带
                _buildBollingerCard(context, analysis),
                const SizedBox(height: 12),
                
                // KDJ
                _buildKdjCard(context, analysis),
                const SizedBox(height: 12),
                
                // 统计数据
                _buildStatsCard(context, analysis),
                const SizedBox(height: 12),
                
                // 持仓穿透
                _buildHoldingsCard(context, analysis),
                const SizedBox(height: 12),
                
                // 排名
                _buildRankCard(context, analysis),
                const SizedBox(height: 12),
                
                // 年度回报
                _buildYearlyReturnsCard(context, analysis),
                const SizedBox(height: 12),
                
                // 额外信息
                if (analysis.managementFee != null || analysis.fundSize != null)
                  _buildExtraCard(context, analysis),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context, FundAnalysis a) {
    final theme = Theme.of(context);
    final basic = a.basic;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [const Color(0xFF1A3C6E), const Color(0xFF2B5EA7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A3C6E).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    basic.code,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (basic.isEtf)
                  _buildWhiteTag('ETF'),
                if (basic.isActiveFund)
                  _buildWhiteTag('主动'),
                if (basic.isQdii)
                  _buildWhiteTag('QDII'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              basic.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(basic.type, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: 12),
            // 实时净值
            if (a.latestNav != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    a.latestNav!.toStringAsFixed(4),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  if (a.dailyChange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: (a.dailyChange! >= 0 ? Colors.red : Colors.green).withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${a.dailyChange! >= 0 ? '+' : ''}${a.dailyChange!.toStringAsFixed(2)}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '暂无数据',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.6)),
                      ),
                    ),
                  ],
                ),
            if (a.dataDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Text(
                      '数据日期: ${a.dataDate}',
                      style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                    ),
                    const Spacer(),
                    if (!a.isFromNetwork)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off, size: 10, color: Colors.white),
                            SizedBox(width: 3),
                            Text('离线数据', style: TextStyle(fontSize: 9, color: Colors.white)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    );
  }

  Widget _buildSignalCard(BuildContext context, FundAnalysis a) {
    final signal = a.signal!;
    final sigColor = Color(int.parse(signal.color.replaceFirst('#', '0xFF')));
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: sigColor.withValues(alpha: 0.3)),
        gradient: LinearGradient(
          colors: [sigColor.withValues(alpha: 0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notifications_active, size: 16, color: sigColor),
                      const SizedBox(width: 4),
                      const Text('操作信号', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SignalBadge(signal: signal),
                  const SizedBox(height: 4),
                  Text(signal.reason, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(width: 1, height: 60, color: Colors.grey[200]),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed, size: 16, color: _ratingColor(a.peGrade?.grade ?? '')),
                      const SizedBox(width: 4),
                      const Text('估值评级', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    a.ratingDisplay,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _ratingColor(a.peGrade?.grade ?? ''),
                    ),
                  ),
                  if (a.peGrade != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'PE ${a.peGrade!.percentile}%分位',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _ratingColor(String grade) {
    if (grade == '极度低估' || grade == '低估') return Colors.green;
    if (grade == '中性') return Colors.orange;
    if (grade == '高估' || grade == '极度高估') return Colors.red;
    return Colors.grey;
  }

  Widget _buildChartCard(BuildContext context, FundAnalysis a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Row(children: [Icon(Icons.timeline, size: 16, color: Color(0xFF1976D2)), SizedBox(width:6), Text('净值走势', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E)))]),
                const Spacer(),
                if (a.ma != null && a.ma!.ma10 != null)
                  _legendDot('MA10', Colors.orange),
                if (a.ma != null && a.ma!.ma60 != null)
                  _legendDot('MA60', Colors.pink),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _buildNavChart(a),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildNavChart(FundAnalysis a) {
    final navData = a.navHistory;
    if (navData == null || navData.length < 5) {
      return const Center(child: Text('数据不足'));
    }
    
    // 取最近200个点
    final List<NavData> points = navData.length > 200 
        ? navData.sublist(navData.length - 200) 
        : navData;
    
    final closes = points.map((n) => n.nav).toList();
    final minY = closes.reduce((a, b) => a < b ? a : b) * 0.98;
    final maxY = closes.reduce((a, b) => a > b ? a : b) * 1.02;
    
    // MA10
    List<double>? ma10Series;
    if (closes.length >= 10) {
      ma10Series = [];
      for (int i = 0; i < closes.length; i++) {
        if (i < 9) {
          ma10Series.add(closes[i]); // fill
        } else {
          ma10Series!.add(closes.sublist(i - 9, i + 1).reduce((a, b) => a + b) / 10);
        }
      }
    }
    
    // MA60
    List<double>? ma60Series;
    if (closes.length >= 60) {
      ma60Series = [];
      for (int i = 0; i < closes.length; i++) {
        if (i < 59) {
          ma60Series.add(closes[i]); // fill
        } else {
          ma60Series!.add(closes.sublist(i - 59, i + 1).reduce((a, b) => a + b) / 60);
        }
      }
    }
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(2),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (points.length / 4).ceilToDouble(),
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= points.length) return const SizedBox();
                return Text(
                  points[idx].date.substring(5),
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (points.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          // 净值线
          LineChartBarData(
            spots: List.generate(closes.length, (i) => FlSpot(i.toDouble(), closes[i])),
            isCurved: true,
            color: const Color(0xFF1976D2),
            barWidth: 2,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: const Color(0x191976D2)),
          ),
          // MA10
          if (ma10Series != null)
            LineChartBarData(
              spots: List.generate(ma10Series.length, (i) => FlSpot(i.toDouble(), ma10Series![i])),
              isCurved: true,
              color: Colors.orange,
              barWidth: 1.5,
              dotData: FlDotData(show: false),
            ),
          // MA60
          if (ma60Series != null)
            LineChartBarData(
              spots: List.generate(ma60Series.length, (i) => FlSpot(i.toDouble(), ma60Series![i])),
              isCurved: true,
              color: Colors.pink,
              barWidth: 1.5,
              dotData: FlDotData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(BuildContext context, FundAnalysis a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.bar_chart, size: 16, color: Color(0xFF2196F3)), SizedBox(width:6), Text('阶段回报', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E)))]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricCard(label: '日涨跌', value: a.dailyChange, suffix: '%'),
                MetricCard(label: '近1月', value: a.ret1m, suffix: '%'),
                MetricCard(label: '近3月', value: a.ret3m, suffix: '%'),
                MetricCard(label: '近6月', value: a.ret6m, suffix: '%'),
                MetricCard(label: '近1年', value: a.ret1y, suffix: '%'),
                MetricCard(label: '近2年', value: a.ret2y, suffix: '%'),
                MetricCard(label: '近3年', value: a.ret3y, suffix: '%'),
                MetricCard(label: '年初至今', value: a.retYtd, suffix: '%'),
              ],
            ),
            if (a.annualReturn != null) ...[
              const SizedBox(height: 8),
              MetricCard(label: '年化收益', value: a.annualReturn, suffix: '%', large: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskCard(BuildContext context, FundAnalysis a) {
    final r = a.risk;
    if (r == null) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.shield_outlined, size: 16, color: Color(0xFFFF5722)), SizedBox(width:6), Text('风险指标', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E)))]),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                MetricCard(label: '年化波动', value: r.annualVolatility, suffix: '%'),
                MetricCard(label: '历史最大回撤', value: r.maxDrawdown, suffix: '%'),
                MetricCard(label: '近1月回撤', value: r.m1Drawdown, suffix: '%'),
                MetricCard(label: '近3月回撤', value: r.m3Drawdown, suffix: '%'),
                MetricCard(label: '当前回撤', value: r.currentDrawdown, suffix: '%'),
                if (r.sharpeRatio != null)
                  MetricCard(label: '夏普比率', value: r.sharpeRatio, prefix: ''),
                if (r.winRate != null)
                  MetricCard(label: '胜率', value: r.winRate, suffix: '%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaCard(BuildContext context, FundAnalysis a) {
    final ma = a.ma!;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.2)),
        gradient: LinearGradient(
          colors: [const Color(0xFF9C27B0).withValues(alpha: 0.05), Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.show_chart, size: 16, color: const Color(0xFF9C27B0)),
            const SizedBox(width: 6),
            const Text('均线 / CCI 分析', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E))),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _maItem('MA10', ma.ma10, a.latestNav),
            _maItem('MA60', ma.ma60, a.latestNav),
            _maItem('乖离率', ma.deviationPercent, null, suffix: '%'),
            InfoChip(label: ma.isGoldenCross ? '金叉 ↑' : ma.isDeathCross ? '死叉 ↓' : '横盘', color: ma.isGoldenCross ? Colors.green : ma.isDeathCross ? Colors.red : Colors.grey),
            InfoChip(label: ma.position == 'above' ? '↑ 线上' : '↓ 线下', color: ma.position == 'above' ? Colors.green : Colors.red),
            if (a.cci != null)
              _cciChip(a.cci!),
          ]),
          if (a.cci != null) ...[
            const SizedBox(height: 6),
            Text(
              _cciInterpretation(a.cci!),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _cciChip(double cci) {
    final color = cci > 100 ? Colors.red : (cci < -100 ? Colors.green : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        'CCI: ${cci.toStringAsFixed(1)}',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  String _cciInterpretation(double cci) {
    if (cci > 200) return '⚠️ CCI超买(>200)，短期可能回调';
    if (cci > 100) return '⚡ CCI进入超买区(>100)，注意风险';
    if (cci < -200) return '💎 CCI超卖(< -200)，短期可能反弹';
    if (cci < -100) return '🔍 CCI进入超卖区(< -100)，关注反弹机会';
    if (cci > 0) return '📈 CCI为正，短期偏强';
    return '📉 CCI为负，短期偏弱';
  }

  Widget _maItem(String label, double? value, double? compare, {String suffix = ''}) {
    if (value == null) return const SizedBox();
    final vsCompare = compare != null ? ((value / compare - 1) * 100) : null;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          const SizedBox(height: 2),
          Text(
            '$label: ${value.toStringAsFixed(4)}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExtraCard(BuildContext context, FundAnalysis a) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(Icons.info_outline, size: 16, color: Color(0xFF607D8B)), SizedBox(width:6), Text('其他信息', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E)))]),
            const SizedBox(height: 8),
            if (a.fundSize != null)
              _infoRow('基金规模', '${a.fundSize!.toStringAsFixed(2)}亿'),
            if (a.stockPosition != null)
              _infoRow('股票仓位', '${a.stockPosition!.toStringAsFixed(1)}%'),
            if (a.managementFee != null)
              _infoRow('管理费率', '${a.managementFee!.toStringAsFixed(2)}%'),
            if (a.custodyFee != null)
              _infoRow('托管费率', '${a.custodyFee!.toStringAsFixed(2)}%'),
            if (a.basic.manager != null)
              _infoRow('基金经理', a.basic.manager!),
            if (a.basic.inceptionDate != null)
              _infoRow('成立日期', a.basic.inceptionDate!),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRsiCard(BuildContext context, FundAnalysis a) {
    if (a.rsi == null) return const SizedBox();
    final rsi = a.rsi!;
    final series = a.chartData?.rsiSeries ?? [];
    Color color;
    String label;
    if (rsi >= 70) { color = Colors.red; label = '超买'; }
    else if (rsi <= 30) { color = Colors.green; label = '超卖'; }
    else { color = Colors.blue; label = '中性'; }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha:0.2)), gradient: LinearGradient(colors: [color.withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.speed, size:16, color:color), SizedBox(width:6), Text('RSI(14)  $rsi  $label', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        if (series.length >= 5) ...[
          const SizedBox(height:8),
          SizedBox(height:130, child: _buildChart(series.map((p)=>FlSpot(p.index.toDouble(), p.value)).toList(),
            lineColor: color, yMin: 0, yMax: 100,
            extraLines: [
              LineChartBarData(spots:[FlSpot(0,70),FlSpot(series.last.index.toDouble(),70)], color:Colors.red.withValues(alpha:0.3), barWidth:1, dotData:FlDotData(show:false)),
              LineChartBarData(spots:[FlSpot(0,30),FlSpot(series.last.index.toDouble(),30)], color:Colors.green.withValues(alpha:0.3), barWidth:1, dotData:FlDotData(show:false)),
            ],
          )),
        ],
        const SizedBox(height:4),
        Text(rsi >= 70 ? '⚠️ 短期超买，注意回调风险' : (rsi <= 30 ? '💎 短期超卖，关注反弹机会' : '📊 中性区间，趋势平稳'), style: TextStyle(fontSize:11, color:Colors.grey[500])),
      ]),
    );
  }

  Widget _buildMacdCard(BuildContext context, FundAnalysis a) {
    if (a.macd == null) return const SizedBox();
    final m = a.macd!;
    final series = a.chartData?.macdSeries ?? [];
    final isBull = m.histogram != null && m.histogram! > 0;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF1565C0).withValues(alpha:0.2)), gradient: LinearGradient(colors: [const Color(0xFF1565C0).withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.show_chart, size:16, color:const Color(0xFF1565C0)), SizedBox(width:6), const Text('MACD(12,26,9)', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        if (series.length >= 5) ...[
          const SizedBox(height:8),
          SizedBox(height:140, child: _buildMacdChart(series)),
        ],
        const SizedBox(height:6),
        _metricRow('MACD', m.macd?.toStringAsFixed(4) ?? '—', const Color(0xFF1565C0)),
        _metricRow('信号线', m.signal?.toStringAsFixed(4) ?? '—', Colors.orange),
        _metricRow('柱状图', m.histogram?.toStringAsFixed(4) ?? '—', isBull ? Colors.green : Colors.red),
        Text(isBull ? '📈 多头信号' : '📉 空头信号', style: TextStyle(fontSize:11, color:Colors.grey[500])),
      ]),
    );
  }

  Widget _buildBollingerCard(BuildContext context, FundAnalysis a) {
    if (a.bollinger == null) return const SizedBox();
    final b = a.bollinger!;
    final series = a.chartData?.bollingerSeries ?? [];
    final nav = a.latestNav;
    String pos; Color color;
    if (nav != null && nav >= (b.upper ?? double.infinity)) { pos = '触及上轨'; color = Colors.red; }
    else if (nav != null && nav <= (b.lower ?? 0)) { pos = '触及下轨'; color = Colors.green; }
    else { pos = '轨道内运行'; color = Colors.blue; }
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha:0.2)), gradient: LinearGradient(colors: [color.withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.auto_graph, size:16, color:color), SizedBox(width:6), const Text('布林带(20,2)', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        if (series.length >= 5) ...[
          const SizedBox(height:8),
          SizedBox(height:140, child: _buildBollingerChart(series, a.navHistory?.map((n)=>n.nav).toList() ?? [])),
        ],
        const SizedBox(height:6),
        _metricRow('上轨', b.upper?.toStringAsFixed(4) ?? '—', Colors.red),
        _metricRow('中轨', b.middle?.toStringAsFixed(4) ?? '—', Colors.blue),
        _metricRow('下轨', b.lower?.toStringAsFixed(4) ?? '—', Colors.green),
        _metricRow('带宽%', b.bandwidth?.toStringAsFixed(2) ?? '—', Colors.grey),
        Text('📊 $pos', style: TextStyle(fontSize:11, color:Colors.grey[500])),
      ]),
    );
  }

  Widget _buildKdjCard(BuildContext context, FundAnalysis a) {
    if (a.kdj == null) return const SizedBox();
    final k = a.kdj!;
    final series = a.chartData?.kdjSeries ?? [];
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF7B1FA2).withValues(alpha:0.2)), gradient: LinearGradient(colors: [const Color(0xFF7B1FA2).withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.graphic_eq, size:16, color:const Color(0xFF7B1FA2)), SizedBox(width:6), const Text('KDJ(9,3,3)', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        if (series.length >= 5) ...[
          const SizedBox(height:8),
          SizedBox(height:140, child: _buildKdjChart(series)),
        ],
        const SizedBox(height:6),
        Wrap(spacing:12, runSpacing:6, children: [
          _kdjChip('K', k.k, Colors.blue),
          _kdjChip('D', k.d, Colors.orange),
          _kdjChip('J', k.j, (k.j ?? 50) > 100 ? Colors.red : (k.j ?? 50) < 0 ? Colors.green : Colors.grey),
        ]),
      ]),
    );
  }

  /// 通用单线图
  Widget _buildChart(List<FlSpot> spots, {required Color lineColor, double? yMin, double? yMax, List<LineChartBarData>? extraLines, bool fill = false}) {
    if (spots.isEmpty) return const SizedBox();
    final yVals = spots.map((s)=>s.y).toList();
    final myMin = yMin ?? (yVals.reduce((a,b)=>a<b?a:b) * 0.95);
    final myMax = yMax ?? (yVals.reduce((a,b)=>a>b?a:b) * 1.05);
    final allBars = <LineChartBarData>[
      LineChartBarData(spots: spots, isCurved: true, color: lineColor, barWidth: 1.8, dotData: FlDotData(show: false), belowBarData: fill ? BarAreaData(show:true, color: lineColor.withValues(alpha:0.08)) : BarAreaData(show:false)),
      if (extraLines != null) ...extraLines,
    ];
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, horizontalInterval: (myMax-myMin)/4, getDrawingHorizontalLine: (v)=>FlLine(color: Colors.grey.withValues(alpha:0.1), strokeWidth:0.5)),
      titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v,_)=>Text(v.toStringAsFixed(0), style: TextStyle(fontSize:8, color:Colors.grey[500])))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      minX: spots.first.x, maxX: spots.last.x, minY: myMin, maxY: myMax,
      lineBarsData: allBars,
    ));
  }

  /// MACD 多线图（MACD线+信号线+柱状图）
  Widget _buildMacdChart(List<MacdPoint> series) {
    final macdSpots = <FlSpot>[];
    final sigSpots = <FlSpot>[];
    final barSpots = <BarChartGroupData>[];
    for (final p in series) {
      if (p.macd != null) macdSpots.add(FlSpot(p.index.toDouble(), p.macd!));
      if (p.signal != null) sigSpots.add(FlSpot(p.index.toDouble(), p.signal!));
    }
    if (macdSpots.isEmpty) return const SizedBox();
    final allY = macdSpots.map((s)=>s.y).followedBy(sigSpots.map((s)=>s.y)).toList();
    final myMin = allY.reduce((a,b)=>a<b?a:b) * 1.2;
    final myMax = allY.reduce((a,b)=>a>b?a:b) * 1.2;
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, getDrawingHorizontalLine: (v)=>FlLine(color: Colors.grey.withValues(alpha:0.1), strokeWidth:0.5)),
      titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v,_)=>Text(v.toStringAsFixed(2), style: TextStyle(fontSize:8, color:Colors.grey[500])))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: macdSpots, isCurved: true, color: const Color(0xFF1565C0), barWidth: 1.5, dotData: FlDotData(show: false)),
        LineChartBarData(spots: sigSpots, isCurved: true, color: Colors.orange, barWidth: 1.5, dotData: FlDotData(show: false)),
      ],
      minX: series.first.index.toDouble(), maxX: series.last.index.toDouble(), minY: myMin, maxY: myMax,
    ));
  }

  /// 布林带三线图 + 净值线
  Widget _buildBollingerChart(List<BollingerPoint> bSeries, List<double> closes) {
    if (bSeries.isEmpty) return const SizedBox();
    final upper = bSeries.where((p)=>p.upper!=null).map((p)=>FlSpot(p.index.toDouble(), p.upper!)).toList();
    final mid = bSeries.where((p)=>p.middle!=null).map((p)=>FlSpot(p.index.toDouble(), p.middle!)).toList();
    final lower = bSeries.where((p)=>p.lower!=null).map((p)=>FlSpot(p.index.toDouble(), p.lower!)).toList();
    // 配对的净值线
    final startIdx = bSeries.first.index;
    final navSpots = <FlSpot>[];
    for (int i = startIdx; i < closes.length && navSpots.length < bSeries.length; i++) {
      navSpots.add(FlSpot(i.toDouble(), closes[i]));
    }
    if (upper.isEmpty) return const SizedBox();
    final allY = [...upper.map((s)=>s.y), ...lower.map((s)=>s.y)];
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, getDrawingHorizontalLine: (v)=>FlLine(color: Colors.grey.withValues(alpha:0.1), strokeWidth:0.5)),
      titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, getTitlesWidget: (v,_)=>Text(v.toStringAsFixed(2), style: TextStyle(fontSize:8, color:Colors.grey[500])))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: upper, isCurved: true, color: Colors.red.withValues(alpha:0.5), barWidth: 1, dotData: FlDotData(show: false)),
        LineChartBarData(spots: mid, isCurved: true, color: Colors.blue.withValues(alpha:0.5), barWidth: 1, dotData: FlDotData(show: false)),
        LineChartBarData(spots: lower, isCurved: true, color: Colors.green.withValues(alpha:0.5), barWidth: 1, dotData: FlDotData(show: false)),
        LineChartBarData(spots: navSpots, isCurved: true, color: Colors.black87, barWidth: 1.8, dotData: FlDotData(show: false)),
      ],
      minX: bSeries.first.index.toDouble(), maxX: bSeries.last.index.toDouble(),
      minY: allY.reduce((a,b)=>a<b?a:b) * 0.98, maxY: allY.reduce((a,b)=>a>b?a:b) * 1.02,
    ));
  }

  /// KDJ 三线图
  Widget _buildKdjChart(List<KdjPoint> series) {
    if (series.isEmpty) return const SizedBox();
    final kSpots = series.where((p)=>p.k!=null).map((p)=>FlSpot(p.index.toDouble(), p.k!)).toList();
    final dSpots = series.where((p)=>p.d!=null).map((p)=>FlSpot(p.index.toDouble(), p.d!)).toList();
    final jSpots = series.where((p)=>p.j!=null).map((p)=>FlSpot(p.index.toDouble(), p.j!)).toList();
    return LineChart(LineChartData(
      gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false, getDrawingHorizontalLine: (v)=>FlLine(color: Colors.grey.withValues(alpha:0.1), strokeWidth:0.5)),
      titlesData: FlTitlesData(leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, getTitlesWidget: (v,_)=>Text(v.toStringAsFixed(0), style: TextStyle(fontSize:8, color:Colors.grey[500])))), bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false))),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(spots: kSpots, isCurved: true, color: Colors.blue, barWidth: 1.5, dotData: FlDotData(show: false)),
        LineChartBarData(spots: dSpots, isCurved: true, color: Colors.orange, barWidth: 1.5, dotData: FlDotData(show: false)),
        LineChartBarData(spots: jSpots, isCurved: true, color: Colors.grey, barWidth: 1.5, dotData: FlDotData(show: false)),
      ],
      minX: series.first.index.toDouble(), maxX: series.last.index.toDouble(), minY: -50, maxY: 150,
      extraLinesData: ExtraLinesData(horizontalLines: [
        HorizontalLine(y: 100, color: Colors.red.withValues(alpha:0.2), strokeWidth: 0.5),
        HorizontalLine(y: 0, color: Colors.green.withValues(alpha:0.2), strokeWidth: 0.5),
      ]),
    ));
  }

  Widget _kdjChip(String label, double? val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:14, vertical:8),
      decoration: BoxDecoration(color:color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color:color.withValues(alpha:0.3))),
      child: Text('$label: ${val?.toStringAsFixed(1) ?? '--'}', style: TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:color)),
    );
  }

  Widget _buildHoldingsCard(BuildContext context, FundAnalysis a) {
    if (a.holdings == null || a.holdings!.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE65100).withValues(alpha:0.2)), gradient: LinearGradient(colors: [const Color(0xFFE65100).withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.folder_open, size:16, color:const Color(0xFFE65100)), SizedBox(width:6), const Text('前10大持仓', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        const SizedBox(height:8),
        ...a.holdings!.take(10).map((h) => Padding(
          padding: const EdgeInsets.symmetric(vertical:3),
          child: Row(children: [
            Container(width:4, height:16, decoration: BoxDecoration(color:const Color(0xFFE65100), borderRadius: BorderRadius.circular(2))),
            SizedBox(width:8),
            Expanded(child: Text(h.code, style: TextStyle(fontSize:12, fontWeight:FontWeight.w500))),
            const SizedBox(width:8),
            Text(h.name, style: TextStyle(fontSize:12, color:Colors.grey[600])),
            if (h.ratio != null) ...[SizedBox(width:6), Text('${h.ratio!.toStringAsFixed(1)}%', style: TextStyle(fontSize:12, fontWeight:FontWeight.w600, color:Color(0xFFE65100)))],
          ]),
        )),
      ]),
    );
  }

  Widget _buildStatsCard(BuildContext context, FundAnalysis a) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF37474F).withValues(alpha:0.15)), gradient: LinearGradient(colors: [const Color(0xFF37474F).withValues(alpha:0.04), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.analytics, size:16, color:const Color(0xFF37474F)), SizedBox(width:6), const Text('统计数据', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children: [
          if (a.maxConsecutiveUp != null) _statChip('最大连涨', '${a.maxConsecutiveUp}天', Colors.red),
          if (a.maxConsecutiveDown != null) _statChip('最大连跌', '${a.maxConsecutiveDown}天', Colors.green),
          if (a.recoveryDays != null && a.recoveryDays! > 0) _statChip('回撤恢复', '${a.recoveryDays}天', Colors.orange),
        ]),
      ]),
    );
  }
  Widget _statChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
      decoration: BoxDecoration(color:color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color:color.withValues(alpha:0.2))),
      child: Column(children: [
        Text(label, style: TextStyle(fontSize:10, color:Colors.grey[500])),
        const SizedBox(height:2),
        Text(value, style: TextStyle(fontSize:14, fontWeight:FontWeight.bold, color:color)),
      ]),
    );
  }

  Widget _metricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical:2),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize:12, color:Colors.grey[600])),
        Text(value, style: TextStyle(fontSize:13, fontWeight:FontWeight.w600, color:color)),
      ]),
    );
  }

  Widget _buildYearlyReturnsCard(BuildContext context, FundAnalysis a) {
    if (a.yearlyReturns == null || a.yearlyReturns!.isEmpty) return const SizedBox();
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF00838F).withValues(alpha:0.2)), gradient: LinearGradient(colors: [const Color(0xFF00838F).withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.calendar_month, size:16, color:const Color(0xFF00838F)), SizedBox(width:6), const Text('年度回报', style: TextStyle(fontSize:14, fontWeight:FontWeight.w600, color:Color(0xFF1A3C6E)))]),
        const SizedBox(height:10),
        Wrap(spacing:8, runSpacing:8, children: a.yearlyReturns!.map((yr) {
          final color = (yr.return_ ?? 0) >= 0 ? Colors.red : Colors.green;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal:12, vertical:8),
            decoration: BoxDecoration(color:color.withValues(alpha:0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color:color.withValues(alpha:0.2))),
            child: Column(children: [
              Text('${yr.year}', style: TextStyle(fontSize:10, color:Colors.grey[500])),
              const SizedBox(height:2),
              Text('${yr.return_ != null ? yr.return_!.toStringAsFixed(1) : 'N/A'}%', style: TextStyle(fontSize:14, fontWeight:FontWeight.bold, color:color)),
            ]),
          );
        }).toList()),
      ]),
    );
  }

  Widget _buildRankCard(BuildContext context, FundAnalysis a) {
    if (a.categoryRank == null) return const SizedBox();
    final r = a.categoryRank!;
    final pct = r.percentile;
    Color color;
    if (pct <= 25) color = Colors.green;
    else if (pct <= 50) color = Colors.blue;
    else if (pct <= 75) color = Colors.orange;
    else color = Colors.red;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color:color.withValues(alpha:0.2)), gradient: LinearGradient(colors: [color.withValues(alpha:0.05), Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Container(width:56, height:56, decoration: BoxDecoration(shape: BoxShape.circle, color:color.withValues(alpha:0.1), border: Border.all(color:color, width:2)), child: Center(child: Text(r.display, style: TextStyle(fontSize:13, fontWeight:FontWeight.bold, color:color)))),
        const SizedBox(width:12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('同类排名', style: TextStyle(fontSize:13, fontWeight:FontWeight.w600)),
          const SizedBox(height:2),
          Text('${r.category} · 前${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize:12, color:Colors.grey[500])),
        ])),
      ]),
    );
  }
}

class InfoChip extends StatelessWidget {
  final String label;
  final Color color;
  const InfoChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}
