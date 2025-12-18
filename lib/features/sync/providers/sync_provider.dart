// ============================================================================
// SYNC PROVIDER
// ============================================================================
// State management for synchronization UI.
//
// This provider:
// - Exposes sync status to UI
// - Triggers sync operations
// - Tracks online/offline state
// - Shows sync progress
// ============================================================================

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/sync_service.dart';
import '../services/network_service.dart';
import '../models/sync_models.dart';

/// Provider for synchronization state management
///
/// Usage in widgets:
/// ```dart
/// final syncProvider = context.watch<SyncProvider>();
/// if (syncProvider.isOnline) {
///   // Show online indicator
/// }
/// ```
class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final NetworkService _networkService;

  // State
  SyncStatus _syncStatus = const SyncStatus();
  bool _isOnline = false;
  bool _isSyncing = false;
  String? _errorMessage;
  int _lastSyncedCount = 0;

  // Subscriptions
  StreamSubscription? _connectivitySubscription;
  Timer? _autoSyncTimer;

  SyncProvider(this._syncService, this._networkService) {
    _initialize();
  }

  // ==========================================================================
  // GETTERS
  // ==========================================================================

  /// Current sync status
  SyncStatus get syncStatus => _syncStatus;

  /// Whether device is online
  bool get isOnline => _isOnline;

  /// Whether sync is in progress
  bool get isSyncing => _isSyncing;

  /// Last error message
  String? get errorMessage => _errorMessage;

  /// Number of items synced in last operation
  int get lastSyncedCount => _lastSyncedCount;

  /// Whether there are pending items
  bool get hasPendingItems => _syncStatus.pendingCount > 0;

  /// Whether there are failed items
  bool get hasFailedItems => _syncStatus.failedCount > 0;

  /// Whether there are overdue items (needs immediate attention)
  bool get hasOverdueItems => _syncStatus.overdueCount > 0;

  /// Whether everything is synced
  bool get isFullySynced => _syncStatus.isFullySynced;

  /// Human-readable status message
  String get statusMessage {
    if (_isSyncing) return 'Syncing...';
    if (!_isOnline) return 'Offline';
    if (hasOverdueItems) return '${_syncStatus.overdueCount} overdue!';
    if (hasFailedItems) return '${_syncStatus.failedCount} failed';
    if (hasPendingItems) return '${_syncStatus.pendingCount} pending';
    if (isFullySynced) return 'All synced';
    return 'Ready';
  }

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  /// Initialize provider
  void _initialize() {
    // Check initial connectivity
    _checkConnectivity();

    // Listen for connectivity changes
    _connectivitySubscription = _networkService.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Load initial sync status
    refreshSyncStatus();

    // Start auto-sync timer
    _startAutoSyncTimer();
  }

  /// Check current connectivity
  Future<void> _checkConnectivity() async {
    _isOnline = await _networkService.isConnected();
    notifyListeners();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(bool isConnected) {
    final wasOffline = !_isOnline;
    _isOnline = isConnected;
    notifyListeners();

    // If we just came online, trigger sync
    if (wasOffline && isConnected) {
      print('Sync: Came online, triggering sync...');
      syncNow();
    }
  }

  /// Start auto-sync timer
  void _startAutoSyncTimer() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(
      const Duration(minutes: 15),
          (_) => _autoSync(),
    );
  }

  /// Auto-sync callback
  Future<void> _autoSync() async {
    if (_isOnline && !_isSyncing && hasPendingItems) {
      print('Sync: Auto-sync triggered');
      await syncNow();
    }
  }

  // ==========================================================================
  // SYNC OPERATIONS
  // ==========================================================================

  /// Refresh sync status from database
  Future<void> refreshSyncStatus() async {
    try {
      _syncStatus = await _syncService.getSyncStatus();
      _syncStatus = _syncStatus.copyWith(
        isOnline: _isOnline,
        isSyncing: _isSyncing,
      );
      notifyListeners();
    } catch (e) {
      print('Sync: Error refreshing status: $e');
    }
  }

  /// Trigger immediate sync
  ///
  /// Call this when:
  /// - User presses sync button
  /// - App comes to foreground
  /// - After saving important data
  Future<void> syncNow() async {
    if (_isSyncing) {
      print('Sync: Already syncing, skipping');
      return;
    }

    if (!_isOnline) {
      _errorMessage = 'Cannot sync while offline';
      notifyListeners();
      return;
    }

    try {
      _isSyncing = true;
      _errorMessage = null;
      notifyListeners();

      // Process the queue
      final syncedCount = await _syncService.processQueue();
      _lastSyncedCount = syncedCount;

      // Retry failed items
      final retriedCount = await _syncService.retryFailedItems();
      _lastSyncedCount += retriedCount;

      // Refresh status
      await refreshSyncStatus();

      // Cleanup old items
      await _syncService.cleanupCompletedItems();

      _isSyncing = false;
      notifyListeners();

      print('Sync: Completed. Synced $_lastSyncedCount items');
    } catch (e) {
      _isSyncing = false;
      _errorMessage = 'Sync failed: $e';
      notifyListeners();
      print('Sync: Error during sync: $e');
    }
  }

  /// Queue an item for sync
  ///
  /// This is called by other providers/services when data is saved locally.
  Future<void> queueForSync({
    required String studyId,
    required SyncItemType itemType,
    required String dataId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await _syncService.addToQueue(
        studyId: studyId,
        itemType: itemType,
        dataId: dataId,
        payload: payload,
      );

      await refreshSyncStatus();

      // If online, try to sync immediately
      if (_isOnline && !_isSyncing) {
        // Small delay to batch nearby saves
        Future.delayed(const Duration(seconds: 2), () {
          if (_isOnline && !_isSyncing) {
            syncNow();
          }
        });
      }
    } catch (e) {
      _errorMessage = 'Failed to queue for sync: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ==========================================================================
  // DISPOSAL
  // ==========================================================================

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
