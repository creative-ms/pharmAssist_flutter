// lib/core/services/background_sync_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import './simplified_sync_service.dart';

class BackgroundSyncService extends ChangeNotifier {
  static final BackgroundSyncService instance = BackgroundSyncService._internal();

  Timer? _syncTimer;
  bool _isEnabled = true;
  bool _isSyncing = false;
  SyncResult? _lastSyncResult;

  // Sync every hour
  static const Duration _syncInterval = Duration(hours: 1);

  BackgroundSyncService._internal();

  bool get isEnabled => _isEnabled;
  bool get isSyncing => _isSyncing;
  SyncResult? get lastSyncResult => _lastSyncResult;

  /// Start background sync service
  Future<void> start() async {
    if (_syncTimer?.isActive == true) {
      return; // Already running
    }

    // Perform initial sync
    await _performBackgroundSync();

    // Schedule periodic syncs
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performBackgroundSync();
    });

    debugPrint('Background sync service started');
  }

  /// Stop background sync service
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Background sync service stopped');
  }

  /// Enable/disable background sync
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      start();
    } else {
      stop();
    }
    notifyListeners();
  }

  /// Perform background sync
  Future<void> _performBackgroundSync() async {
    if (!_isEnabled || _isSyncing) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      _lastSyncResult = await SimplifiedSyncService.instance.performSync();
      debugPrint('Background sync completed: ${_lastSyncResult?.message}');
    } catch (e) {
      _lastSyncResult = SyncResult(
        success: false,
        message: 'Background sync failed: $e',
        syncType: SyncType.incremental,
        error: e.toString(),
      );
      debugPrint('Background sync error: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Manual sync trigger
  Future<SyncResult> triggerManualSync([SyncType? syncType]) async {
    // Use the force parameter instead of passing syncType directly
    final result = await SimplifiedSyncService.instance.performSync(
        force: syncType == SyncType.full
    );
    _lastSyncResult = result;
    notifyListeners();
    return result;
  }

  /// Get sync status
  Map<String, dynamic> getStatus() {
    return {
      'is_enabled': _isEnabled,
      'is_syncing': _isSyncing,
      'is_timer_active': _syncTimer?.isActive ?? false,
      'last_sync_result': _lastSyncResult != null ? {
        'success': _lastSyncResult!.success,
        'message': _lastSyncResult!.message,
        'sync_type': _lastSyncResult!.syncType.toString(),
        'records_synced': _lastSyncResult!.recordsSynced,
        'records_updated': _lastSyncResult!.recordsUpdated,
      } : null,
      'enhanced_sync_status': SimplifiedSyncService.instance.getSyncStatus(),
    };
  }

  /// Initialize background sync on app start
  Future<void> initialize() async {
    await SimplifiedSyncService.instance.initialize();
    await start();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}