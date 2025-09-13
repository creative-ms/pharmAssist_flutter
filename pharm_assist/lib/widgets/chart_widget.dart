// lib/widgets/chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/dashboard_provider.dart';
import '../core/theme/app_theme.dart';
import '../utils/formatters.dart';

class ChartWidget extends StatelessWidget {
  final List<ChartData> data;
  final String title;
  final ChartType type;
  final Color? color;

  const ChartWidget({
    Key? key,
    required this.data,
    required this.title,
    this.type = ChartType.line,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return _buildEmptyChart(theme);
    }

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: type == ChartType.line
                  ? _buildLineChart()
                  : _buildBarChart(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChart(ThemeData theme) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Container(
        height: 250,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart,
              size: 48,
              color: AppTheme.tertiaryTextColor,
            ),
            SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              'No data available',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    final spots = data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                Formatters.formatCompactCurrency(value),
                style: TextStyle(fontSize: 10, color: AppTheme.secondaryTextColor),
              ),
              reservedSize: 50,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: TextStyle(fontSize: 10, color: AppTheme.secondaryTextColor),
                    ),
                  );
                }
                return Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color ?? AppTheme.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                radius: 4,
                color: color ?? AppTheme.primaryColor,
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: (color ?? AppTheme.primaryColor).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final barGroups = data.asMap().entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: entry.value.value,
            color: color ?? AppTheme.primaryColor,
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.isEmpty ? 100 : data.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2,
        barGroups: barGroups,
        gridData: FlGridData(show: true, drawHorizontalLine: true, drawVerticalLine: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text(
                Formatters.formatCompactCurrency(value),
                style: TextStyle(fontSize: 10, color: AppTheme.secondaryTextColor),
              ),
              reservedSize: 50,
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.length) {
                  return Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      data[index].label,
                      style: TextStyle(fontSize: 10, color: AppTheme.secondaryTextColor),
                    ),
                  );
                }
                return Text('');
              },
              reservedSize: 30,
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

enum ChartType {
  line,
  bar,
}