// lib/core/database/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/daily_stats.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  static Database? _database;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pharmassist_dashboard.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    // Create daily_stats table
    await db.execute('''
      CREATE TABLE daily_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        store_id TEXT,
        store_name TEXT,
        hour TEXT,
        total_revenue REAL DEFAULT 0,
        total_profit REAL DEFAULT 0,
        net_cash_flow REAL DEFAULT 0,
        cash_inflow REAL DEFAULT 0,
        cash_outflow REAL DEFAULT 0,
        total_sales INTEGER DEFAULT 0,
        items_sold INTEGER DEFAULT 0,
        due_by_customers REAL DEFAULT 0,
        payable_to_suppliers REAL DEFAULT 0,
        credit_with_suppliers REAL DEFAULT 0,
        customer_store_credit REAL DEFAULT 0,
        total_purchases REAL DEFAULT 0,
        average_sale REAL DEFAULT 0,
        customer_refunds REAL DEFAULT 0,
        supplier_returns REAL DEFAULT 0,
        created_at TEXT,
        updated_at TEXT,
        UNIQUE(date, store_id)
      )
    ''');

    // Create sync_logs table
    await db.execute('''
      CREATE TABLE sync_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sync_type TEXT NOT NULL,
        status TEXT NOT NULL,
        records_synced INTEGER DEFAULT 0,
        error_message TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_daily_stats_date ON daily_stats(date)');
    await db.execute('CREATE INDEX idx_daily_stats_store ON daily_stats(store_id)');
    await db.execute('CREATE INDEX idx_sync_logs_date ON sync_logs(synced_at)');

    print('[DB] Database created successfully');
  }

  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here if needed
    print('[DB] Database upgraded from version $oldVersion to $newVersion');
  }

  /// Initialize database
  Future<void> initialize() async {
    await database;
    print('[DB] Database initialized');
  }

  /// Insert or update daily stats
  Future<void> insertDailyStats(DailyStats stats) async {
    final db = await database;

    try {
      await db.insert(
        'daily_stats',
        stats.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('[DB] Saved stats for ${stats.date}: Revenue=${stats.totalRevenue}');
    } catch (e) {
      print('[DB] Error inserting daily stats: $e');
      rethrow;
    }
  }

  /// Get stats for a specific date range
  Future<List<DailyStats>> getStatsForDateRange(DateTime startDate, DateTime endDate) async {
    final db = await database;

    final startDateStr = startDate.toIso8601String().split('T')[0];
    final endDateStr = endDate.toIso8601String().split('T')[0];

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'daily_stats',
        where: 'date >= ? AND date <= ?',
        whereArgs: [startDateStr, endDateStr],
        orderBy: 'date DESC',
      );

      return maps.map((map) => DailyStats.fromDatabaseMap(map)).toList();
    } catch (e) {
      print('[DB] Error getting stats for date range: $e');
      return [];
    }
  }

  /// Get today's stats
  Future<DailyStats?> getTodayStats() async {
    final today = DateTime.now();
    final todayStr = today.toIso8601String().split('T')[0];

    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'daily_stats',
        where: 'date LIKE ?',
        whereArgs: ['$todayStr%'],
        limit: 1,
      );

      if (maps.isNotEmpty) {
        return DailyStats.fromDatabaseMap(maps.first);
      }
      return null;
    } catch (e) {
      print('[DB] Error getting today stats: $e');
      return null;
    }
  }

  /// Get last N days stats
  Future<List<DailyStats>> getLastNDaysStats(int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));
    final startDateStr = startDate.toIso8601String().split('T')[0];

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'daily_stats',
        where: 'date >= ?',
        whereArgs: [startDateStr],
        orderBy: 'date DESC',
        limit: days,
      );

      return maps.map((map) => DailyStats.fromDatabaseMap(map)).toList();
    } catch (e) {
      print('[DB] Error getting last N days stats: $e');
      return [];
    }
  }

  /// Get total stats count
  Future<int> getStatsCount() async {
    final db = await database;

    try {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM daily_stats');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('[DB] Error getting stats count: $e');
      return 0;
    }
  }

  /// Clear all data (for fresh sync)
  Future<void> clearAllData() async {
    final db = await database;

    try {
      await db.delete('daily_stats');
      print('[DB] Cleared all daily stats data');
    } catch (e) {
      print('[DB] Error clearing data: $e');
      rethrow;
    }
  }

  /// Insert sync log
  Future<void> insertSyncLog(SyncLog syncLog) async {
    final db = await database;

    try {
      await db.insert(
        'sync_logs',
        syncLog.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('[DB] Error inserting sync log: $e');
      rethrow;
    }
  }

  /// Get recent sync logs
  Future<List<SyncLog>> getRecentSyncLogs({int limit = 10}) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'sync_logs',
        orderBy: 'synced_at DESC',
        limit: limit,
      );

      return maps.map((map) => SyncLog.fromDatabaseMap(map)).toList();
    } catch (e) {
      print('[DB] Error getting sync logs: $e');
      return [];
    }
  }

  /// Debug: Get all stats (for troubleshooting)
  Future<List<DailyStats>> getAllStats() async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'daily_stats',
        orderBy: 'date DESC',
      );

      print('[DB] Found ${maps.length} total stats records');
      for (final map in maps.take(5)) {
        print('[DB] Sample record: ${map['date']} - Revenue: ${map['total_revenue']}');
      }

      return maps.map((map) => DailyStats.fromDatabaseMap(map)).toList();
    } catch (e) {
      print('[DB] Error getting all stats: $e');
      return [];
    }
  }

  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
      print('[DB] Database closed');
    }
  }
}

// SyncLog class definition (you'll need to add this to your models)
class SyncLog {
  final int? id;
  final String syncType;
  final String status;
  final int recordsSynced;
  final String? errorMessage;
  final DateTime syncedAt;

  SyncLog({
    this.id,
    required this.syncType,
    required this.status,
    required this.recordsSynced,
    this.errorMessage,
    required this.syncedAt,
  });

  Map<String, dynamic> toDatabaseMap() {
    return {
      'sync_type': syncType,
      'status': status,
      'records_synced': recordsSynced,
      'error_message': errorMessage,
      'synced_at': syncedAt.toIso8601String(),
    };
  }

  static SyncLog fromDatabaseMap(Map<String, dynamic> map) {
    return SyncLog(
      id: map['id'],
      syncType: map['sync_type'],
      status: map['status'],
      recordsSynced: map['records_synced'] ?? 0,
      errorMessage: map['error_message'],
      syncedAt: DateTime.parse(map['synced_at']),
    );
  }
}