// ============================================================================
// SYNC MODELS
// ============================================================================
// Models for the offline-first synchronization system.
//
// Key concepts:
// - SyncQueueItem: Represents a pending sync operation
// - SyncStatus: Overall sync state for the app
// - SyncResult: Result of a sync operation
// - AuditLogEntry: Audit trail for regulatory compliance
// ============================================================================

/// Status of a sync queue item
enum SyncItemStatus {
  pending,    // Waiting to be synced
  syncing,    // Currently being synced
  completed,  // Successfully synced
  failed,     // Sync failed (will retry)
  expired,    // Past deadline, requires attention
}

/// Type of data being synced
enum SyncItemType {
  assessment,     // Pain assessment data
  consent,        // Consent acceptance
  auditLog,       // Audit trail events
  alert,          // Coordinator alerts
  gamification,   // Points and badges (future)
}

// ============================================================================
// SYNC QUEUE ITEM
// ============================================================================

/// Represents an item in the sync queue
///
/// Each piece of data that needs to be synced to the server
/// is tracked as a SyncQueueItem. This enables:
/// - Offline-first: Save locally, sync later
/// - Retry logic: Track failed attempts
/// - Deadline enforcement: Ensure data syncs within 48 hours
class SyncQueueItem {
  final String id;
  final String studyId;
  final SyncItemType itemType;
  final String dataId;         // ID of the data (e.g., assessmentId)
  final String payload;        // JSON payload to sync
  final SyncItemStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  final DateTime? syncedAt;
  final DateTime deadline;     // Must sync by this time

  SyncQueueItem({
    String? id,
    required this.studyId,
    required this.itemType,
    required this.dataId,
    required this.payload,
    this.status = SyncItemStatus.pending,
    this.retryCount = 0,
    this.lastError,
    DateTime? createdAt,
    this.lastAttemptAt,
    this.syncedAt,
    DateTime? deadline,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now(),
        deadline = deadline ?? DateTime.now().add(const Duration(hours: 48));

  /// Check if this item is past its sync deadline
  bool get isOverdue => DateTime.now().isAfter(deadline);

  /// Check if this item is approaching its deadline (within 12 hours)
  bool get isApproachingDeadline {
    final warningTime = deadline.subtract(const Duration(hours: 12));
    return DateTime.now().isAfter(warningTime) && !isOverdue;
  }

  /// Get hours remaining until deadline
  int get hoursUntilDeadline {
    final remaining = deadline.difference(DateTime.now());
    return remaining.inHours;
  }

  /// Check if we should retry this item
  bool get shouldRetry {
    return status == SyncItemStatus.failed &&
        retryCount < 5 &&
        !isOverdue;
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'item_type': itemType.name,
      'data_id': dataId,
      'payload': payload,
      'status': status.name,
      'retry_count': retryCount,
      'last_error': lastError,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'synced_at': syncedAt?.toIso8601String(),
      'deadline': deadline.toIso8601String(),
    };
  }

  /// Create from database Map
  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      itemType: SyncItemType.values.firstWhere(
            (e) => e.name == map['item_type'],
      ),
      dataId: map['data_id'] as String,
      payload: map['payload'] as String,
      status: SyncItemStatus.values.firstWhere(
            (e) => e.name == map['status'],
      ),
      retryCount: map['retry_count'] as int,
      lastError: map['last_error'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      lastAttemptAt: map['last_attempt_at'] != null
          ? DateTime.parse(map['last_attempt_at'] as String)
          : null,
      syncedAt: map['synced_at'] != null
          ? DateTime.parse(map['synced_at'] as String)
          : null,
      deadline: DateTime.parse(map['deadline'] as String),
    );
  }

  /// Create a copy with updated fields
  SyncQueueItem copyWith({
    String? id,
    String? studyId,
    SyncItemType? itemType,
    String? dataId,
    String? payload,
    SyncItemStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    DateTime? syncedAt,
    DateTime? deadline,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      studyId: studyId ?? this.studyId,
      itemType: itemType ?? this.itemType,
      dataId: dataId ?? this.dataId,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      syncedAt: syncedAt ?? this.syncedAt,
      deadline: deadline ?? this.deadline,
    );
  }

  @override
  String toString() {
    return 'SyncQueueItem($itemType: $dataId, status: $status, retries: $retryCount)';
  }
}

// ============================================================================
// SYNC STATUS
// ============================================================================

/// Overall sync status for the application
class SyncStatus {
  final bool isOnline;
  final bool isSyncing;
  final int pendingCount;
  final int failedCount;
  final int overdueCount;
  final DateTime? lastSyncAt;
  final String? lastError;
  final DateTime? nextScheduledSync;

  const SyncStatus({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingCount = 0,
    this.failedCount = 0,
    this.overdueCount = 0,
    this.lastSyncAt,
    this.lastError,
    this.nextScheduledSync,
  });

  /// Check if everything is synced
  bool get isFullySynced =>
      pendingCount == 0 && failedCount == 0 && overdueCount == 0;

  /// Check if there are items needing attention
  bool get needsAttention => failedCount > 0 || overdueCount > 0;

  /// Get a human-readable status message
  String get statusMessage {
    if (isSyncing) return 'Syncing...';
    if (!isOnline) return 'Offline';
    if (isFullySynced) return 'All synced';
    if (overdueCount > 0) return '$overdueCount overdue!';
    if (failedCount > 0) return '$failedCount failed';
    if (pendingCount > 0) return '$pendingCount pending';
    return 'Unknown';
  }

  /// Get status color for UI
  String get statusColor {
    if (overdueCount > 0) return 'red';
    if (failedCount > 0) return 'orange';
    if (!isOnline) return 'grey';
    if (isSyncing) return 'blue';
    if (isFullySynced) return 'green';
    if (pendingCount > 0) return 'yellow';
    return 'grey';
  }

  SyncStatus copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingCount,
    int? failedCount,
    int? overdueCount,
    DateTime? lastSyncAt,
    String? lastError,
    DateTime? nextScheduledSync,
  }) {
    return SyncStatus(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingCount: pendingCount ?? this.pendingCount,
      failedCount: failedCount ?? this.failedCount,
      overdueCount: overdueCount ?? this.overdueCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastError: lastError ?? this.lastError,
      nextScheduledSync: nextScheduledSync ?? this.nextScheduledSync,
    );
  }
}

// ============================================================================
// SYNC RESULT
// ============================================================================

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? syncedAt;
  final Map<String, dynamic>? serverResponse;

  const SyncResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.syncedAt,
    this.serverResponse,
  });

  factory SyncResult.success({
    DateTime? syncedAt,
    Map<String, dynamic>? serverResponse,
  }) {
    return SyncResult(
      success: true,
      syncedAt: syncedAt ?? DateTime.now(),
      serverResponse: serverResponse,
    );
  }

  factory SyncResult.failure({
    required String errorCode,
    required String errorMessage,
  }) {
    return SyncResult(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  @override
  String toString() {
    if (success) return 'SyncResult(success)';
    return 'SyncResult(failed: $errorCode - $errorMessage)';
  }
}

// ============================================================================
// AUDIT LOG ENTRY
// ============================================================================

/// Audit log entry for regulatory compliance (FDA 21 CFR Part 11)
class AuditLogEntry {
  final String id;
  final String studyId;
  final String eventType;
  final Map<String, dynamic> eventDetails;
  final DateTime timestamp;
  final String appVersion;
  final String platform;
  final String osVersion;
  final bool isSynced;

  AuditLogEntry({
    String? id,
    required this.studyId,
    required this.eventType,
    required this.eventDetails,
    DateTime? timestamp,
    required this.appVersion,
    required this.platform,
    required this.osVersion,
    this.isSynced = false,
  })  : id = id ?? 'log_${DateTime.now().millisecondsSinceEpoch}',
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'event_type': eventType,
      'event_details': eventDetails.toString(),
      'timestamp': timestamp.toIso8601String(),
      'app_version': appVersion,
      'platform': platform,
      'os_version': osVersion,
      'is_synced': isSynced ? 1 : 0,
    };
  }

  /// Convert to API payload format
  Map<String, dynamic> toApiPayload() {
    return {
      'logId': id,
      'studyId': studyId,
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType,
      'eventDetails': eventDetails,
      'deviceInfo': {
        'platform': platform,
        'osVersion': osVersion,
        'appVersion': appVersion,
      },
    };
  }

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] as String,
      studyId: map['study_id'] as String,
      eventType: map['event_type'] as String,
      eventDetails: Map<String, dynamic>.from(
        map['event_details'] is String
            ? {'raw': map['event_details']}
            : map['event_details'] as Map,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      appVersion: map['app_version'] as String,
      platform: map['platform'] as String,
      osVersion: map['os_version'] as String,
      isSynced: map['is_synced'] == 1,
    );
  }
}

// ============================================================================
// BATCH SYNC RESULT
// ============================================================================

/// Result of a batch sync operation
class BatchSyncResult {
  final int totalReceived;
  final int successful;
  final int failed;
  final List<SyncItemResult> results;

  const BatchSyncResult({
    required this.totalReceived,
    required this.successful,
    required this.failed,
    required this.results,
  });

  bool get isFullSuccess => failed == 0;
  bool get isPartialSuccess => successful > 0 && failed > 0;
  bool get isFullFailure => successful == 0 && failed > 0;
}

/// Result for a single item in a batch sync
class SyncItemResult {
  final String itemId;
  final bool success;
  final String? errorCode;
  final String? errorMessage;
  final DateTime? syncedAt;

  const SyncItemResult({
    required this.itemId,
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.syncedAt,
  });
}
