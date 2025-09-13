// lib/providers/dashboard_provider.dart
import 'package:flutter/foundation.dart';
import '../models/daily_stats.dart';
import '../core/database/database_service.dart';

class ChartData {
  final DateTime date;
  final double value;
  final String label;

  ChartData({
    required this.date,
    required this.value,
    required this.label,
  });
}

class DashboardProvider extends ChangeNotifier {
  DailyStats? _todayStats;
  List<DailyStats> _weeklyStats = [];
  List<DailyStats> _monthlyStats = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  DailyStats? get todayStats => _todayStats;
  List<DailyStats> get weeklyStats => _weeklyStats;
  List<DailyStats> get monthlyStats => _monthlyStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _todayStats != null || _weeklyStats.isNotEmpty;

  // Chart data getters
  List<ChartData> get weeklyRevenueData => _weeklyStats
      .map((stats) => ChartData(
    date: DateTime.parse(stats.date.split('T')[0]),
    value: stats.totalRevenue,
    label: _formatDateForChart(DateTime.parse(stats.date.split('T')[0])),
  ))
      .toList();

  List<ChartData> get weeklyProfitData => _weeklyStats
      .map((stats) => ChartData(
    date: DateTime.parse(stats.date.split('T')[0]),
    value: stats.totalProfit,
    label: _formatDateForChart(DateTime.parse(stats.date.split('T')[0])),
  ))
      .toList();

  List<ChartData> get weeklySalesData => _weeklyStats
      .map((stats) => ChartData(
    date: DateTime.parse(stats.date.split('T')[0]),
    value: stats.totalSales.toDouble(),
    label: _formatDateForChart(DateTime.parse(stats.date.split('T')[0])),
  ))
      .toList();

  String _formatDateForChart(DateTime date) {
    return '${date.month}/${date.day}';
  }

  Future<void> loadDashboardData() async {
    _setLoading(true);
    _setError(null);

    try {
      // Load today's stats
      await _loadTodayStats();

      // Load weekly stats (last 7 days)
      await _loadWeeklyStats();

      // Load monthly stats (last 30 days)
      await _loadMonthlyStats();

    } catch (e) {
      _setError('Failed to load dashboard data: ${e.toString()}');
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadTodayStats() async {
    try {
      _todayStats = await DatabaseService.instance.getTodayStats();
    } catch (e) {
      debugPrint('Error loading today stats: $e');
    }
  }

  Future<void> _loadWeeklyStats() async {
    try {
      _weeklyStats = await DatabaseService.instance.getLastNDaysStats(7);
      _weeklyStats.sort((a, b) => a.date.compareTo(b.date)); // Sort ascending for charts
    } catch (e) {
      debugPrint('Error loading weekly stats: $e');
      _weeklyStats = [];
    }
  }

  Future<void> _loadMonthlyStats() async {
    try {
      _monthlyStats = await DatabaseService.instance.getLastNDaysStats(30);
    } catch (e) {
      debugPrint('Error loading monthly stats: $e');
      _monthlyStats = [];
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Analytics getters
  double get weeklyRevenueTotal => _weeklyStats.fold(0.0, (sum, stats) => sum + stats.totalRevenue);
  double get weeklyProfitTotal => _weeklyStats.fold(0.0, (sum, stats) => sum + stats.totalProfit);
  int get weeklySalesTotal => _weeklyStats.fold(0, (sum, stats) => sum + stats.totalSales);

  double get weeklyAverageRevenue => _weeklyStats.isNotEmpty ? weeklyRevenueTotal / _weeklyStats.length : 0.0;
  double get weeklyAverageProfit => _weeklyStats.isNotEmpty ? weeklyProfitTotal / _weeklyStats.length : 0.0;

  double get profitMargin => weeklyRevenueTotal > 0 ? (weeklyProfitTotal / weeklyRevenueTotal) * 100 : 0.0;

  // Trend analysis
  String get revenueTrend {
    if (_weeklyStats.length < 2) return 'neutral';

    final recent = _weeklyStats.take(_weeklyStats.length ~/ 2).fold(0.0, (sum, stats) => sum + stats.totalRevenue);
    final older = _weeklyStats.skip(_weeklyStats.length ~/ 2).fold(0.0, (sum, stats) => sum + stats.totalRevenue);

    if (recent > older) return 'up';
    if (recent < older) return 'down';
    return 'neutral';
  }

  String get profitTrend {
    if (_weeklyStats.length < 2) return 'neutral';

    final recent = _weeklyStats.take(_weeklyStats.length ~/ 2).fold(0.0, (sum, stats) => sum + stats.totalProfit);
    final older = _weeklyStats.skip(_weeklyStats.length ~/ 2).fold(0.0, (sum, stats) => sum + stats.totalProfit);

    if (recent > older) return 'up';
    if (recent < older) return 'down';
    return 'neutral';
  }

  void clearError() {
    _setError(null);
  }
}