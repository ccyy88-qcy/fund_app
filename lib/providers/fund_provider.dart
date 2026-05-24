import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/fund_basic.dart';
import '../models/fund_analysis.dart';
import '../models/nav_data.dart';
import '../models/kline_data.dart';
import '../services/east_money_api.dart';
import '../services/analysis_engine.dart';

/// 基金搜索 / 分析状态管理
class FundProvider extends ChangeNotifier {
  // 搜索状态
  bool _isLoading = false;
  String? _error;
  String _currentCode = '';
  
  // 搜索结果
  FundAnalysis? _analysis;
  List<NavData> _navData = [];
  List<KlineData> _klineData = [];
  
  // 最近查询记录
  List<String> _recentCodes = [];
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCode => _currentCode;
  FundAnalysis? get analysis => _analysis;
  List<String> get recentCodes => _recentCodes;
  List<NavData> get navData => _navData;

  /// 搜索基金代码
  Future<void> searchFund(String code) async {
    final cleanCode = code.trim();
    if (cleanCode.isEmpty) return;
    if (cleanCode.length < 6) {
      _error = '基金代码格式错误（需6位）';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    _error = null;
    _currentCode = cleanCode;
    _analysis = null;
    notifyListeners();
    
    // 整体超时30秒
    try {
      await _doSearch(cleanCode).timeout(const Duration(seconds: 30));
    } on TimeoutException {
      _isLoading = false;
      _error = '请求超时，请检查网络后重试';
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '获取数据失败：$e';
      notifyListeners();
    }
  }

  Future<void> _doSearch(String cleanCode) async {
    try {
      // 1. 获取pingzhongdata（基础信息+净值历史）
      final pingzhong = await EastMoneyApi.fetchPingzhongData(cleanCode);
      
      // 2. 解析净值历史
      _navData = [];
      if (pingzhong.containsKey('navHistory')) {
        final navRaw = pingzhong['navHistory'] as List;
        final accNavRaw = pingzhong['accNavHistory'] as List? ?? [];
        
        // navRaw: [{x: timestamp_ms, y: nav}, ...]
        // accNavRaw: [{x: timestamp_ms, y: acc_nav}, ...]
        final accNavMap = <int, double>{};
        for (final item in accNavRaw) {
          if (item is Map) {
            final ts = item['x'] as int? ?? 0;
            final val = (item['y'] as num?)?.toDouble() ?? 0;
            accNavMap[ts] = val;
          }
        }
        
        for (final item in (navRaw as List).reversed) {
          if (item is Map) {
            final ts = item['x'] as int? ?? 0;
            final nav = (item['y'] as num?)?.toDouble() ?? 0;
            if (ts > 0 && nav > 0) {
              final date = DateTime.fromMillisecondsSinceEpoch(ts, isUtc: false);
              final dateStr = '${date.year}-${_pad(date.month)}-${_pad(date.day)}';
              _navData.add(NavData(
                date: dateStr,
                nav: nav,
                accNav: accNavMap[ts] ?? nav,
              ));
            }
          }
        }
        _navData.sort((a, b) => a.date.compareTo(b.date));
      }
      
      // 3. 如果净值数据不够，用F10补充
      if (_navData.length < 30) {
        final f10Data = await EastMoneyApi.fetchF10NavHistory(cleanCode);
        if (f10Data.isNotEmpty) {
          _navData = f10Data.map((d) => NavData(
            date: d['date'] as String,
            nav: (d['nav'] as num).toDouble(),
            accNav: (d['accNav'] as num).toDouble(),
          )).toList();
          _navData.sort((a, b) => a.date.compareTo(b.date));
        }
      }
      
      // 4. 判断是否是ETF，如果是则获取K线
      _klineData = [];
      final name = pingzhong['name'] as String? ?? FundNameLookup.lookup(cleanCode);
      final type = FundNameLookup.lookupType(cleanCode); // API 不含 type
      final code = pingzhong['code'] as String? ?? cleanCode;
      final isEtfType = type.toString().contains('ETF');
      
      if (isEtfType) {
        final market = SinaKlineApi.detectMarket(cleanCode);
        final klineRaw = await SinaKlineApi.fetchKline(cleanCode, market);
        if (klineRaw.isNotEmpty) {
          _klineData = klineRaw.map((d) => KlineData.fromSinaJson(d)).toList();
        }
      }
      
      // 5. 获取实时估值
      final estimation = await EastMoneyApi.fetchRealTimeEstimation(cleanCode);
      
      // 6. PE/PB估值（ETF专用，内置模拟数据）
      int? pePct, pbPct;
      if (isEtfType) {
        // 使用内置估值数据
        final val = _getValuationPercentile(cleanCode);
        pePct = val['pe'];
        pbPct = val['pb'];
      }
      
      // 7. 日涨跌幅（从估值数据或排行获取）
      double? dailyChange;
      if (estimation != null) {
        dailyChange = double.tryParse(estimation['gszzl']?.toString() ?? '');
      }
      
      // 8. 构建FundBasic
      final basic = FundBasic(
        code: cleanCode,
        name: name is String ? name : FundNameLookup.lookup(cleanCode),
        type: type is String ? type : FundNameLookup.lookupType(cleanCode),
        manager: pingzhong['manager'] as String?,
        inceptionDate: pingzhong['inceptionDate'] as String?,
      );
      
      // 9. 全量分析
      _analysis = AnalysisEngine.analyze(
        basic,
        _navData,
        _klineData.isNotEmpty ? _klineData : null,
        estimation,
        dailyChange,
        pePct,
        pbPct,
      );
      
      // 10. 记录最近查询
      _recentCodes.remove(cleanCode);
      _recentCodes.insert(0, cleanCode);
      if (_recentCodes.length > 10) _recentCodes.removeLast();
      
      _isLoading = false;
      notifyListeners();
      
    } catch (e) {
      _isLoading = false;
      _error = '获取数据失败：$e';
      notifyListeners();
    }
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  /// 内置估值分位（从现有基金数据中提取）
  Map<String, int?> _getValuationPercentile(String code) {
    const valuations = {
      '512480': {'pe': 55, 'pb': 45}, // 半导体ETF
      '515880': {'pe': 45, 'pb': 35}, // 通信ETF
      '515790': {'pe': 30, 'pb': 20}, // 光伏ETF
      '512070': {'pe': 5, 'pb': 15},  // 保险ETF
      '515220': {'pe': 35, 'pb': 45}, // 煤炭ETF
      '515070': {'pe': 74, 'pb': 24}, // AI人工智能ETF
      '562360': {'pe': 97, 'pb': 96}, // 机器人ETF
      '513100': {'pe': 87, 'pb': 100},// 纳指ETF
      '510300': {'pe': 91, 'pb': 47}, // 沪深300ETF
      '159720': {'pe': 49, 'pb': 47}, // 智能车TK
    };
    final val = valuations[code];
    if (val != null) return {'pe': val['pe'], 'pb': val['pb']};
    return {'pe': null, 'pb': null};
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 删除历史查询记录
  void removeRecent(String code) {
    _recentCodes.remove(code);
    notifyListeners();
  }
}

/// FundProvider单例
FundProvider fundProvider = FundProvider();
