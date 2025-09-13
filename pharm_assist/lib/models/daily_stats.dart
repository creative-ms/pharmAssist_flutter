// lib/models/daily_stats.dart - FIXED VERSION
import 'package:json_annotation/json_annotation.dart';

part 'daily_stats.g.dart';

@JsonSerializable()
class DailyStats {
  final int? id;
  final String date;
  final String? storeId;
  final String? storeName;
  final String? hour;
  final double totalRevenue;
  final double totalProfit;
  final double netCashFlow;
  final double cashInflow;
  final double cashOutflow;
  final int totalSales;
  final int itemsSold;
  final double dueByCustomers;
  final double payableToSuppliers;
  final double creditWithSuppliers;
  final double customerStoreCredit;
  final double totalPurchases;
  final double averageSale;
  final double customerRefunds;
  final double supplierReturns;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DailyStats({
    this.id,
    required this.date,
    this.storeId,
    this.storeName,
    this.hour,
    this.totalRevenue = 0.0,
    this.totalProfit = 0.0,
    this.netCashFlow = 0.0,
    this.cashInflow = 0.0,
    this.cashOutflow = 0.0,
    this.totalSales = 0,
    this.itemsSold = 0,
    this.dueByCustomers = 0.0,
    this.payableToSuppliers = 0.0,
    this.creditWithSuppliers = 0.0,
    this.customerStoreCredit = 0.0,
    this.totalPurchases = 0.0,
    this.averageSale = 0.0,
    this.customerRefunds = 0.0,
    this.supplierReturns = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory DailyStats.fromJson(Map<String, dynamic> json) => _$DailyStatsFromJson(json);
  Map<String, dynamic> toJson() => _$DailyStatsToJson(this);

  // FIXED: Convert from CouchDB document format
  factory DailyStats.fromCouchDB(Map<String, dynamic> doc) {
    print('[DailyStats] Parsing document: ${doc['_id']}');

    // Use the date field directly if available, otherwise extract from ID
    String dateStr;
    if (doc['date'] != null) {
      dateStr = doc['date'].toString();
      // Ensure it's in ISO format for consistency
      if (!dateStr.contains('T')) {
        dateStr = '${dateStr}T00:00:00';
      }
    } else {
      // Fallback: extract from document ID
      dateStr = DateTime.now().toIso8601String();
      final docId = doc['_id'] as String?;
      if (docId?.contains('-') == true) {
        try {
          final parts = docId!.split('-');
          if (parts.length >= 4) {
            // Find the date part (YYYY-MM-DD pattern)
            for (int i = 0; i < parts.length - 2; i++) {
              if (parts[i].length == 4 &&
                  parts[i + 1].length == 2 &&
                  parts[i + 2].length == 2) {
                dateStr = '${parts[i]}-${parts[i + 1]}-${parts[i + 2]}T00:00:00';
                break;
              }
            }
          }
        } catch (e) {
          print('[DailyStats] Error parsing date from ID: $e');
        }
      }
    }

    return DailyStats(
      date: dateStr,
      storeId: doc['storeId']?.toString(),
      storeName: doc['storeName']?.toString(),
      hour: doc['hour']?.toString() ?? doc['timestamp']?.toString(),

      // Revenue and sales data - using your field names
      totalRevenue: _parseDouble(doc['totalRevenue']),
      totalProfit: _parseDouble(doc['totalProfit']),
      netCashFlow: _parseDouble(doc['netCashFlow']),
      cashInflow: _parseDouble(doc['cashInflow']),
      cashOutflow: _parseDouble(doc['cashOutflow']),

      totalSales: _parseInt(doc['totalSales']),
      itemsSold: _parseInt(doc['itemsSold']),

      // Customer and supplier balances
      dueByCustomers: _parseDouble(doc['dueByCustomers']),
      payableToSuppliers: _parseDouble(doc['payableToSuppliers']),
      creditWithSuppliers: _parseDouble(doc['creditWithSuppliers']),
      customerStoreCredit: _parseDouble(doc['customerStoreCredit']),

      // Other metrics
      totalPurchases: _parseDouble(doc['totalPurchases']),
      averageSale: _parseDouble(doc['averageSale']),
      customerRefunds: _parseDouble(doc['customerRefunds']),
      supplierReturns: _parseDouble(doc['supplierReturns']),
    );
  }

  // Simplified helper methods
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // Convert to database map
  Map<String, dynamic> toDatabaseMap() {
    return {
      'date': date,
      'store_id': storeId,
      'store_name': storeName,
      'hour': hour,
      'total_revenue': totalRevenue,
      'total_profit': totalProfit,
      'net_cash_flow': netCashFlow,
      'cash_inflow': cashInflow,
      'cash_outflow': cashOutflow,
      'total_sales': totalSales,
      'items_sold': itemsSold,
      'due_by_customers': dueByCustomers,
      'payable_to_suppliers': payableToSuppliers,
      'credit_with_suppliers': creditWithSuppliers,
      'customer_store_credit': customerStoreCredit,
      'total_purchases': totalPurchases,
      'average_sale': averageSale,
      'customer_refunds': customerRefunds,
      'supplier_returns': supplierReturns,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Create from database map
  factory DailyStats.fromDatabaseMap(Map<String, dynamic> map) {
    return DailyStats(
      id: map['id']?.toInt(),
      date: map['date'] ?? '',
      storeId: map['store_id']?.toString(),
      storeName: map['store_name']?.toString(),
      hour: map['hour']?.toString(),
      totalRevenue: (map['total_revenue'] as num?)?.toDouble() ?? 0.0,
      totalProfit: (map['total_profit'] as num?)?.toDouble() ?? 0.0,
      netCashFlow: (map['net_cash_flow'] as num?)?.toDouble() ?? 0.0,
      cashInflow: (map['cash_inflow'] as num?)?.toDouble() ?? 0.0,
      cashOutflow: (map['cash_outflow'] as num?)?.toDouble() ?? 0.0,
      totalSales: (map['total_sales'] as num?)?.toInt() ?? 0,
      itemsSold: (map['items_sold'] as num?)?.toInt() ?? 0,
      dueByCustomers: (map['due_by_customers'] as num?)?.toDouble() ?? 0.0,
      payableToSuppliers: (map['payable_to_suppliers'] as num?)?.toDouble() ?? 0.0,
      creditWithSuppliers: (map['credit_with_suppliers'] as num?)?.toDouble() ?? 0.0,
      customerStoreCredit: (map['customer_store_credit'] as num?)?.toDouble() ?? 0.0,
      totalPurchases: (map['total_purchases'] as num?)?.toDouble() ?? 0.0,
      averageSale: (map['average_sale'] as num?)?.toDouble() ?? 0.0,
      customerRefunds: (map['customer_refunds'] as num?)?.toDouble() ?? 0.0,
      supplierReturns: (map['supplier_returns'] as num?)?.toDouble() ?? 0.0,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    );
  }

  DailyStats copyWith({
    int? id,
    String? date,
    String? storeId,
    String? storeName,
    String? hour,
    double? totalRevenue,
    double? totalProfit,
    double? netCashFlow,
    double? cashInflow,
    double? cashOutflow,
    int? totalSales,
    int? itemsSold,
    double? dueByCustomers,
    double? payableToSuppliers,
    double? creditWithSuppliers,
    double? customerStoreCredit,
    double? totalPurchases,
    double? averageSale,
    double? customerRefunds,
    double? supplierReturns,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DailyStats(
      id: id ?? this.id,
      date: date ?? this.date,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      hour: hour ?? this.hour,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProfit: totalProfit ?? this.totalProfit,
      netCashFlow: netCashFlow ?? this.netCashFlow,
      cashInflow: cashInflow ?? this.cashInflow,
      cashOutflow: cashOutflow ?? this.cashOutflow,
      totalSales: totalSales ?? this.totalSales,
      itemsSold: itemsSold ?? this.itemsSold,
      dueByCustomers: dueByCustomers ?? this.dueByCustomers,
      payableToSuppliers: payableToSuppliers ?? this.payableToSuppliers,
      creditWithSuppliers: creditWithSuppliers ?? this.creditWithSuppliers,
      customerStoreCredit: customerStoreCredit ?? this.customerStoreCredit,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      averageSale: averageSale ?? this.averageSale,
      customerRefunds: customerRefunds ?? this.customerRefunds,
      supplierReturns: supplierReturns ?? this.supplierReturns,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

@JsonSerializable()
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
    this.recordsSynced = 0,
    this.errorMessage,
    required this.syncedAt,
  });

  factory SyncLog.fromJson(Map<String, dynamic> json) => _$SyncLogFromJson(json);
  Map<String, dynamic> toJson() => _$SyncLogToJson(this);

  Map<String, dynamic> toDatabaseMap() {
    return {
      'sync_type': syncType,
      'status': status,
      'records_synced': recordsSynced,
      'error_message': errorMessage,
      'synced_at': syncedAt.toIso8601String(),
    };
  }

  factory SyncLog.fromDatabaseMap(Map<String, dynamic> map) {
    return SyncLog(
      id: map['id']?.toInt(),
      syncType: map['sync_type'] ?? '',
      status: map['status'] ?? '',
      recordsSynced: (map['records_synced'] as num?)?.toInt() ?? 0,
      errorMessage: map['error_message']?.toString(),
      syncedAt: DateTime.parse(map['synced_at']),
    );
  }
}