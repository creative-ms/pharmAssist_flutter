// lib/screens/dashboard_screen.dart - ENHANCED VERSION
import 'package:flutter/material.dart';
import '../core/services/simplified_sync_service.dart';
import '../core/database/database_service.dart';
import '../models/daily_stats.dart';
import '../widgets/stats_card.dart';
import '../widgets/loading_widget.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isSyncing = false;

  // Local data from SQLite
  DailyStats? _todayStats;
  List<DailyStats> _weekStats = [];
  List<DailyStats> _monthStats = [];
  int _localRecordCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  Future<void> _initializeAndLoadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Initialize sync service
      await SimplifiedSyncService.instance.initialize();

      // Load local data
      await _loadLocalData();

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocalData() async {
    try {
      print('[Dashboard] Loading local data from SQLite...');

      final db = DatabaseService.instance;

      // Get today's stats
      _todayStats = await db.getTodayStats();
      print('[Dashboard] Today stats: ${_todayStats?.totalRevenue ?? 0}');

      // Get week stats (last 7 days)
      _weekStats = await db.getLastNDaysStats(7);
      print('[Dashboard] Week stats count: ${_weekStats.length}');

      // Get month stats (last 30 days)
      _monthStats = await db.getLastNDaysStats(30);
      print('[Dashboard] Month stats count: ${_monthStats.length}');

      // Get total record count
      _localRecordCount = await db.getStatsCount();
      print('[Dashboard] Total local records: $_localRecordCount');

      // Debug: Print actual data
      if (_todayStats != null) {
        print('[Dashboard] Today\'s data: Revenue=${_todayStats!.totalRevenue}, Sales=${_todayStats!.totalSales}, Profit=${_todayStats!.totalProfit}');
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('[Dashboard] Error loading local data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _performSync() async {
    setState(() => _isSyncing = true);

    try {
      print('[Dashboard] Starting manual sync...');
      final result = await SimplifiedSyncService.instance.performSync();

      if (result.success) {
        print('[Dashboard] Sync successful, reloading data...');
        await _loadLocalData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.message}'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('[Dashboard] Sync failed: ${result.message}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ ${result.message}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('[Dashboard] Sync error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Sync error: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  /// Format sync time for display
  String _formatSyncTime(DateTime syncTime) {
    return Formatters.formatRelativeTime(syncTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PharmAssist Dashboard'),
        actions: [
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _performSync,
            tooltip: 'Sync Data',
          ),
          // Debug button to reset sync
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'reset') {
                await SimplifiedSyncService.instance.resetSyncState();
                await DatabaseService.instance.clearAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('🔄 Sync state reset')),
                );
                _initializeAndLoadData();
              } else if (value == 'debug') {
                _showDebugInfo();
              } else if (value == 'force_sync') {
                await SimplifiedSyncService.instance.performSync(force: true);
                _loadLocalData();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'debug', child: Text('Debug Info')),
              PopupMenuItem(value: 'force_sync', child: Text('Force Full Sync')),
              PopupMenuItem(value: 'reset', child: Text('Reset Sync')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLocalData,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading dashboard data...');
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataInfo(),
          const SizedBox(height: 20),
          _buildPeriodSection("Today's Performance", _todayStats != null ? [_todayStats!] : []),
          const SizedBox(height: 24),
          _buildPeriodSection("This Week's Performance (${_weekStats.length} days)", _weekStats),
          const SizedBox(height: 24),
          _buildPeriodSection("This Month's Performance (${_monthStats.length} days)", _monthStats),
        ],
      ),
    );
  }

  Widget _buildDataInfo() {
    final hasLocalData = _localRecordCount > 0;
    final lastSyncTime = SimplifiedSyncService.instance.lastSyncTime;

    return Card(
      color: hasLocalData ? Colors.green.shade50 : Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLocalData ? Icons.storage : Icons.warning,
                  color: hasLocalData ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocalData ? 'Local Data Available' : 'No Local Data',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasLocalData ? Colors.green.shade700 : Colors.orange.shade700,
                        ),
                      ),
                      Text(
                        'Local records: $_localRecordCount',
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (lastSyncTime != null)
                        Text(
                          'Last sync: ${_formatSyncTime(lastSyncTime)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                if (_isSyncing)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: _performSync,
                    child: const Text('SYNC'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSection(String title, List<DailyStats> statsList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (statsList.isNotEmpty) ...[
          Text(
            '${statsList.length} records available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildComprehensiveStatsGrid(_aggregateStats(statsList)),
        ] else ...[
          const SizedBox(height: 16),
          _buildNoDataCard(),
        ],
      ],
    );
  }

  /// Aggregate stats from list
  Map<String, dynamic> _aggregateStats(List<DailyStats> statsList) {
    if (statsList.isEmpty) {
      return {
        'totalRevenue': 0.0,
        'totalProfit': 0.0,
        'netCashFlow': 0.0,
        'cashInflow': 0.0,
        'cashOutflow': 0.0,
        'totalSales': 0,
        'itemsSold': 0,
        'averageSale': 0.0,
        'dueByCustomers': 0.0,
        'payableToSuppliers': 0.0,
        'creditWithSuppliers': 0.0,
        'customerStoreCredit': 0.0,
        'totalPurchases': 0.0,
        'customerRefunds': 0.0,
        'supplierReturns': 0.0,
      };
    }

    double totalRevenue = 0;
    double totalProfit = 0;
    double netCashFlow = 0;
    double cashInflow = 0;
    double cashOutflow = 0;
    int totalSales = 0;
    int itemsSold = 0;
    double dueByCustomers = 0;
    double payableToSuppliers = 0;
    double creditWithSuppliers = 0;
    double customerStoreCredit = 0;
    double totalPurchases = 0;
    double customerRefunds = 0;
    double supplierReturns = 0;

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

    return {
      'totalRevenue': totalRevenue,
      'totalProfit': totalProfit,
      'netCashFlow': netCashFlow,
      'cashInflow': cashInflow,
      'cashOutflow': cashOutflow,
      'totalSales': totalSales,
      'itemsSold': itemsSold,
      'averageSale': totalSales > 0 ? totalRevenue / totalSales : 0.0,
      'dueByCustomers': dueByCustomers,
      'payableToSuppliers': payableToSuppliers,
      'creditWithSuppliers': creditWithSuppliers,
      'customerStoreCredit': customerStoreCredit,
      'totalPurchases': totalPurchases,
      'customerRefunds': customerRefunds,
      'supplierReturns': supplierReturns,
    };
  }

  Widget _buildComprehensiveStatsGrid(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Primary Revenue & Profit Metrics
        _buildSectionHeader('Revenue & Profitability'),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Total Revenue',
                value: stats['totalRevenue'],
                type: StatsCardType.currency,
                color: AppTheme.primaryColor,
                icon: Icons.trending_up,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Total Profit',
                value: stats['totalProfit'],
                type: StatsCardType.currency,
                color: Colors.green,
                icon: Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Average Sale',
                value: stats['averageSale'],
                type: StatsCardType.currency,
                color: Colors.teal,
                icon: Icons.receipt,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Profit Margin',
                value: stats['totalRevenue'] > 0 ? (stats['totalProfit'] / stats['totalRevenue']) * 100 : 0.0,
                type: StatsCardType.percentage,
                color: Colors.purple,
                icon: Icons.percent,
              ),
            ),
          ],
        ),

        // Sales & Inventory Metrics
        _buildSectionHeader('Sales & Inventory'),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Total Sales',
                value: stats['totalSales'].toDouble(),
                type: StatsCardType.number,
                color: Colors.orange,
                icon: Icons.shopping_cart,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Items Sold',
                value: stats['itemsSold'].toDouble(),
                type: StatsCardType.number,
                color: Colors.indigo,
                icon: Icons.inventory,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Total Purchases',
                value: stats['totalPurchases'],
                type: StatsCardType.currency,
                color: Colors.brown,
                icon: Icons.shopping_bag,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Items per Sale',
                value: stats['totalSales'] > 0 ? stats['itemsSold'] / stats['totalSales'] : 0.0,
                type: StatsCardType.decimal,
                color: Colors.cyan,
                icon: Icons.analytics,
              ),
            ),
          ],
        ),

        // Cash Flow Metrics
        _buildSectionHeader('Cash Flow'),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Net Cash Flow',
                value: stats['netCashFlow'],
                type: StatsCardType.currency,
                color: stats['netCashFlow'] >= 0 ? Colors.green : Colors.red,
                icon: stats['netCashFlow'] >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Cash Inflow',
                value: stats['cashInflow'],
                type: StatsCardType.currency,
                color: Colors.green[700]!,
                icon: Icons.input,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Cash Outflow',
                value: stats['cashOutflow'],
                type: StatsCardType.currency,
                color: Colors.red[700]!,
                icon: Icons.output,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Cash Flow Ratio',
                value: stats['cashOutflow'] > 0 ? stats['cashInflow'] / stats['cashOutflow'] : 0.0,
                type: StatsCardType.decimal,
                color: Colors.blue[700]!,
                icon: Icons.balance,
              ),
            ),
          ],
        ),

        // Customer & Supplier Balances
        _buildSectionHeader('Balances & Credits'),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Due by Customers',
                value: stats['dueByCustomers'],
                type: StatsCardType.currency,
                color: Colors.amber[700]!,
                icon: Icons.person,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Customer Credit',
                value: stats['customerStoreCredit'],
                type: StatsCardType.currency,
                color: Colors.lightBlue[700]!,
                icon: Icons.credit_card,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Payable to Suppliers',
                value: stats['payableToSuppliers'],
                type: StatsCardType.currency,
                color: Colors.deepOrange[700]!,
                icon: Icons.business,
              ),
            ),
            Expanded(
              child: StatsCard(
                title: 'Credit with Suppliers',
                value: stats['creditWithSuppliers'],
                type: StatsCardType.currency,
                color: Colors.green[600]!,
                icon: Icons.account_balance,
              ),
            ),
          ],
        ),

        // Returns & Refunds
        if (stats['customerRefunds'] > 0 || stats['supplierReturns'] > 0) ...[
          _buildSectionHeader('Returns & Refunds'),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Customer Refunds',
                  value: stats['customerRefunds'],
                  type: StatsCardType.currency,
                  color: Colors.red[600]!,
                  icon: Icons.undo,
                ),
              ),
              Expanded(
                child: StatsCard(
                  title: 'Supplier Returns',
                  value: stats['supplierReturns'],
                  type: StatsCardType.currency,
                  color: Colors.orange[600]!,
                  icon: Icons.keyboard_return,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for this period',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap SYNC to fetch data from server',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLocalData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDebugInfo() {
    final syncStatus = SimplifiedSyncService.instance.getSyncStatus();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('=== SYNC STATUS ==='),
              Text('Local Records: $_localRecordCount'),
              Text('Is Syncing: ${syncStatus['is_syncing']}'),
              Text('Last Sync: ${syncStatus['last_sync_time'] ?? 'Never'}'),
              Text('Sync Days: ${syncStatus['sync_days']}'),
              SizedBox(height: 16),
              Text('=== DATA SUMMARY ==='),
              Text('Today Stats: ${_todayStats != null ? 'Available' : 'None'}'),
              Text('Week Stats: ${_weekStats.length} records'),
              Text('Month Stats: ${_monthStats.length} records'),
              if (_todayStats != null) ...[
                SizedBox(height: 16),
                Text('=== TODAY\'S DETAILS ==='),
                Text('Date: ${_todayStats!.date}'),
                Text('Revenue: ${_todayStats!.totalRevenue}'),
                Text('Profit: ${_todayStats!.totalProfit}'),
                Text('Sales: ${_todayStats!.totalSales}'),
                Text('Items: ${_todayStats!.itemsSold}'),
                Text('Due by Customers: ${_todayStats!.dueByCustomers}'),
                Text('Payable to Suppliers: ${_todayStats!.payableToSuppliers}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show all records from database
              final allStats = await DatabaseService.instance.getAllStats();
              _showAllRecords(allStats);
            },
            child: Text('Show All Records'),
          ),
        ],
      ),
    );
  }

  void _showAllRecords(List<DailyStats> allStats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('All Database Records'),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: allStats.length,
            itemBuilder: (context, index) {
              final stats = allStats[index];
              return ListTile(
                title: Text('${stats.date} - Revenue: ${Formatters.formatCurrency(stats.totalRevenue)}'),
                subtitle: Text('Sales: ${stats.totalSales}, Items: ${stats.itemsSold}, Profit: ${Formatters.formatCurrency(stats.totalProfit)}'),
                trailing: Text('ID: ${stats.id}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}