// lib/widgets/detailed_analytics_widget.dart - ENHANCED VERSION
import 'package:flutter/material.dart';
import '../models/daily_stats.dart';
import '../widgets/stats_card.dart';
import '../core/theme/app_theme.dart';
import '../core/database/database_service.dart';

enum AnalyticsDateRange { today, weekly, monthly, custom }

class DetailedAnalyticsWidget extends StatefulWidget {
  final DailyStats? todayStats;
  final List<DailyStats> weekStats;

  const DetailedAnalyticsWidget({
    Key? key,
    required this.todayStats,
    required this.weekStats,
  }) : super(key: key);

  @override
  State<DetailedAnalyticsWidget> createState() => _DetailedAnalyticsWidgetState();
}

class _DetailedAnalyticsWidgetState extends State<DetailedAnalyticsWidget> {
  // Collapsible section states
  bool _isRevenueExpanded = true;
  bool _isCashFlowExpanded = false;
  bool _isSalesExpanded = false;
  bool _isBalancesExpanded = false;
  bool _isReturnsExpanded = false;

  // Date range selection
  AnalyticsDateRange _selectedRange = AnalyticsDateRange.today;
  bool _isLoading = false;
  List<DailyStats> _currentData = [];
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  @override
  void initState() {
    super.initState();
    _loadDataForRange();
  }

  @override
  void didUpdateWidget(DetailedAnalyticsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadDataForRange();
  }

  Future<void> _loadDataForRange() async {
    setState(() {
      _isLoading = true;
    });

    try {
      List<DailyStats> data = [];

      switch (_selectedRange) {
        case AnalyticsDateRange.today:
          if (widget.todayStats != null) {
            data = [widget.todayStats!];
          }
          break;
        case AnalyticsDateRange.weekly:
          data = widget.weekStats.isNotEmpty 
              ? widget.weekStats 
              : await DatabaseService.instance.getLastNDaysStats(7);
          break;
        case AnalyticsDateRange.monthly:
          data = await DatabaseService.instance.getLastNDaysStats(30);
          break;
        case AnalyticsDateRange.custom:
          if (_customStartDate != null && _customEndDate != null) {
            data = await DatabaseService.instance.getStatsForDateRange(
              _customStartDate!, 
              _customEndDate!
            );
          }
          break;
      }

      setState(() {
        _currentData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('[DetailedAnalytics] Error loading data: $e');
      setState(() {
        _currentData = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _selectCustomDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customStartDate = picked.start;
        _customEndDate = picked.end;
        _selectedRange = AnalyticsDateRange.custom;
      });
      await _loadDataForRange();
    }
  }

  // Aggregate stats for multi-day periods
  DailyStats _aggregateStats(List<DailyStats> statsList) {
    if (statsList.isEmpty) {
      return DailyStats(date: DateTime.now().toIso8601String());
    }

    if (statsList.length == 1) {
      return statsList.first;
    }

    // Aggregate multiple days
    double totalRevenue = 0, totalProfit = 0, netCashFlow = 0, cashInflow = 0, cashOutflow = 0;
    int totalSales = 0, itemsSold = 0;
    double dueByCustomers = 0, payableToSuppliers = 0, creditWithSuppliers = 0, customerStoreCredit = 0;
    double totalPurchases = 0, customerRefunds = 0, supplierReturns = 0;

    for (final stats in statsList) {
      totalRevenue += stats.totalRevenue;
      totalProfit += stats.totalProfit;
      netCashFlow += stats.netCashFlow;
      cashInflow += stats.cashInflow;
      cashOutflow += stats.cashOutflow;
      totalSales += stats.totalSales;
      itemsSold += stats.itemsSold;
      dueByCustomers += stats.dueByCustomers;
      payableToSuppliers += stats.payableToSuppliers;
      creditWithSuppliers += stats.creditWithSuppliers;
      customerStoreCredit += stats.customerStoreCredit;
      totalPurchases += stats.totalPurchases;
      customerRefunds += stats.customerRefunds;
      supplierReturns += stats.supplierReturns;
    }

    // For balances, use the most recent values instead of summing
    final mostRecent = statsList.last;

    return DailyStats(
      date: "${statsList.first.date} to ${statsList.last.date}",
      totalRevenue: totalRevenue,
      totalProfit: totalProfit,
      netCashFlow: netCashFlow,
      cashInflow: cashInflow,
      cashOutflow: cashOutflow,
      totalSales: totalSales,
      itemsSold: itemsSold,
      // Use most recent values for balances since these are point-in-time
      dueByCustomers: mostRecent.dueByCustomers,
      payableToSuppliers: mostRecent.payableToSuppliers,
      creditWithSuppliers: mostRecent.creditWithSuppliers,
      customerStoreCredit: mostRecent.customerStoreCredit,
      totalPurchases: totalPurchases,
      averageSale: totalSales > 0 ? totalRevenue / totalSales : 0.0,
      customerRefunds: customerRefunds,
      supplierReturns: supplierReturns,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_currentData.isEmpty) {
      return _buildEmptyState();
    }

    final aggregatedStats = _aggregateStats(_currentData);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),

        // Revenue & Profitability
        _buildCollapsibleSection(
          'Revenue & Profitability',
          Icons.trending_up,
          Colors.green,
          _isRevenueExpanded,
          () => setState(() => _isRevenueExpanded = !_isRevenueExpanded),
          _buildRevenueCards(aggregatedStats),
        ),

        // Cash Flow
        _buildCollapsibleSection(
          'Cash Flow',
          Icons.account_balance,
          Colors.blue,
          _isCashFlowExpanded,
          () => setState(() => _isCashFlowExpanded = !_isCashFlowExpanded),
          _buildCashFlowCards(aggregatedStats),
        ),

        // Sales & Inventory
        _buildCollapsibleSection(
          'Sales & Inventory',
          Icons.shopping_cart,
          Colors.orange,
          _isSalesExpanded,
          () => setState(() => _isSalesExpanded = !_isSalesExpanded),
          _buildSalesCards(aggregatedStats),
        ),

        // Balances & Credits
        _buildCollapsibleSection(
          'Balances & Credits',
          Icons.account_balance_wallet,
          Colors.purple,
          _isBalancesExpanded,
          () => setState(() => _isBalancesExpanded = !_isBalancesExpanded),
          _buildBalanceCards(aggregatedStats),
        ),

        // Returns & Refunds (only show if there are any)
        if (aggregatedStats.customerRefunds > 0 || aggregatedStats.supplierReturns > 0)
          _buildCollapsibleSection(
            'Returns & Refunds',
            Icons.undo,
            Colors.red,
            _isReturnsExpanded,
            () => setState(() => _isReturnsExpanded = !_isReturnsExpanded),
            _buildReturnsCards(aggregatedStats),
          ),

        // Period Summary (for multi-day views)
        if (_currentData.length > 1)
          _buildPeriodSummary(_currentData),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Detailed Analytics",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _getHeaderSubtitle(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildRangeSelector(),
      ],
    );
  }

  String _getHeaderSubtitle() {
    switch (_selectedRange) {
      case AnalyticsDateRange.today:
        return "Today's performance";
      case AnalyticsDateRange.weekly:
        return "Last 7 days aggregated";
      case AnalyticsDateRange.monthly:
        return "Last 30 days aggregated";
      case AnalyticsDateRange.custom:
        if (_customStartDate != null && _customEndDate != null) {
          final days = _customEndDate!.difference(_customStartDate!).inDays + 1;
          return "$days days period";
        }
        return "Custom period";
    }
  }

  Widget _buildRangeSelector() {
    return PopupMenuButton<AnalyticsDateRange>(
      onSelected: (AnalyticsDateRange range) async {
        if (range == AnalyticsDateRange.custom) {
          await _selectCustomDateRange();
        } else {
          setState(() {
            _selectedRange = range;
          });
          await _loadDataForRange();
        }
      },
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor.withValues(alpha:0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getRangeLabel(_selectedRange),
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => [
        _buildMenuItem(AnalyticsDateRange.today, 'Today', Icons.today),
        _buildMenuItem(AnalyticsDateRange.weekly, 'Weekly', Icons.date_range),
        _buildMenuItem(AnalyticsDateRange.monthly, 'Monthly', Icons.calendar_month),
        _buildMenuItem(AnalyticsDateRange.custom, 'Custom', Icons.event_available),
      ],
    );
  }

  PopupMenuItem<AnalyticsDateRange> _buildMenuItem(
    AnalyticsDateRange range, 
    String label, 
    IconData icon
  ) {
    final isSelected = _selectedRange == range;
    return PopupMenuItem<AnalyticsDateRange>(
      value: range,
      child: Row(
        children: [
          Icon(
            icon, 
            size: 16, 
            color: isSelected ? AppTheme.primaryColor : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppTheme.primaryColor : Colors.grey[800],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 16,
              color: AppTheme.primaryColor,
            ),
          ],
        ],
      ),
    );
  }

  String _getRangeLabel(AnalyticsDateRange range) {
    switch (range) {
      case AnalyticsDateRange.today:
        return 'Today';
      case AnalyticsDateRange.weekly:
        return 'Weekly';
      case AnalyticsDateRange.monthly:
        return 'Monthly';
      case AnalyticsDateRange.custom:
        return 'Custom';
    }
  }

  Widget _buildPeriodSummary(List<DailyStats> data) {
    if (data.length <= 1) return Container();

    final days = data.length;
    final totalRevenue = data.fold(0.0, (sum, stat) => sum + stat.totalRevenue);
    final avgRevenue = totalRevenue / days;
    final totalProfit = data.fold(0.0, (sum, stat) => sum + stat.totalProfit);
    final avgProfit = totalProfit / days;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Period Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem('Days', days.toString(), Icons.calendar_today),
                ),
                Expanded(
                  child: _buildSummaryItem('Avg Revenue/Day', 
                    '\$${avgRevenue.toStringAsFixed(0)}', Icons.attach_money),
                ),
                Expanded(
                  child: _buildSummaryItem('Avg Profit/Day', 
                    '\$${avgProfit.toStringAsFixed(0)}', Icons.trending_up),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  List<Widget> _buildRevenueCards(DailyStats stats) {
    return [
      StatsCard(
        title: 'Total Revenue',
        value: stats.totalRevenue,
        type: StatsCardType.currency,
        color: AppTheme.primaryColor,
        icon: Icons.trending_up,
      ),
      StatsCard(
        title: 'Total Profit',
        value: stats.totalProfit,
        type: StatsCardType.currency,
        color: Colors.green,
        icon: Icons.account_balance_wallet,
      ),
      StatsCard(
        title: 'Profit Margin',
        value: stats.totalRevenue > 0
            ? (stats.totalProfit / stats.totalRevenue) * 100
            : 0.0,
        type: StatsCardType.percentage,
        color: Colors.purple,
        icon: Icons.percent,
      ),
    ];
  }

  List<Widget> _buildCashFlowCards(DailyStats stats) {
    return [
      StatsCard(
        title: 'Net Cash Flow',
        value: stats.netCashFlow,
        type: StatsCardType.currency,
        color: stats.netCashFlow >= 0 ? Colors.green : Colors.red,
        icon: stats.netCashFlow >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
      ),
      StatsCard(
        title: 'Cash Inflow',
        value: stats.cashInflow,
        type: StatsCardType.currency,
        color: Colors.green[700]!,
        icon: Icons.input,
      ),
      StatsCard(
        title: 'Cash Outflow',
        value: stats.cashOutflow,
        type: StatsCardType.currency,
        color: Colors.red[700]!,
        icon: Icons.output,
      ),
    ];
  }

  List<Widget> _buildSalesCards(DailyStats stats) {
    return [
      StatsCard(
        title: 'Total Sales',
        value: stats.totalSales.toDouble(),
        type: StatsCardType.number,
        color: Colors.orange,
        icon: Icons.shopping_cart,
      ),
      StatsCard(
        title: 'Items Sold',
        value: stats.itemsSold.toDouble(),
        type: StatsCardType.number,
        color: Colors.indigo,
        icon: Icons.inventory,
      ),
      StatsCard(
        title: 'Average Sale',
        value: stats.averageSale > 0
            ? stats.averageSale
            : (stats.totalSales > 0 ? stats.totalRevenue / stats.totalSales : 0.0),
        type: StatsCardType.currency,
        color: Colors.teal,
        icon: Icons.receipt,
      ),
      StatsCard(
        title: 'Total Purchases',
        value: stats.totalPurchases,
        type: StatsCardType.currency,
        color: Colors.brown,
        icon: Icons.shopping_bag,
      ),
    ];
  }

  List<Widget> _buildBalanceCards(DailyStats stats) {
    return [
      StatsCard(
        title: 'Due by Customers',
        value: stats.dueByCustomers,
        type: StatsCardType.currency,
        color: Colors.amber[700]!,
        icon: Icons.person,
      ),
      StatsCard(
        title: 'Payable to Suppliers',
        value: stats.payableToSuppliers,
        type: StatsCardType.currency,
        color: Colors.deepOrange[700]!,
        icon: Icons.business,
      ),
      StatsCard(
        title: 'Customer Store Credit',
        value: stats.customerStoreCredit,
        type: StatsCardType.currency,
        color: Colors.lightBlue[700]!,
        icon: Icons.credit_card,
      ),
      StatsCard(
        title: 'Credit with Suppliers',
        value: stats.creditWithSuppliers,
        type: StatsCardType.currency,
        color: Colors.green[600]!,
        icon: Icons.account_balance,
      ),
    ];
  }

  List<Widget> _buildReturnsCards(DailyStats stats) {
    final cards = <Widget>[];

    if (stats.customerRefunds > 0) {
      cards.add(
        StatsCard(
          title: 'Customer Refunds',
          value: stats.customerRefunds,
          type: StatsCardType.currency,
          color: Colors.red[600]!,
          icon: Icons.undo,
        ),
      );
    }

    if (stats.supplierReturns > 0) {
      cards.add(
        StatsCard(
          title: 'Supplier Returns',
          value: stats.supplierReturns,
          type: StatsCardType.currency,
          color: Colors.orange[600]!,
          icon: Icons.keyboard_return,
        ),
      );
    }

    return cards;
  }

  Widget _buildCollapsibleSection(
    String title,
    IconData icon,
    Color color,
    bool isExpanded,
    VoidCallback onToggle,
    List<Widget> children,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${children.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: isExpanded ? null : 0,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isExpanded ? 1.0 : 0.0,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: children.map((child) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: child,
                        )).toList(),
                      ),
                    )
                  : Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading analytics data...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.analytics_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No detailed data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync data to view detailed analytics for the selected period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}