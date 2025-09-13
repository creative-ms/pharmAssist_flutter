// lib/core/services/enhanced_couchdb_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/daily_stats.dart';

class AggregatedStats {
  final DateTime startDate, endDate;
  final int recordCount, totalSales, itemsSold;
  final double totalRevenue, totalProfit, netCashFlow, cashInflow, cashOutflow;
  final double dueByCustomers, payableToSuppliers, creditWithSuppliers, customerStoreCredit;
  final double totalPurchases, averageSale, customerRefunds, supplierReturns;

  AggregatedStats({
    required this.startDate,
    required this.endDate,
    required this.recordCount,
    required this.totalRevenue,
    required this.totalProfit,
    required this.netCashFlow,
    required this.cashInflow,
    required this.cashOutflow,
    required this.totalSales,
    required this.itemsSold,
    required this.dueByCustomers,
    required this.payableToSuppliers,
    required this.creditWithSuppliers,
    required this.customerStoreCredit,
    required this.totalPurchases,
    required this.averageSale,
    required this.customerRefunds,
    required this.supplierReturns,
  });

  factory AggregatedStats.empty(DateTime start, DateTime end) => AggregatedStats(
    startDate: start,
    endDate: end,
    recordCount: 0,
    totalRevenue: 0,
    totalProfit: 0,
    netCashFlow: 0,
    cashInflow: 0,
    cashOutflow: 0,
    totalSales: 0,
    itemsSold: 0,
    dueByCustomers: 0,
    payableToSuppliers: 0,
    creditWithSuppliers: 0,
    customerStoreCredit: 0,
    totalPurchases: 0,
    averageSale: 0,
    customerRefunds: 0,
    supplierReturns: 0,
  );
}

class EnhancedCouchDBService {
  static final EnhancedCouchDBService instance = EnhancedCouchDBService._internal();
  late final Dio _dio;
  Dio get dio => _dio;

  // CouchDB Configuration
  static const String baseURL = 'http://13.51.161.166:5984';
  static const String username = 'admin';
  static const String password = 'sufferingofinsanity';
  static const String dashboardDB = 'dashboard_summaries';

  EnhancedCouchDBService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      },
    ));
  }

  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (_) {
      return false;
    }
  }

  Future<bool> testConnection() async {
    try {
      if (!await checkConnectivity()) throw Exception('No internet connection');
      final response = await _dio.get('/$dashboardDB');
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Get document IDs with proper JSON encoding
  Future<List<String>> getDocumentIds({int limit = 100}) async {
    try {
      if (!await checkConnectivity()) throw Exception('No internet connection');

      final response = await _dio.get(
        '/$dashboardDB/_all_docs',
        queryParameters: {
          'startkey': json.encode('summary-'),
          'endkey': json.encode('summary-\ufff0'),
          'descending': true,
          'limit': limit,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rows = data['rows'] as List<dynamic>;
        return rows.map((row) => row['id'] as String).toList();
      }
      throw Exception('Failed to fetch document IDs: ${response.statusMessage}');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Get latest stats with documents
  Future<List<DailyStats>> getLatestStatsWithDocs({int limit = 100}) async {
    try {
      if (!await checkConnectivity()) {
        throw Exception('No internet connection');
      }

      final response = await _dio.get(
        '/$dashboardDB/_all_docs',
        queryParameters: {
          'include_docs': true,
          'limit': limit,
          'descending': true,
        },
      );

      if (response.statusCode == 200) {
        final rows = (response.data['rows'] as List<dynamic>);
        return rows
            .where((row) => row['doc'] != null)
            .map((row) => DailyStats.fromCouchDB(row['doc'] as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Failed to fetch stats: ${response.statusMessage}');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Future<List<DailyStats>> getLatestStats({int limit = 100}) async {
    return getLatestStatsWithDocs(limit: limit);
  }

  Future<List<DailyStats>> getStatsAfterDate(DateTime date) async {
    return getStatsForDateRange(date, DateTime.now());
  }

  /// Get stats for date range
  Future<List<DailyStats>> getStatsForDateRange(DateTime startDate, DateTime endDate) async {
    if (!await checkConnectivity()) {
      throw Exception('No internet connection');
    }

    final response = await _dio.get(
      '/$dashboardDB/_all_docs',
      queryParameters: {
        'include_docs': true,
      },
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final rows = data['rows'] as List<dynamic>;

      final allDocs = rows
          .where((row) => row['doc'] != null && !(row['doc'] as Map).containsKey('_deleted'))
          .map((row) => DailyStats.fromCouchDB(row['doc'] as Map<String, dynamic>))
          .toList();

      // Filter in Dart by timestamp field
      return allDocs.where((doc) {
        final ts = DateTime.tryParse(doc.date ?? '');
        return ts != null && ts.isAfter(startDate) && ts.isBefore(endDate);
      }).toList();
    }

    throw Exception('Failed to fetch stats: ${response.statusMessage}');
  }

  Future<AggregatedStats> getAggregatedStatsForPeriod(DateTime startDate, DateTime endDate) async {
    final stats = await getStatsForDateRange(startDate, endDate);
    return _aggregateStats(stats, startDate, endDate);
  }

  AggregatedStats _aggregateStats(List<DailyStats> statsList, DateTime start, DateTime end) {
    if (statsList.isEmpty) return AggregatedStats.empty(start, end);

    double revenue = 0, profit = 0, netFlow = 0, inflow = 0, outflow = 0;
    int sales = 0, items = 0;
    double dueCust = 0, payableSupp = 0, creditSupp = 0, creditCust = 0;
    double purchases = 0, refunds = 0, returns = 0;

    for (final s in statsList) {
      revenue += s.totalRevenue;
      profit += s.totalProfit;
      netFlow += s.netCashFlow;
      inflow += s.cashInflow;
      outflow += s.cashOutflow;
      sales += s.totalSales;
      items += s.itemsSold;
      dueCust += s.dueByCustomers;
      payableSupp += s.payableToSuppliers;
      creditSupp += s.creditWithSuppliers;
      creditCust += s.customerStoreCredit;
      purchases += s.totalPurchases;
      refunds += s.customerRefunds;
      returns += s.supplierReturns;
    }

    return AggregatedStats(
      startDate: start,
      endDate: end,
      recordCount: statsList.length,
      totalRevenue: revenue,
      totalProfit: profit,
      netCashFlow: netFlow,
      cashInflow: inflow,
      cashOutflow: outflow,
      totalSales: sales,
      itemsSold: items,
      dueByCustomers: dueCust,
      payableToSuppliers: payableSupp,
      creditWithSuppliers: creditSupp,
      customerStoreCredit: creditCust,
      totalPurchases: purchases,
      averageSale: sales > 0 ? revenue / sales : 0,
      customerRefunds: refunds,
      supplierReturns: returns,
    );
  }

  Future<AggregatedStats> getTodayStats() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return getAggregatedStatsForPeriod(start, end);
  }

  Future<AggregatedStats> getThisWeekStats() async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return getAggregatedStatsForPeriod(DateTime(start.year, start.month, start.day), now);
  }

  Future<AggregatedStats> getThisMonthStats() async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    return getAggregatedStatsForPeriod(start, now);
  }

  Future<DailyStats?> getSummaryById(String id) async {
    try {
      if (!await checkConnectivity()) throw Exception('No internet connection');
      final response = await _dio.get('/$dashboardDB/$id');
      if (response.statusCode == 200) {
        final doc = response.data as Map<String, dynamic>;
        if (doc.containsKey('_deleted')) return null;
        return DailyStats.fromCouchDB(doc);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _handleDioException(e);
    }
  }

  Exception _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return Exception('Connection timeout');
      case DioExceptionType.connectionError:
        return Exception('Connection failed');
      case DioExceptionType.badResponse:
        return Exception('HTTP Error ${e.response?.statusCode}');
      default:
        return Exception('Network error: ${e.message}');
    }
  }

  void dispose() => _dio.close();
}