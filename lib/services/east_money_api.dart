import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'dart:convert';
import 'dart:math';

/// 统一API配置
class ApiConfig {
  // 东方财富接口
  static const String eastMoneyPingzhong = 'https://fund.eastmoney.com/pingzhongdata';
  static const String eastMoneyF10 = 'https://fund.eastmoney.com/f10/F10DataApi.aspx';
  static const String eastMoneyRank = 'https://fund.eastmoney.com/data/rankhandler.aspx';
  static const String eastMoneyEstimation = 'https://fundgz.1234567.com.cn/js';

  // 新浪K线
  static const String sinaKline = 'https://money.finance.sina.com.cn/quotes_service/api/json_v2.php/CN_MarketData.getKLineData';
  
  // 妙想搜索
  static const String mxSearch = 'https://search-api.10jqka.com.cn/search';
  
  // 东方财富ETF实时行情
  static const String eastMoneyEtf = 'https://push2.eastmoney.com/api/qt/stock/get';

  static const Duration readTimeout = Duration(seconds: 10);
  static const Duration connectTimeout = Duration(seconds: 8);
  static const String userAgent = 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36';
  
  /// 创建带连接超时的 HTTP 客户端
  static http.Client createClient() {
      return IOClient(
        HttpClient()
        ..connectionTimeout = connectTimeout
        ..idleTimeout = const Duration(seconds: 15),
    );
  }
}

/// 东方财富基金数据API
class EastMoneyApi {
  static final _client = ApiConfig.createClient();

  /// 获取基金历史净值（pingzhongdata）
  /// 注意：东方财富 API 返回 GBK 编码的 JS 文件，需手动 UTF-8 解码
  static Future<Map<String, dynamic>> fetchPingzhongData(String code) async {
    final url = '${ApiConfig.eastMoneyPingzhong}/$code.js';
    try {
      final resp = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': ApiConfig.userAgent},
      ).timeout(ApiConfig.readTimeout);
      
      if (resp.statusCode != 200) return {};
      
      // 强制 UTF-8 解码，避免乱码
      final text = utf8.decode(resp.bodyBytes);
      final result = <String, dynamic>{};
      
      try {
        // 解析净值趋势（使用非贪婪+平衡匹配）
        final navMatch = RegExp(r'var Data_netWorthTrend = (\[[\s\S]*?\n\]);', multiLine: true).firstMatch(text);
        if (navMatch != null) {
          final raw = jsonDecode(navMatch.group(1)!) as List;
          result['navHistory'] = raw;
        } else {
          // 备选正则
          final navMatch2 = RegExp(r'Data_netWorthTrend\s*=\s*(\[[\s\S]*?\])\s*;').firstMatch(text);
          if (navMatch2 != null) {
            final raw = jsonDecode(navMatch2.group(1)!) as List;
            result['navHistory'] = raw;
          }
        }
      } catch (e) {
        // NAV 解析失败不阻断
      }
      
      try {
        // 解析累计净值
        final accNavMatch = RegExp(r'Data_ACWorthTrend\s*=\s*(\[[\s\S]*?\])\s*;').firstMatch(text);
        if (accNavMatch != null) {
          result['accNavHistory'] = jsonDecode(accNavMatch.group(1)!);
        }
      } catch (_) {}
      
      // 基金名称（强制 UTF-8 已确保不乱码）
      try {
        final nameMatch = RegExp(r'var fS_name = "([^"]+)"').firstMatch(text);
        if (nameMatch != null) result['name'] = nameMatch.group(1)!;
      } catch (_) {}
      
      // 基金代码
      try {
        final codeMatch = RegExp(r'fS_code = "([^"]+)"').firstMatch(text);
        if (codeMatch != null) result['code'] = codeMatch.group(1)!;
      } catch (_) {}
      
      // 收益率（直接从JS变量获取，准确）
      try {
        final s1y = RegExp(r'syl_1n="([\d\.\-]+)"').firstMatch(text);
        if (s1y != null) result['syl_1y'] = double.tryParse(s1y.group(1)!);
        final s6y = RegExp(r'syl_6y="([\d\.\-]+)"').firstMatch(text);
        if (s6y != null) result['syl_6m'] = double.tryParse(s6y.group(1)!);
        final s3y = RegExp(r'syl_3y="([\d\.\-]+)"').firstMatch(text);
        if (s3y != null) result['syl_3m'] = double.tryParse(s3y.group(1)!);
        final s1m = RegExp(r'syl_1y="([\d\.\-]+)"').firstMatch(text);
        if (s1m != null) result['syl_1m'] = double.tryParse(s1m.group(1)!);
      } catch (_) {}
      
      // 基金经理
      try {
        final mgrMatch = RegExp(r'var基金经理 = "([^"]+)"').firstMatch(text);
        if (mgrMatch != null) result['manager'] = mgrMatch.group(1)!;
      } catch (_) {}
      
      // 成立日期
      try {
        final incepMatch = RegExp(r'var成立日期 = "([^"]+)"').firstMatch(text);
        if (incepMatch != null) result['inceptionDate'] = incepMatch.group(1)!;
      } catch (_) {}
      
      // 规模
      try {
        final sizeMatch = RegExp(r'var基金规模 = "([^"]+)"').firstMatch(text);
        if (sizeMatch != null) result['fundSize'] = sizeMatch.group(1)!;
      } catch (_) {}
      
      return result;
    } catch (_) {
      return {};
    }
  }

  /// 获取基金F10历史净值（分页）
  static Future<List<Map<String, dynamic>>> fetchF10NavHistory(String code, {int pages = 5}) async {
    final records = <Map<String, dynamic>>[];
    for (int page = 1; page <= pages; page++) {
      try {
        final url = '${ApiConfig.eastMoneyF10}?type=lsjz&code=$code&page=$page&per=20&sdate=&edate=';
        final resp = await _client.get(
          Uri.parse(url),
          headers: {'User-Agent': ApiConfig.userAgent},
        ).timeout(ApiConfig.readTimeout);
        
        if (resp.statusCode != 200) break;
        
        // 解析HTML表格
        final tableRegex = RegExp(
          r'<td>(\d{4}-\d{2}-\d{2})</td><td[^>]*>([\d\.]+)</td><td[^>]*>([\d\.]+)</td>',
        );
        final matches = tableRegex.allMatches(resp.body);
        if (matches.isEmpty) break;
        
        for (final m in matches) {
          records.add({
            'date': m.group(1),
            'nav': double.parse(m.group(2)!),
            'accNav': double.parse(m.group(3)!),
          });
        }
      } catch (_) {
        break;
      }
    }
    return records;
  }

  /// 获取基金排行/回报数据
  static Future<List<Map<String, dynamic>>> fetchFundRanking(List<String> codes) async {
    // 使用东方财富基金排行API
    final codeStr = codes.join(',');
    final url = '${ApiConfig.eastMoneyRank}?op=ph&dt=kf&ft=all&rs=&gs=0&sc=zzf&st=asc&sd=&ed=&qdii=&tabSubType=ABBR&pi=1&pn=200&dx=1&v=0.8764246452077373';
    
    try {
      final resp = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': ApiConfig.userAgent, 'Referer': 'https://fund.eastmoney.com/'},
      ).timeout(ApiConfig.readTimeout);
      
      if (resp.statusCode != 200) return [];
      
      final text = resp.body;
      // 提取JSON数据
      final jsonMatch = RegExp(r'\[.*?\]', dotAll: true).firstMatch(text);
      if (jsonMatch == null) return [];
      
      final datas = jsonDecode(jsonMatch.group(0)!) as List;
      final results = <Map<String, dynamic>>[];
      
      for (final data in datas) {
        final parts = (data as String).split('|');
        if (parts.length < 10) continue;
        
        final fc = parts[1].trim();
        if (!codes.contains(fc)) continue;
        
        results.add({
          'code': fc,
          'name': parts[2].trim(),
          'type': parts[4].trim(),
          'nav': parts[3].trim(),
          'dailyChange': parts[5].trim(),
          'ret1w': parts[6].trim(),
          'ret1m': parts[7].trim(),
          'ret3m': parts[8].trim(),
          'ret6m': parts[9].trim(),
          'ret1y': parts[10].trim(),
          'ret2y': parts[11].trim(),
          'ret3y': parts[12].trim(),
          'retYtd': parts[13].trim(),
        });
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  /// 获取实时估值
  static Future<Map<String, dynamic>?> fetchRealTimeEstimation(String code) async {
    try {
      final url = '${ApiConfig.eastMoneyEstimation}/$code.js';
      final resp = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': ApiConfig.userAgent, 'Referer': 'https://fund.eastmoney.com/'},
      ).timeout(ApiConfig.readTimeout);
      
      if (resp.statusCode != 200) return null;
      
      // 格式: jsonpgz({...});
      final jsonMatch = RegExp(r'jsonpgz\((.+)\)').firstMatch(resp.body);
      if (jsonMatch == null) return null;
      
      return jsonDecode(jsonMatch.group(1)!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

/// 新浪K线API
class SinaKlineApi {
  static final _client = ApiConfig.createClient();

  /// 获取ETF K线数据
  /// market: 'sh' 或 'sz'
  static Future<List<Map<String, dynamic>>> fetchKline(String code, String market, {int days = 2000}) async {
    try {
      final url = '${ApiConfig.sinaKline}?symbol=$market$code&scale=240&datalen=$days';
      final resp = await _client.get(
        Uri.parse(url),
        headers: {'User-Agent': ApiConfig.userAgent},
      ).timeout(ApiConfig.readTimeout);
      
      if (resp.statusCode != 200) return [];
      
      final data = jsonDecode(resp.body);
      if (data is! List || data.isEmpty) return [];
      
      return data.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// 判断ETF市场（上海/深圳）
  static String detectMarket(String code) {
    // 6开头上海, 0/1/2/3开头深圳, 159开头深圳
    if (code.startsWith('6')) return 'sh';
    return 'sz';
  }
}

/// 基金名称查询（内置部分常见基金）
class FundNameLookup {
  static const Map<String, String> knownFunds = {
    '001016': '华夏沪深300ETF联接C',
    '002207': '前海开源金银珠宝混合C',
    '005734': '华夏沪港通ETF联接',
    '020434': '金信量化精选混合C',
    '022365': '永赢科技智选混合C',
    '512480': '半导体ETF',
    '515880': '通信ETF',
    '515790': '光伏ETF',
    '512070': '保险ETF',
    '515220': '煤炭ETF',
    '515070': 'AI人工智能ETF',
    '562360': '机器人ETF银华',
    '513100': '纳指ETF',
    '510300': '沪深300ETF',
    '159720': '智能车TK',
    '040046': '华安纳斯达克100ETF联接A',
    '270042': '广发纳斯达克100ETF联接A',
    '006075': '博时标普500ETF联接C',
    '006105': '华宝标普油气上游股票C',
    '006479': '广发美国房地产指数C',
  };

  static const Map<String, String> knownTypes = {
    '001016': 'ETF联接',
    '020434': '混合型-灵活',
    '022365': '混合型-偏股',
    '512480': 'ETF-行业指数',
    '515880': 'ETF-行业指数',
    '515790': 'ETF-行业指数',
    '512070': 'ETF-行业指数',
    '515220': 'ETF-行业指数',
    '515070': 'ETF-行业指数',
    '562360': 'ETF-行业指数',
    '513100': 'ETF-QDII',
    '510300': 'ETF-规模指数',
    '159720': 'ETF-行业指数',
    '040046': 'ETF联接-QDII',
    '270042': 'ETF联接-QDII',
    '006075': 'QDII-指数',
    '006105': 'QDII-商品',
    '006479': 'QDII-房地产',
  };

  static String lookup(String code) => knownFunds[code] ?? '查询中...';
  static String lookupType(String code) => knownTypes[code] ?? '';
}
