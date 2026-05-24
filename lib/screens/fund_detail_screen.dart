import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/fund_provider.dart';
import '../models/fund_analysis.dart';
import '../models/nav_data.dart';
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
