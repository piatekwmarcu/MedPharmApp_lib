// ============================================================================
// API CONFIGURATION
// ============================================================================
// This file contains all API-related configuration constants.
//
// For development/testing, we use mock mode which simulates API responses.
// For production, set useMockApi to false and configure the real baseUrl.
// ============================================================================

/// API Configuration for MedPharm Clinical Trial Backend
class ApiConfig {
  // ==========================================================================
  // ENVIRONMENT CONFIGURATION
  // ==========================================================================

  /// Whether to use mock API (no real network calls)
  /// Set to false when connecting to real backend
  static const bool useMockApi = true;

  /// Simulated network delay for mock API (milliseconds)
  static const int mockNetworkDelayMs = 800;

  /// Base URL for the API
  /// Production: https://api.medpharm-trials.com/v1
  /// Development: http://localhost:3000
  static const String baseUrl = 'https://api.medpharm-trials.com/v1';

  /// API Version
  static const String apiVersion = 'v1';

  // ==========================================================================
  // ENDPOINTS
  // ==========================================================================

  /// Authentication & Enrollment
  static const String enrollmentValidate = '/enrollment/validate';
  static const String enrollmentConsent = '/enrollment/consent';

  /// Questionnaires
  static const String questionnaireConfig = '/questionnaires/config';

  /// Assessments
  static const String assessmentsSync = '/assessments/sync';
  static const String assessmentsSyncBatch = '/assessments/sync/batch';

  /// Sync Status
  static const String syncStatus = '/sync/status';

  /// Alerts
  static const String alerts = '/alerts';

  /// Audit Logs
  static const String auditLog = '/audit/log';

  // ==========================================================================
  // TIMEOUTS
  // ==========================================================================

  /// Connection timeout in seconds
  static const int connectionTimeoutSeconds = 30;

  /// Receive timeout in seconds
  static const int receiveTimeoutSeconds = 30;

  /// Send timeout in seconds
  static const int sendTimeoutSeconds = 60;

  // ==========================================================================
  // RETRY CONFIGURATION
  // ==========================================================================

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Base delay for exponential backoff (milliseconds)
  static const int retryBaseDelayMs = 1000;

  /// Maximum delay between retries (milliseconds)
  static const int retryMaxDelayMs = 60000;

  /// Multiplier for exponential backoff
  static const double retryBackoffMultiplier = 2.0;

  // ==========================================================================
  // SYNC CONFIGURATION
  // ==========================================================================

  /// Maximum time before sync is considered overdue (hours)
  static const int syncDeadlineHours = 48;

  /// Warning threshold before deadline (hours)
  static const int syncWarningHours = 36;

  /// Automatic sync interval when connected (minutes)
  static const int autoSyncIntervalMinutes = 360; // 6 hours

  /// Batch size for bulk sync operations
  static const int syncBatchSize = 10;

  // ==========================================================================
  // RATE LIMITING
  // ==========================================================================

  /// Minimum delay between API calls (milliseconds)
  static const int minRequestIntervalMs = 100;

  /// Maximum requests per minute
  static const int maxRequestsPerMinute = 100;

  // ==========================================================================
  // HELPER METHODS
  // ==========================================================================

  /// Get full URL for an endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Calculate retry delay with exponential backoff
  static int calculateRetryDelay(int attemptNumber) {
    final delay = retryBaseDelayMs *
        (retryBackoffMultiplier * attemptNumber).toInt();
    return delay.clamp(retryBaseDelayMs, retryMaxDelayMs);
  }
}

// ============================================================================
// HTTP HEADERS
// ============================================================================

/// Standard HTTP headers for API requests
class ApiHeaders {
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String appVersion = 'X-App-Version';
  static const String platform = 'X-Platform';
  static const String deviceId = 'X-Device-Id';
  static const String requestId = 'X-Request-Id';

  static const String contentTypeJson = 'application/json';
  static const String bearerPrefix = 'Bearer ';
}

// ============================================================================
// API ERROR CODES
// ============================================================================

/// Standard API error codes from the backend
class ApiErrorCodes {
  // Authentication errors
  static const String invalidToken = 'INVALID_TOKEN';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String unauthorized = 'UNAUTHORIZED';

  // Enrollment errors
  static const String invalidEnrollmentCode = 'INVALID_ENROLLMENT_CODE';
  static const String codeAlreadyUsed = 'CODE_ALREADY_USED';
  static const String codeExpired = 'CODE_EXPIRED';

  // Assessment errors
  static const String duplicateAssessment = 'DUPLICATE_ASSESSMENT';
  static const String outsideTimeWindow = 'OUTSIDE_TIME_WINDOW';
  static const String incompleteData = 'INCOMPLETE_DATA';
  static const String invalidScore = 'INVALID_SCORE';

  // Sync errors
  static const String syncConflict = 'SYNC_CONFLICT';
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';

  // Rate limiting
  static const String rateLimitExceeded = 'RATE_LIMIT_EXCEEDED';
}

// ============================================================================
// ALERT TYPES
// ============================================================================

/// Alert types that can be sent to trial coordinators
class AlertTypes {
  static const String missedAssessment = 'MISSED_ASSESSMENT';
  static const String syncFailure = 'SYNC_FAILURE';
  static const String highPainScore = 'HIGH_PAIN_SCORE';
  static const String suddenPainIncrease = 'SUDDEN_PAIN_INCREASE';
  static const String consentWithdrawn = 'CONSENT_WITHDRAWN';
}

// ============================================================================
// AUDIT EVENT TYPES
// ============================================================================

/// Audit log event types for regulatory compliance
class AuditEventTypes {
  static const String appInstalled = 'APP_INSTALLED';
  static const String appUninstalled = 'APP_UNINSTALLED';
  static const String userEnrolled = 'USER_ENROLLED';
  static const String consentAccepted = 'CONSENT_ACCEPTED';
  static const String consentWithdrawn = 'CONSENT_WITHDRAWN';
  static const String assessmentStarted = 'ASSESSMENT_STARTED';
  static const String assessmentCompleted = 'ASSESSMENT_COMPLETED';
  static const String assessmentAbandoned = 'ASSESSMENT_ABANDONED';
  static const String notificationReceived = 'NOTIFICATION_RECEIVED';
  static const String notificationOpened = 'NOTIFICATION_OPENED';
  static const String settingsChanged = 'SETTINGS_CHANGED';
  static const String syncInitiated = 'SYNC_INITIATED';
  static const String syncSucceeded = 'SYNC_SUCCEEDED';
  static const String syncFailed = 'SYNC_FAILED';
  static const String dataExported = 'DATA_EXPORTED';
}
