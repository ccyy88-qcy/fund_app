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
    // 导航到详情页
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FundDetailScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('基金分析器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
        ],
      ),
      body: Consumer<FundProvider>(
        builder: (context, provider, _) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 搜索栏
                _buildSearchBar(context, theme),
                const SizedBox(height: 32),
                
                // 推荐基金
                if (provider.recentCodes.isNotEmpty) ...[
                  _buildSectionTitle('最近查询'),
                  const SizedBox(height: 8),
                  ...provider.recentCodes.take(5).map((code) => _buildRecentItem(context, code)),
                  const SizedBox(height: 24),
                ],
                
                // 快速入口
                _buildSectionTitle('快速查询'),
                const SizedBox(height: 8),
                _buildQuickGrid(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: '输入基金代码（如 020434）',
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
            FilledButton.icon(
              onPressed: () => _search(_searchController.text),
              icon: const Icon(Icons.trending_up, size: 18),
              label: const Text('分析'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildRecentItem(BuildContext context, String code) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.history, size: 18),
        title: Text(code, style: const TextStyle(fontSize: 14)),
        subtitle: Text('查询', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _search(code),
      ),
    );
  }

  Widget _buildQuickGrid(BuildContext context) {
    final quickFunds = [
      ('020434', '金信量化C'),
      ('512070', '保险ETF'),
      ('562360', '机器人ETF'),
      ('513100', '纳指ETF'),
      ('510300', '沪深300ETF'),
      ('515070', 'AI智能ETF'),
      ('515790', '光伏ETF'),
      ('515220', '煤炭ETF'),
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickFunds.map((f) {
        return ActionChip(
          avatar: const Icon(Icons.show_chart, size: 16),
          label: Text('${f.$1} ${f.$2}', style: const TextStyle(fontSize: 12)),
          onPressed: () => _search(f.$1),
        );
      }).toList(),
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
