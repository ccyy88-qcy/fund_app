import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/fund_provider.dart';
import 'fund_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String code) {
    final clean = code.trim();
    if (clean.isEmpty || clean.length < 6) return;
    context.read<FundProvider>().searchFund(clean);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const FundDetailScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ─── 渐变头部 ───
          _buildHeader(),
          // ─── 内容 ───
          Expanded(
            child: Consumer<FundProvider>(
              builder: (context, provider, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 最近查询（带删除）
                      if (provider.recentCodes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildSectionTitle(Icons.history, '最近查询'),
                        const SizedBox(height: 6),
                        ...provider.recentCodes.take(5).map(
                          (code) => _buildRecentItem(context, provider, code),
                        ),
                        const SizedBox(height: 20),
                      ],
                      // 热门标的
                      _buildSectionTitle(Icons.trending_up, '热门标的'),
                      const SizedBox(height: 10),
                      _buildQuickGrid(context),
                      // 搜索提示
                      const SizedBox(height: 24),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 14, color: Colors.amber[700]),
                              const SizedBox(width: 6),
                              Text(
                                '输入6位基金代码，一键全量分析',
                                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ═══ 渐变头部 ═══
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20, right: 20, bottom: 24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A3C6E), Color(0xFF2B5EA7), Color(0xFF3A7BD5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        '基金分析器',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 34),
                    child: Text(
                      '实时净值 · 技术指标 · 交易信号',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info_outline, color: Colors.white60, size: 20),
                onPressed: () => _showAbout(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
        ],
      ),
    );
  }

  // ═══ 搜索栏 ═══
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          const Padding(padding: EdgeInsets.only(left: 14), child: Icon(Icons.search, color: Color(0xFF1A3C6E), size: 22)),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '输入基金代码，如 020434',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey, size: 18),
              onPressed: () => setState(() => _searchController.clear()),
            ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A3C6E), Color(0xFF2B5EA7)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _search(_searchController.text),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.travel_explore, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('分析', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ 板块标题 ═══
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3C6E).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF1A3C6E)),
        ),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1A3C6E))),
      ],
    );
  }

  // ═══ 最近查询（可删除）═══
  Widget _buildRecentItem(BuildContext context, FundProvider provider, String code) {
    return Dismissible(
      key: Key(code),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
      ),
      onDismissed: (_) => provider.removeRecent(code),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 3),
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A3C6E).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.history, size: 16, color: Color(0xFF1A3C6E)),
          ),
          title: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          subtitle: Text('点击重新查询', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_left, size: 14, color: Colors.grey[300]),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
          onTap: () => _search(code),
        ),
      ),
    );
  }

  // ═══ 热门标的网格 ═══
  Widget _buildQuickGrid(BuildContext context) {
    final quickFunds = [
      ('020434', '金信量化C', '混合', const Color(0xFF4CAF50), Icons.auto_graph),
      ('512070', '保险ETF', 'ETF', const Color(0xFF2196F3), Icons.shield),
      ('562360', '机器人ETF', 'ETF', const Color(0xFF9C27B0), Icons.smart_toy),
      ('513100', '纳指ETF', 'QDII', const Color(0xFFFF9800), Icons.public),
      ('510300', '沪深300ETF', '宽基', const Color(0xFFE91E63), Icons.bar_chart),
      ('515070', 'AI智能ETF', 'ETF', const Color(0xFF00BCD4), Icons.precision_manufacturing),
      ('515790', '光伏ETF', 'ETF', const Color(0xFFFF5722), Icons.sunny),
      ('515220', '煤炭ETF', 'ETF', const Color(0xFF795548), Icons.fireplace),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 2.8, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: quickFunds.length,
      itemBuilder: (ctx, i) {
        final f = quickFunds[i];
        return Material(
          borderRadius: BorderRadius.circular(14),
          elevation: 1.5,
          shadowColor: f.$4.withValues(alpha: 0.25),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _search(f.$1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: f.$4.withValues(alpha: 0.15)),
                gradient: LinearGradient(
                  colors: [f.$4.withValues(alpha: 0.1), f.$4.withValues(alpha: 0.02)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 32,
                    decoration: BoxDecoration(color: f.$4, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(f.$5, size: 11, color: f.$4),
                            const SizedBox(width: 4),
                            Text(f.$2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(f.$1, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: f.$4.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(f.$3, style: TextStyle(fontSize: 9, color: f.$4, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 14, color: f.$4.withValues(alpha: 0.4)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '基金分析器',
      applicationVersion: '1.0.1',
      children: [
        const Text('数据来源：东方财富 + 新浪财经\n技术指标：MA10/MA60/CCI/RSI\n仅供学习参考，不构成投资建议'),
      ],
    );
  }
}
