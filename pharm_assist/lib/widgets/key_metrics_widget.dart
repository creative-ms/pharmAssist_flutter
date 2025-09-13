// lib/widgets/key_metrics_widget.dart
import 'package:flutter/material.dart';
import '../models/daily_stats.dart';
import '../utils/formatters.dart';

class KeyMetricsWidget extends StatelessWidget {
  final DailyStats? todayStats;

  const KeyMetricsWidget({
    Key? key,
    required this.todayStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (todayStats == null) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Today's Key Metrics",
          style: Theme
              .of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                todayStats!.totalRevenue,
                Icons.trending_up,
                Colors.green,
                _formatCurrency,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Profit',
                todayStats!.totalProfit,
                Icons.account_balance_wallet,
                Colors.blue,
                _formatCurrency,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Sales',
                todayStats!.totalSales.toDouble(),
                Icons.shopping_cart,
                Colors.orange,
                _formatNumber,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Cash Flow',
                todayStats!.netCashFlow,
                todayStats!.netCashFlow >= 0 ? Icons.arrow_upward : Icons
                    .arrow_downward,
                todayStats!.netCashFlow >= 0 ? Colors.green : Colors.red,
                _formatCurrency,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title,
      double value,
      IconData icon,
      Color color,
      String Function(double) formatter,) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha:0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha:0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            formatter(value),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.today, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No data for today',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync data to view today\'s metrics',
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    return Formatters.formatCompactCurrency(value);
  }

  String _formatNumber(double value) {
    return Formatters.formatNumber(value.toInt());
  }
}