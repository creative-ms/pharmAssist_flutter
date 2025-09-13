// lib/screens/dashboard_screen.dart - REFACTORED VERSION
import 'package:flutter/material.dart';
import '../core/services/simplified_sync_service.dart';
import '../core/database/database_service.dart';
import '../models/daily_stats.dart';
import '../widgets/loading_widget.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/key_metrics_widget.dart';
import '../widgets/sales_trend_widget.dart';
import '../widgets/detailed_analytics_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  // Loading states
  bool _isLoading = true;
  String? _error;
  bool _isSyncing = false;

  // Data
  DailyStats? _todayStats;
  List<DailyStats> _weekStats = [];
  List<DailyStats> _monthStats = [];
  int _localRecordCount = 0;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _initializeAndLoadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeAndLoadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SimplifiedSyncService.instance.initialize();
      await _loadLocalData();
      _animationController.forward();
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

      _todayStats = await db.getTodayStats();
      _weekStats = await db.getLastNDaysStats(7);
      _monthStats = await db.getLastNDaysStats(30);
      _localRecordCount = await db.getStatsCount();

      print('[Dashboard] Loaded: Today=${_todayStats != null}, Week=${_weekStats.length}, Month=${_monthStats.length}');

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
          _showSnackBar('âœ… ${result.message}', Colors.green);
        }
      } else {
        print('[Dashboard] Sync failed: ${result.message}');
        if (mounted) {
          _showSnackBar('âŒ ${result.message}', Colors.red);
        }
      }
    } catch (e) {
      print('[Dashboard] Sync error: $e');
      if (mounted) {
        _showSnackBar('âŒ Sync error: $e', Colors.red);
      }
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadLocalData,
        child: _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('PharmAssist Dashboard'),
      elevation: 0,
      actions: [
        IconButton(
          icon: _isSyncing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Icon(Icons.sync),
          onPressed: _isSyncing ? null : _performSync,
          tooltip: 'Sync Data',
        ),
        // Debug menu
        PopupMenuButton<String>(
          onSelected: _handleDebugMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'debug',
              child: Text('Debug Info'),
            ),
            const PopupMenuItem(
              value: 'force_sync',
              child: Text('Force Full Sync'),
            ),
            const PopupMenuItem(
              value: 'reset',
              child: Text('Reset Sync'),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleDebugMenuAction(String value) async {
    switch (value) {
      case 'reset':
        await SimplifiedSyncService.instance.resetSyncState();
        await DatabaseService.instance.clearAllData();
        _showSnackBar('ðŸ”„ Sync state reset', Colors.blue);
        _initializeAndLoadData();
        break;
      case 'debug':
        _showDebugInfo();
        break;
      case 'force_sync':
        await SimplifiedSyncService.instance.performSync(force: true);
        _loadLocalData();
        break;
    }
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading dashboard data...');
    }

    if (_error != null) {
      return _buildErrorState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sync Status
            SyncStatusWidget(
              localRecordCount: _localRecordCount,
              lastSyncTime: SimplifiedSyncService.instance.lastSyncTime,
              isSyncing: _isSyncing,
              onSyncPressed: _performSync,
            ),

            const SizedBox(height: 20),

            // Key Metrics
            KeyMetricsWidget(
              todayStats: _todayStats,
            ),

            const SizedBox(height: 20),

            // Sales Trend Chart
            SalesTrendWidget(
              weekStats: _weekStats,
              monthStats: _monthStats,
            ),

            const SizedBox(height: 20),

            // Detailed Analytics
            DetailedAnalyticsWidget(
              todayStats: _todayStats,
              weekStats: _weekStats,
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
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('=== SYNC STATUS ==='),
              Text('Local Records: $_localRecordCount'),
              Text('Is Syncing: ${syncStatus['is_syncing']}'),
              Text('Last Sync: ${syncStatus['last_sync_time'] ?? 'Never'}'),
              Text('Sync Days: ${syncStatus['sync_days']}'),
              const SizedBox(height: 16),
              const Text('=== DATA SUMMARY ==='),
              Text('Today Stats: ${_todayStats != null ? 'Available' : 'None'}'),
              Text('Week Stats: ${_weekStats.length} records'),
              Text('Month Stats: ${_monthStats.length} records'),
              if (_todayStats != null) ...[
                const SizedBox(height: 16),
                const Text('=== TODAY\'S DETAILS ==='),
                Text('Date: ${_todayStats!.date}'),
                Text('Revenue: ${_todayStats!.totalRevenue}'),
                Text('Profit: ${_todayStats!.totalProfit}'),
                Text('Sales: ${_todayStats!.totalSales}'),
                Text('Items: ${_todayStats!.itemsSold}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final allStats = await DatabaseService.instance.getAllStats();
              _showAllRecords(allStats);
            },
            child: const Text('Show All Records'),
          ),
        ],
      ),
    );
  }

  void _showAllRecords(List<DailyStats> allStats) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Database Records'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: allStats.length,
            itemBuilder: (context, index) {
              final stats = allStats[index];
              return ListTile(
                title: Text('${stats.date} - Revenue: ${stats.totalRevenue}'),
                subtitle: Text('Sales: ${stats.totalSales}, Items: ${stats.itemsSold}'),
                trailing: Text('ID: ${stats.id}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}