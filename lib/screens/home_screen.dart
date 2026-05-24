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
    final provider = context.read<FundProvider>();
    provider.searchFund(code);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FundDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradient = LinearGradient(
      colors: [const Color(0xFF1A3C6E), const Color(0xFF2B5EA7)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      body: Column(
        children: [
          // 渐变头部
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20, right: 20, bottom: 24,
            ),
            decoration: BoxDecoration(gradient: gradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '基金分析器',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.info_outline, color: Colors.white70),
                      onPressed: () => _showAbout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '输入基金代码，一键获取全量分析数据',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 16),
                // 搜索栏
                _buildSearchBar(context),
              ],
            ),
          ),
          // 内容区
          Expanded(
            child: Consumer<FundProvider>(
              builder: (context, provider, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 最近查询
                      if (provider.recentCodes.isNotEmpty) ...[
                        _buildSectionTitle(Icons.history, '最近查询'),
                        const SizedBox(height: 8),
                        ...provider.recentCodes.take(5).map(
                          (code) => _buildRecentItem(context, code),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // 热门标的
                      _buildSectionTitle(Icons.trending_up, '热门标的'),
                      const SizedBox(height: 12),
                      _buildQuickGrid(context),
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

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 14),
            child: Icon(Icons.search, color: Color(0xFF1A3C6E), size: 22),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '输入基金代码，如 020434',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              style: const TextStyle(fontSize: 15),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
            ),
          ),
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () => _searchController.clear(),
            ),
          Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3C6E), Color(0xFF2B5EA7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => _search(_searchController.text),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    '分析',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A3C6E)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A3C6E),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(BuildContext context, String code) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF1A3C6E).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.history, size: 16, color: Color(0xFF1A3C6E)),
        ),
        title: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text('点击查询', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () => _search(code),
      ),
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    final quickFunds = [
      ('020434', '金信量化C', '混合', const Color(0xFF4CAF50)),
      ('512070', '保险ETF', 'ETF', const Color(0xFF2196F3)),
      ('562360', '机器人ETF', 'ETF', const Color(0xFF9C27B0)),
      ('513100', '纳指ETF', 'QDII', const Color(0xFFFF9800)),
      ('510300', '沪深300ETF', '宽基', const Color(0xFFE91E63)),
      ('515070', 'AI智能ETF', 'ETF', const Color(0xFF00BCD4)),
      ('515790', '光伏ETF', 'ETF', const Color(0xFFFF5722)),
      ('515220', '煤炭ETF', 'ETF', const Color(0xFF795548)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.6,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: quickFunds.length,
      itemBuilder: (ctx, i) {
        final f = quickFunds[i];
        return Material(
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          shadowColor: f.$4.withValues(alpha: 0.3),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _search(f.$1),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [f.$4.withValues(alpha: 0.12), f.$4.withValues(alpha: 0.04)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 28,
                    decoration: BoxDecoration(
                      color: f.$4,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(f.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            Text(f.$1, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: f.$4.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(f.$3, style: TextStyle(fontSize: 9, color: f.$4, fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: f.$4.withValues(alpha: 0.5)),
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
      applicationVersion: '1.0.0',
      applicationLegalese: '数据来源：东方财富 + 新浪财经\n仅供学习参考，不构成投资建议',
    );
  }
}
