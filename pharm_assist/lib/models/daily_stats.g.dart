// lib/models/daily_stats.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stats.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DailyStats _$DailyStatsFromJson(Map<String, dynamic> json) => DailyStats(
  id: json['id'] as int?,
  date: json['date'] as String,
  storeId: json['storeId'] as String?,
  storeName: json['storeName'] as String?,
  hour: json['hour'] as String?,
  totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
  totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
  netCashFlow: (json['netCashFlow'] as num?)?.toDouble() ?? 0.0,
  cashInflow: (json['cashInflow'] as num?)?.toDouble() ?? 0.0,
  cashOutflow: (json['cashOutflow'] as num?)?.toDouble() ?? 0.0,
  totalSales: json['totalSales'] as int? ?? 0,
  itemsSold: json['itemsSold'] as int? ?? 0,
  dueByCustomers: (json['dueByCustomers'] as num?)?.toDouble() ?? 0.0,
  payableToSuppliers: (json['payableToSuppliers'] as num?)?.toDouble() ?? 0.0,
  creditWithSuppliers: (json['creditWithSuppliers'] as num?)?.toDouble() ?? 0.0,
  customerStoreCredit: (json['customerStoreCredit'] as num?)?.toDouble() ?? 0.0,
  totalPurchases: (json['totalPurchases'] as num?)?.toDouble() ?? 0.0,
  averageSale: (json['averageSale'] as num?)?.toDouble() ?? 0.0,
  customerRefunds: (json['customerRefunds'] as num?)?.toDouble() ?? 0.0,
  supplierReturns: (json['supplierReturns'] as num?)?.toDouble() ?? 0.0,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$DailyStatsToJson(DailyStats instance) => <String, dynamic>{
  'id': instance.id,
  'date': instance.date,
  'storeId': instance.storeId,
  'storeName': instance.storeName,
  'hour': instance.hour,
  'totalRevenue': instance.totalRevenue,
  'totalProfit': instance.totalProfit,
  'netCashFlow': instance.netCashFlow,
  'cashInflow': instance.cashInflow,
  'cashOutflow': instance.cashOutflow,
  'totalSales': instance.totalSales,
  'itemsSold': instance.itemsSold,
  'dueByCustomers': instance.dueByCustomers,
  'payableToSuppliers': instance.payableToSuppliers,
  'creditWithSuppliers': instance.creditWithSuppliers,
  'customerStoreCredit': instance.customerStoreCredit,
  'totalPurchases': instance.totalPurchases,
  'averageSale': instance.averageSale,
  'customerRefunds': instance.customerRefunds,
  'supplierReturns': instance.supplierReturns,
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
};

SyncLog _$SyncLogFromJson(Map<String, dynamic> json) => SyncLog(
  id: json['id'] as int?,
  syncType: json['syncType'] as String,
  status: json['status'] as String,
  recordsSynced: json['recordsSynced'] as int? ?? 0,
  errorMessage: json['errorMessage'] as String?,
  syncedAt: DateTime.parse(json['syncedAt'] as String),
);

Map<String, dynamic> _$SyncLogToJson(SyncLog instance) => <String, dynamic>{
  'id': instance.id,
  'syncType': instance.syncType,
  'status': instance.status,
  'recordsSynced': instance.recordsSynced,
  'errorMessage': instance.errorMessage,
  'syncedAt': instance.syncedAt.toIso8601String(),
};