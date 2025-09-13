// lib/utils/constants.dart
class Constants {
  // API Configuration
  static const String couchdbBaseUrl = 'http://13.51.161.166:5984';
  static const String couchdbUsername = 'admin';
  static const String couchdbPassword = 'sufferingofinsanity';
  static const String dashboardDatabase = 'dashboard_summaries';

  // Sync Configuration
  static const int syncTimeoutSeconds = 30;
  static const int maxRetries = 3;
  static const int autoSyncIntervalHours = 1;
  static const int dataRetentionDays = 90;
  static const int syncLogRetentionDays = 30;

  // UI Configuration
  static const int defaultChartLimit = 7;
  static const int maxChartDataPoints = 30;
  static const double cardElevation = 2.0;
  static const double cardBorderRadius = 12.0;

  // Animation Durations
  static const int shortAnimationMs = 200;
  static const int mediumAnimationMs = 300;
  static const int longAnimationMs = 500;

  // Colors (complementing theme)
  static const Map<String, int> statusColors = {
    'success': 0xFF4CAF50,
    'error': 0xFFFF3B30,
    'warning': 0xFFFF9500,
    'info': 0xFF007AFF,
    'neutral': 0xFF8E8E93,
  };

  // Chart Colors
  static const List<int> chartColorCodes = [
    0xFF007AFF, // Primary blue
    0xFF34C759, // Green
    0xFFFF9500, // Orange
    0xFFFF3B30, // Red
    0xFF5856D6, // Purple
    0xFFAF52DE, // Pink
    0xFF00C7BE, // Teal
    0xFFFF6482, // Coral
  ];
}