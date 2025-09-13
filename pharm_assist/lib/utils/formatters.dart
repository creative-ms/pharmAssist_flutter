// lib/utils/formatters.dart
import 'package:intl/intl.dart';

class Formatters {
  static final _currencyFormatter = NumberFormat.currency(
    symbol: 'PKR ',
    decimalDigits: 2,
  );

  static final _numberFormatter = NumberFormat('#,##0');

  static final _compactCurrencyFormatter = NumberFormat.compactCurrency(
    symbol: 'PKR ',
    decimalDigits: 1,
  );

  static final _percentFormatter = NumberFormat.percentPattern();

  static final _dateFormatter = DateFormat('MMM d, yyyy');
  static final _timeFormatter = DateFormat('h:mm a');
  static final _dateTimeFormatter = DateFormat('MMM d, h:mm a');
  static final _shortDateFormatter = DateFormat('M/d');

  // Currency formatting
  static String formatCurrency(double? amount) {
    if (amount == null) return 'PKR 0.00';
    return _currencyFormatter.format(amount);
  }

  static String formatCompactCurrency(double? amount) {
    if (amount == null) return 'PKR 0';
    if (amount.abs() < 1000) return formatCurrency(amount);
    return _compactCurrencyFormatter.format(amount);
  }

  // Number formatting
  static String formatNumber(int? number) {
    if (number == null) return '0';
    return _numberFormatter.format(number);
  }

  static String formatDecimal(double? number, {int decimalPlaces = 1}) {
    if (number == null) return '0';
    return number.toStringAsFixed(decimalPlaces);
  }

  // Percentage formatting
  static String formatPercentage(double? percentage) {
    if (percentage == null) return '0%';
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Date formatting
  static String formatDate(DateTime? date) {
    if (date == null) return '';
    return _dateFormatter.format(date);
  }

  static String formatTime(DateTime? time) {
    if (time == null) return '';
    return _timeFormatter.format(time);
  }

  static String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    return _dateTimeFormatter.format(dateTime);
  }

  static String formatShortDate(DateTime? date) {
    if (date == null) return '';
    return _shortDateFormatter.format(date);
  }

  static String formatRelativeTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Business specific formatters
  static String formatCashFlow(double? amount) {
    if (amount == null) return 'PKR 0.00';
    final formatted = formatCurrency(amount.abs());
    return amount >= 0 ? '+$formatted' : '-$formatted';
  }

  static String formatTrend(String trend) {
    switch (trend.toLowerCase()) {
      case 'up':
        return '↗️ Trending Up';
      case 'down':
        return '↘️ Trending Down';
      case 'neutral':
      default:
        return '➡️ Stable';
    }
  }

  // Color helpers for financial data
  static bool isPositiveValue(double? value) {
    return (value ?? 0) >= 0;
  }

  static String formatChangeIndicator(double? current, double? previous) {
    if (current == null || previous == null || previous == 0) {
      return '';
    }

    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(1)}%';
  }

  // Validation helpers
  static bool isValidAmount(String? text) {
    if (text == null || text.trim().isEmpty) return false;
    final amount = double.tryParse(text.replaceAll(RegExp(r'[^\d.-]'), ''));
    return amount != null && amount >= 0;
  }

  static double? parseAmount(String? text) {
    if (text == null || text.trim().isEmpty) return null;
    return double.tryParse(text.replaceAll(RegExp(r'[^\d.-]'), ''));
  }

  // Pakistani Rupee specific formatting
  static String formatPKR(double? amount) {
    if (amount == null) return 'PKR 0';
    
    // Handle large amounts (lacs and crores)
    if (amount.abs() >= 10000000) { // 1 crore
      return 'PKR ${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount.abs() >= 100000) { // 1 lac
      return 'PKR ${(amount / 100000).toStringAsFixed(2)} Lac';
    } else if (amount.abs() >= 1000) { // thousands
      return 'PKR ${(amount / 1000).toStringAsFixed(1)}K';
    }
    
    return formatCurrency(amount);
  }
}