// lib/screens/stats_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/daily_stats.dart';
import '../core/database/database_service.dart';
import '../widgets/stats_card.dart';
import '../widgets/chart_widget.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';
import '../providers/dashboard_provider.dart';

class StatsDetailScreen extends StatefulWidget {
  @override
  _StatsDetailScreenState createState() => _StatsDetailScreenState();
}

class _StatsDetailScreenState extends State<StatsDetailScreen> {
  DailyStats? stats;
  List<ChartData> historicalData = [];
  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    stats = arguments?['stats'] as DailyStats?;
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    try {
      final historical = await DatabaseService.instance.getLastNDaysStats(30);
      setState(() {
        historicalData = historical
            .map((stats) => ChartData(
                  date: DateTime.parse(stats.date.split('T')[0]),
                  value: stats.totalRevenue,
                  label: Formatters.formatShortDate(DateTime.parse(stats.date.split('T')[0])),
                ))
            .toList();
        historicalData.sort((a, b) => a.date.compareTo(b.date));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Statistics')),
        body: Center(
          child: Text('No statistics data available'),
        ),
      );
    }

    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Detailed Statistics')),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Detailed Statistics'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistics for',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  Text(
                    Formatters.formatDate(DateTime.parse(stats!.date.split('T')[0])),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),

            // Revenue & Profit Section
            _buildSection('Revenue & Profit', [
              _buildDetailCard('Total Revenue', stats!.totalRevenue, StatsCardType.currency, AppTheme.secondaryColor, Icons.trending_up),
              _buildDetailCard('Total Profit', stats!.totalProfit, StatsCardType.currency, AppTheme.primaryColor, Icons.account_balance_wallet),
              _buildDetailCard('Average Sale', stats!.averageSale, StatsCardType.currency, AppTheme.warningColor, Icons.receipt),
            ]),

            // Cash Flow Section
            _buildSection('Cash Flow', [
              _buildDetailCard('Net Cash Flow', stats!.netCashFlow, StatsCardType.currency, 
                stats!.netCashFlow >= 0 ? AppTheme.secondaryColor : AppTheme.errorColor, 
                stats!.netCashFlow >= 0 ? Icons.arrow_upward : Icons.arrow_downward),
              _buildDetailCard('Cash Inflow', stats!.cashInflow, StatsCardType.currency, AppTheme.secondaryColor, Icons.arrow_downward),
              _buildDetailCard('Cash Outflow', stats!.cashOutflow, StatsCardType.currency, AppTheme.errorColor, Icons.arrow_upward),
            ]),

            // Sales & Inventory Section
            _buildSection('Sales & Inventory', [
              _buildDetailCard('Total Sales', stats!.totalSales.toDouble(), StatsCardType.number, Color(0xFF9C27B0), Icons.shopping_cart),
              _buildDetailCard('Items Sold', stats!.itemsSold.toDouble(), StatsCardType.number, Color(0xFF607D8B), Icons.inventory),
              _buildDetailCard('Customer Refunds', stats!.customerRefunds, StatsCardType.currency, AppTheme.errorColor, Icons.undo),
            ]),

            // Balances Section
            _buildSection('Balances', [
              _buildDetailCard('Due by Customers', stats!.dueByCustomers, StatsCardType.currency, Color(0xFFFF5722), Icons.person),
              _buildDetailCard('Payable to Suppliers', stats!.payableToSuppliers, StatsCardType.currency, Color(0xFFE91E63), Icons.business),
              _buildDetailCard('Customer Store Credit', stats!.customerStoreCredit, StatsCardType.currency, Color(0xFF00BCD4), Icons.account_balance),
              _buildDetailCard('Credit with Suppliers', stats!.creditWithSuppliers, StatsCardType.currency, Color(0xFF8BC34A), Icons.credit_card),
            ]),

            // Historical Chart
            if (historicalData.isNotEmpty)
              ChartWidget(
                data: historicalData,
                title: '30-Day Revenue Trend',
                type: ChartType.line,
                color: AppTheme.primaryColor,
              ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> cards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...cards,
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailCard(String title, double value, StatsCardType type, Color color, IconData icon) {
    return StatsCard(
      title: title,
      value: value,
      type: type,
      color: color,
      icon: icon,
    );
  }
}