// lib/providers/sync_provider.dart
import 'package:flutter/foundation.dart';

class SyncProvider extends ChangeNotifier {
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastSyncError;
  String? _lastSyncMessage;
  int _lastRecordsSynced = 0;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastSyncError => _lastSyncError;
  String? get lastSyncMessage => _lastSyncMessage;
  int get lastRecordsSynced => _lastRecordsSynced;

  void setSyncing(bool syncing) {
    _isSyncing = syncing;
    notifyListeners();
  }

  void setSyncResult({
    required bool success,
    required String message,
    int recordsSynced = 0,
    String? error,
  }) {
    _isSyncing = false;
    _lastSyncTime = DateTime.now();
    _lastSyncMessage = message;
    _lastRecordsSynced = recordsSynced;
    _lastSyncError = success ? null : (error ?? message);
    notifyListeners();
  }

  void clearSyncError() {
    _lastSyncError = null;
    notifyListeners();
  }

  String get syncStatusText {
    if (_isSyncing) return 'Syncing...';
    if (_lastSyncError != null) return 'Sync failed';
    if (_lastSyncTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_lastSyncTime!);
      if (diff.inMinutes < 1) return 'Just synced';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return 'Never synced';
  }
}