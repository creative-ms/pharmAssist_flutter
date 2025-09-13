// lib/core/services/simplified_sync_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_service.dart';
import '../../models/daily_stats.dart';

class SimplifiedSyncService {
  static final SimplifiedSyncService instance = SimplifiedSyncService._internal();

  // Configuration
  static const String baseURL = 'http://13.51.161.166:5984';
  static const String username = 'admin';
  static const String password = 'sufferingofinsanity';
  static const String dashboardDB = 'dashboard_summaries';

  // Sync preferences
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncInitializedKey = 'sync_initialized';

  late final Dio _dio;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  SimplifiedSyncService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
    ));

    _loadLastSyncTime();
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Initialize sync service
  Future<void> initialize() async {
    await _loadLastSyncTime();

    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_syncInitializedKey) ?? false;

    if (!isInitialized) {
      print('[Sync] First time initialization - performing full sync');
      await performSync(force: true);
      await prefs.setBool(_syncInitializedKey, true);
    } else {
      print('[Sync] Already initialized, last sync: $_lastSyncTime');
    }
  }

  /// Main sync method
  Future<SyncResult> performSync({bool force = false}) async {
    if (_isSyncing && !force) {
      return SyncResult(
        success: false,
        message: 'Sync already in progress',
        syncType: SyncType.incremental,
      );
    }

    _isSyncing = true;
    print('[Sync] Starting sync operation...');

    try {
      // Check connectivity
      if (!await _checkConnectivity()) {
        throw Exception('No internet connection');
      }

      // Test CouchDB connection
      if (!await _testConnection()) {
        throw Exception('Cannot connect to CouchDB');
      }

      // Determine how much data to sync
      final syncDays = _determineSyncDays();
      print('[Sync] Syncing last $syncDays days of data');

      // Fetch documents from CouchDB
      final documents = await _fetchRecentDocuments(syncDays);
      print('[Sync] Fetched ${documents.length} documents from CouchDB');

      if (documents.isEmpty) {
        await _updateLastSyncTime();
        return SyncResult(
          success: true,
          message: 'No new data found',
          syncType: SyncType.incremental,
        );
      }

      // Convert to DailyStats and save to SQLite
      final statsList = <DailyStats>[];
      for (final doc in documents) {
        try {
          final stats = DailyStats.fromCouchDB(doc);
          statsList.add(stats);
          print('[Sync] Parsed stats for ${stats.date}: Revenue=${stats.totalRevenue}');
        } catch (e) {
          print('[Sync] Error parsing document ${doc['_id']}: $e');
        }
      }

      // Save to SQLite
      int saved = 0;
      for (final stats in statsList) {
        try {
          await DatabaseService.instance.insertDailyStats(stats);
          saved++;
        } catch (e) {
          print('[Sync] Error saving stats: $e');
        }
      }

      await _updateLastSyncTime();

      print('[Sync] Sync completed: $saved records saved');
      return SyncResult(
        success: true,
        message: 'Synced $saved records successfully',
        recordsSynced: saved,
        syncType: saved == documents.length ? SyncType.full : SyncType.incremental,
      );

    } catch (e) {
      print('[Sync] Sync failed: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        error: e.toString(),
        syncType: SyncType.incremental,
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Fetch recent documents from CouchDB
  Future<List<Map<String, dynamic>>> _fetchRecentDocuments(int days) async {
    try {
      // Calculate the start date
      final startDate = DateTime.now().subtract(Duration(days: days));
      final startDateStr = _formatDate(startDate);

      print('[Sync] Fetching documents since: $startDateStr');

      // Use _all_docs with include_docs=true to get all documents
      final response = await _dio.get(
        '/$dashboardDB/_all_docs',
        queryParameters: {
          'include_docs': true,
          'startkey': json.encode('summary-'),
          'endkey': json.encode('summary-\ufff0'),
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch documents: ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final rows = data['rows'] as List<dynamic>;

      // Filter documents by date and extract docs
      final documents = <Map<String, dynamic>>[];
      for (final row in rows) {
        final doc = row['doc'] as Map<String, dynamic>?;
        if (doc != null && !doc.containsKey('_deleted')) {
          // Check if document date is within our sync range
          final docDate = _extractDateFromDoc(doc);
          if (docDate != null && docDate.isAfter(startDate.subtract(Duration(days: 1)))) {
            documents.add(doc);
            print('[Sync] Including document: ${doc['_id']} (date: $docDate)');
          }
        }
      }

      print('[Sync] Filtered to ${documents.length} relevant documents');
      return documents;

    } catch (e) {
      print('[Sync] Error fetching documents: $e');
      rethrow;
    }
  }

  /// Extract date from document
  DateTime? _extractDateFromDoc(Map<String, dynamic> doc) {
    // Try the date field first
    if (doc['date'] != null) {
      try {
        final dateStr = doc['date'].toString();
        if (dateStr.contains('T')) {
          return DateTime.parse(dateStr);
        } else {
          return DateTime.parse('${dateStr}T00:00:00');
        }
      } catch (e) {
        print('[Sync] Error parsing date field: $e');
      }
    }

    // Try extracting from document ID
    final docId = doc['_id'] as String?;
    if (docId != null) {
      try {
        final parts = docId.split('-');
        // Look for YYYY-MM-DD pattern
        for (int i = 0; i < parts.length - 2; i++) {
          if (parts[i].length == 4 &&
              parts[i + 1].length == 2 &&
              parts[i + 2].length == 2) {
            final dateStr = '${parts[i]}-${parts[i + 1]}-${parts[i + 2]}';
            return DateTime.parse('${dateStr}T00:00:00');
          }
        }
      } catch (e) {
        print('[Sync] Error parsing date from ID: $e');
      }
    }

    return null;
  }

  /// Determine how many days of data to sync
  int _determineSyncDays() {
    if (_lastSyncTime == null) {
      // First sync: get last 30 days
      return 30;
    }

    final daysSinceLastSync = DateTime.now().difference(_lastSyncTime!).inDays;

    if (daysSinceLastSync <= 1) {
      // Recent sync: just get today and yesterday
      return 2;
    } else if (daysSinceLastSync <= 7) {
      // Weekly sync: get last week
      return 7;
    } else {
      // Recovery sync: get last 30 days
      return 30;
    }
  }

  /// Check internet connectivity
  Future<bool> _checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  /// Test connection to CouchDB
  Future<bool> _testConnection() async {
    try {
      final response = await _dio.get('/$dashboardDB');
      return response.statusCode == 200;
    } catch (e) {
      print('[Sync] Connection test failed: $e');
      return false;
    }
  }

  /// Load last sync time from preferences
  Future<void> _loadLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      if (lastSyncStr != null) {
        _lastSyncTime = DateTime.parse(lastSyncStr);
        print('[Sync] Loaded last sync time: $_lastSyncTime');
      } else {
        print('[Sync] No previous sync time found');
      }
    } catch (e) {
      print('[Sync] Error loading last sync time: $e');
    }
  }

  /// Update last sync time
  Future<void> _updateLastSyncTime() async {
    try {
      _lastSyncTime = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, _lastSyncTime!.toIso8601String());
      print('[Sync] Updated last sync time: $_lastSyncTime');
    } catch (e) {
      print('[Sync] Error updating last sync time: $e');
    }
  }

  /// Format date for comparison
  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  /// Reset sync state (for troubleshooting)
  Future<void> resetSyncState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey);
      await prefs.remove(_syncInitializedKey);
      _lastSyncTime = null;
      print('[Sync] Sync state reset');
    } catch (e) {
      print('[Sync] Error resetting sync state: $e');
    }
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'is_syncing': _isSyncing,
      'last_sync_time': _lastSyncTime?.toIso8601String(),
      'sync_days': _determineSyncDays(),
    };
  }

  void dispose() {
    _dio.close();
  }
}

// Keep the existing result classes
class SyncResult {
  final bool success;
  final String message;
  final int recordsSynced;
  final int recordsUpdated;
  final String? error;
  final SyncType syncType;

  SyncResult({
    required this.success,
    required this.message,
    this.recordsSynced = 0,
    this.recordsUpdated = 0,
    this.error,
    required this.syncType,
  });
}

enum SyncType { incremental, recovery, full }