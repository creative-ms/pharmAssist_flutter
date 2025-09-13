// lib/widgets/enhanced_sales_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/daily_stats.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';

class EnhancedSalesChartWidget extends StatefulWidget {
  final List<DailyStats> weekStats;
  final List<DailyStats> monthStats;

  const EnhancedSalesChartWidget({
    Key? key,
    required this.weekStats,
    required this.monthStats,
  }) : super(key: key);

  @override
  State<EnhancedSalesChartWidget> createState() => _EnhancedSalesChartWidgetState();
}

class _EnhancedSalesChartWidgetState extends State<EnhancedSalesChartWidget> {
  String _chartView = 'daily'; // 'daily' or 'monthly'

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildStatsCards(),
        const SizedBox(height: 20),
        _buildMixedChart(),
        const SizedBox(height: 12),
        _buildDataQualityInfo(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildTimeButton('Daily', 'daily'),
              const SizedBox(width: 8),
              _buildTimeButton('Monthly', 'monthly'),
            ],
          ),
        ),
        Text(
          _chartView == 'daily' ? 'Last 14 days' : 'Last 12 months',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeButton(String label, String value) {
    final isActive = _chartView == value;
    return GestureDetector(
      onTap: () => setState(() => _chartView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: isActive
              ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3))
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final data = _chartView == 'daily' ? widget.weekStats : widget.monthStats;
    final summary = _calculateSummary(data);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Period Revenue',
            summary['revenue']!,
            Colors.green.shade600,
            Icons.attach_money,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Period Profit',
            summary['profit']!,
            Colors.orange.shade600,
            Icons.trending_up,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Period Sales',
            summary['sales']!,
            Colors.blue.shade600,
            Icons.bar_chart,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMixedChart() {
    final data = _chartView == 'daily' ? widget.weekStats : widget.monthStats;

    if (data.isEmpty) {
      return _buildEmptyChart();
    }

    // Sort and prepare data
    final sortedData = List<DailyStats>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedData.length < 2) {
      return _buildEmptyChart();
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: _buildCombinedChart(sortedData),
    );
  }

  Widget _buildCombinedChart(List<DailyStats> data) {
    // Prepare bar chart data (Sales)
    final barGroups = <BarChartGroupData>[];
    final revenueSpots = <FlSpot>[];
    final profitSpots = <FlSpot>[];

    // Find max values for scaling
    double maxRevenue = 0;
    double maxProfit = 0;
    int maxSales = 0;

    for (int i = 0; i < data.length; i++) {
      final stat = data[i];
      if (stat.totalRevenue > maxRevenue) maxRevenue = stat.totalRevenue;
      if (stat.totalProfit > maxProfit) maxProfit = stat.totalProfit;
      if (stat.totalSales > maxSales) maxSales = stat.totalSales;
    }

    // Create chart data
    for (int i = 0; i < data.length; i++) {
      final stat = data[i];

      // Bar data for sales
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: stat.totalSales.toDouble(),
              color: Colors.blue.shade600.withOpacity(0.8),
              width: 12,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
          ],
        ),
      );

      // Line data for revenue and profit (scaled to match bar chart)
      final revenueScaled = maxSales > 0 ? (stat.totalRevenue / maxRevenue) * maxSales : 0.0;
      final profitScaled = maxSales > 0 ? (stat.totalProfit / maxProfit) * maxSales : 0.0;

      revenueSpots.add(FlSpot(i.toDouble(), revenueScaled));
      profitSpots.add(FlSpot(i.toDouble(), profitScaled));
    }

    return Stack(
      children: [
        // Bar Chart for Sales
        BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxSales.toDouble() * 1.2,
            barGroups: barGroups,
            gridData: FlGridData(
              show: true,
              drawHorizontalLine: true,
              drawVerticalLine: false,
              horizontalInterval: maxSales / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                axisNameWidget: const Text(
                  'Sales Count',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (value, meta) {
                    // Convert back from scaled value to original revenue value
                    final originalValue = maxSales > 0 ? (value / maxSales) * maxRevenue : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        Formatters.formatCompactCurrency(originalValue),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
                axisNameWidget: const Text(
                  'Revenue (PKR)',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < data.length) {
                      try {
                        final dateStr = data[index].date.split('T')[0];
                        final date = DateTime.parse(dateStr);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      } catch (e) {
                        return const Text('');
                      }
                    }
                    return const Text('');
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
          ),
        ),
        // Line Chart for Revenue and Profit (overlaid)
        LineChart(
          LineChartData(
            minY: 0,
            maxY: maxSales.toDouble() * 1.2,
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // Revenue Line
              LineChartBarData(
                spots: revenueSpots,
                isCurved: true,
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
                  color: Colors.green.withOpacity(0.1),
                ),
              ),
              // Profit Line
              LineChartBarData(
                spots: profitSpots,
                isCurved: true,
                color: Colors.orange.shade600,
                barWidth: 2,
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
              ),
            ],
          ),
        ),
        // Custom Legend
        Positioned(
          top: 10,
          right: 10,
          child: _buildChartLegend(),
        ),
      ],
    );
  }

  Widget _buildChartLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLegendItem('Revenue', Colors.green.shade600, true),
          const SizedBox(width: 12),
          _buildLegendItem('Sales', Colors.blue.shade600, false),
          const SizedBox(width: 12),
          _buildLegendItem('Profit', Colors.orange.shade600, true),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isLine) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: isLine ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isLine ? 1 : 2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDataQualityInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Chart reflects ${_chartView} sales data including returns impact • Last updated: ${DateTime.now().toString().substring(0, 16)}',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sync data to view sales trends',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
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
}