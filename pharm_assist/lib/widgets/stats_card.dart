// lib/widgets/stats_card.dart
import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import '../core/theme/app_theme.dart';

class StatsCard extends StatelessWidget {
  final String title;
  final double value;
  final StatsCardType type;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final String? trend;

  const StatsCard({
    Key? key,
    required this.title,
    required this.value,
    this.type = StatsCardType.currency,
    this.subtitle,
    this.onTap,
    this.color,
    this.icon,
    this.trend,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? AppTheme.primaryColor;

    return Card(
      elevation: AppTheme.cardColor == Colors.white ? 2 : 0,
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(
              left: BorderSide(
                color: cardColor,
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      color: cardColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                  if (trend != null) _buildTrendIndicator(theme),
                ],
              ),
              SizedBox(height: 8),
              Text(
                _formatValue(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.tertiaryTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme) {
    IconData trendIcon;
    Color trendColor;

    switch (trend?.toLowerCase()) {
      case 'up':
        trendIcon = Icons.trending_up;
        trendColor = AppTheme.secondaryColor;
        break;
      case 'down':
        trendIcon = Icons.trending_down;
        trendColor = AppTheme.errorColor;
        break;
      default:
        trendIcon = Icons.trending_flat;
        trendColor = AppTheme.secondaryTextColor;
    }

    return Icon(
      trendIcon,
      color: trendColor,
      size: 16,
    );
  }

  String _formatValue() {
    switch (type) {
      case StatsCardType.currency:
        return Formatters.formatCurrency(value);
      case StatsCardType.number:
        return Formatters.formatNumber(value.toInt());
      case StatsCardType.percentage:
        return Formatters.formatPercentage(value);
      case StatsCardType.decimal:
        return Formatters.formatDecimal(value);
    }
  }
}

enum StatsCardType {
  currency,
  number,
  percentage,
  decimal,
}