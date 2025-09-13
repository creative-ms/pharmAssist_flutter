// lib/widgets/sales_trend_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/daily_stats.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';
import '../core/database/database_service.dart';

enum ChartPeriod { weekly, monthly }

class SalesTrendWidget extends StatefulWidget {
  final List<DailyStats> weekStats;
  final List<DailyStats> monthStats;

  const SalesTrendWidget({
    Key? key,
    required this.weekStats,
    required this.monthStats,
  }) : super(key: key);

  @override
  State<SalesTrendWidget> createState() => _SalesTrendWidgetState();
}

class _SalesTrendWidgetState extends State<SalesTrendWidget> {
  ChartPeriod _selectedPeriod = ChartPeriod.weekly;
  List<DailyStats> _currentData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDataForPeriod();
  }

  @override
  void didUpdateWidget(SalesTrendWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadDataForPeriod();
  }

  Future<void> _loadDataForPeriod() async {
    setState(() => _isLoading = true);

    try {
      List<DailyStats> data = [];

      if (_selectedPeriod == ChartPeriod.weekly) {
        // Load last 7 days from database to ensure fresh data
        data = await DatabaseService.instance.getLastNDaysStats(7);
        if (data.isEmpty && widget.weekStats.isNotEmpty) {
          data = widget.weekStats;
        }
      } else {
        // Load last 30 days from database for monthly view
        data = await DatabaseService.instance.getLastNDaysStats(30);
        if (data.isEmpty && widget.monthStats.isNotEmpty) {
          data = widget.monthStats;
        }
      }

      // Sort data by date ascending for proper chart display
      data.sort((a, b) => a.date.compareTo(b.date));

      setState(() {
        _currentData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('[SalesTrend] Error loading data: $e');
      setState(() {
        _currentData = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingChart();
    }

    if (_currentData.isEmpty) {
      return _buildEmptyChart();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildStatsCards(_currentData),
            const SizedBox(height: 20),
            _buildCombinedChart(_currentData),
            const SizedBox(height: 12),
            _buildLegend(),
            const SizedBox(height: 12),
            _buildSummary(_currentData),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.trending_up, color: Colors.blue.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sales Trend Analysis',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _selectedPeriod == ChartPeriod.weekly
                    ? 'Last 7 days performance'
                    : 'Last 30 days performance',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildPeriodToggle(),
      ],
    );
  }

  Widget _buildPeriodToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton('Weekly', ChartPeriod.weekly),
        const SizedBox(width: 8),
        _buildToggleButton('Monthly', ChartPeriod.monthly),
      ],
    );
  }

  Widget _buildToggleButton(String label, ChartPeriod period) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        if (_selectedPeriod != period) {
          setState(() => _selectedPeriod = period);
          _loadDataForPeriod();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(List<DailyStats> data) {
    final summary = _calculateSummary(data);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Revenue',
            summary['revenue']!,
            Colors.green.shade600,
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Sales',
            summary['sales']!,
            Colors.blue.shade600,
            Icons.bar_chart,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            'Profit',
            summary['profit']!,
            Colors.orange.shade600,
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha:0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedChart(List<DailyStats> data) {
    // Sort data by date
    final sortedData = List<DailyStats>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Prepare data for charts
    final revenueSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];
    final barGroups = <BarChartGroupData>[];

    // Find max values for proper scaling
    double maxRevenue = 0;
    double maxProfit = 0;
    int maxSales = 0;

    for (final stat in sortedData) {
      if (stat.totalRevenue > maxRevenue) maxRevenue = stat.totalRevenue;
      if (stat.totalProfit > maxProfit) maxProfit = stat.totalProfit;
      if (stat.totalSales > maxSales) maxSales = stat.totalSales;
    }

    // Create chart data points
    for (int i = 0; i < sortedData.length; i++) {
      final stat = sortedData[i];

      // Line chart spots for revenue and profit
      revenueSpots.add(FlSpot(i.toDouble(), stat.totalRevenue.abs()));
      profitSpots.add(FlSpot(i.toDouble(), stat.totalProfit.abs()));

      // Bar chart data for sales
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stat.totalSales.toDouble(),
              color: Colors.blue.shade600.withValues(alpha:0.8),
              width: _selectedPeriod == ChartPeriod.weekly ? 16 : 8,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    final chartMaxY = [maxRevenue, maxProfit, maxSales.toDouble()]
        .reduce((a, b) => a > b ? a : b) * 1.2;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Stack(
        children: [
          // Bar Chart Layer (Sales)
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: chartMaxY,
              barGroups: barGroups,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: chartMaxY / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha:0.2),
                  strokeWidth: 0.5,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 0 && index < sortedData.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDate(sortedData[index].date),
                            style: const TextStyle(fontSize: 9, color: Colors.grey),
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    getTitlesWidget: (value, meta) => Text(
                      Formatters.formatCompactCurrency(value),
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
            ),
          ),
          // Line Chart Layer (Revenue & Profit with area fill)
          LineChart(
            LineChartData(
              minY: 0,
              maxY: chartMaxY,
              gridData: FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Revenue line with area
                LineChartBarData(
                  spots: revenueSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: Colors.green.shade600,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: Colors.green.shade600,
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.green.withValues(alpha:0.3),
                        Colors.green.withValues(alpha:0.1),
                        Colors.green.withValues(alpha:0.05),
                      ],
                    ),
                  ),
                ),
                // Profit line with area
                LineChartBarData(
                  spots: profitSpots,
                  isCurved: true,
                  curveSmoothness: 0.35,
                  color: Colors.orange.shade600,
                  barWidth: 2.5,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.orange.shade600,
                      strokeColor: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.orange.withValues(alpha:0.2),
                        Colors.orange.withValues(alpha:0.1),
                        Colors.orange.withValues(alpha:0.05),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final cleanDateStr = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDateStr);

      if (_selectedPeriod == ChartPeriod.weekly) {
        return '${date.day}/${date.month}';
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('Revenue', Colors.green.shade600, true),
        const SizedBox(width: 16),
        _buildLegendItem('Sales', Colors.blue.shade600, false),
        const SizedBox(width: 16),
        _buildLegendItem('Profit', Colors.orange.shade600, true),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isLine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: isLine ? 3 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isLine ? 2 : 1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(List<DailyStats> data) {
    final totalRevenue = data.fold(0.0, (sum, stat) => sum + stat.totalRevenue);
    final totalSales = data.fold(0, (sum, stat) => sum + stat.totalSales);
    final totalProfit = data.fold(0.0, (sum, stat) => sum + stat.totalProfit);
    final avgRevenue = data.isNotEmpty ? totalRevenue / data.length : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Revenue', Formatters.formatCompactCurrency(totalRevenue.abs())),
          _buildSummaryItem('Total Sales', totalSales.toString()),
          _buildSummaryItem('Avg/Day', Formatters.formatCompactCurrency(avgRevenue.abs())),
          _buildSummaryItem('Total Profit', Formatters.formatCompactCurrency(totalProfit.abs())),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Map<String, String> _calculateSummary(List<DailyStats> data) {
    if (data.isEmpty) {
      return {
        'revenue': 'PKR 0',
        'profit': 'PKR 0',
        'sales': '0',
      };
    }

    final totalRevenue = data.fold(0.0, (sum, stat) => sum + stat.totalRevenue);
    final totalProfit = data.fold(0.0, (sum, stat) => sum + stat.totalProfit);
    final totalSales = data.fold(0, (sum, stat) => sum + stat.totalSales);

    return {
      'revenue': Formatters.formatCompactCurrency(totalRevenue.abs()),
      'profit': Formatters.formatCompactCurrency(totalProfit.abs()),
      'sales': totalSales.toString(),
    };
  }

  Widget _buildLoadingChart() {
    return Card(
      elevation: 2,
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading chart data...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Card(
      elevation: 2,
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No chart data available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync data to view sales trends',
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