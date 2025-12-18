// ============================================================================
// USER MODEL
// ============================================================================

/// Represents a user enrolled in the clinical trial
class UserModel {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================

  final int? id; // Database ID (null if not yet saved)
  final String studyId; // Unique ID from the trial system
  final String enrollmentCode; // Code used to enroll
  final DateTime enrolledAt; // When the user enrolled
  final bool consentAccepted; // Has user accepted consent?
  final DateTime? consentAcceptedAt; // When consent was accepted
  final bool tutorialCompleted; // Has user completed tutorial?

  // ==========================================================================
  // CONSTRUCTOR
  // ==========================================================================

  UserModel({
    this.id,
    required this.studyId,
    required this.enrollmentCode,
    required this.enrolledAt,
    this.consentAccepted = false,
    this.consentAcceptedAt,
    this.tutorialCompleted = false,
  });

  // ==========================================================================
  // TO MAP (for database)
  // ==========================================================================

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'study_id': studyId,
      'enrollment_code': enrollmentCode,
      'enrolled_at': enrolledAt.toIso8601String(),
      'consent_accepted': consentAccepted ? 1 : 0,
      'consent_accepted_at': consentAcceptedAt?.toIso8601String(),
      'tutorial_completed': tutorialCompleted ? 1 : 0,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  // ==========================================================================
  // FROM MAP (from database)
  // ==========================================================================

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      studyId: map['study_id'] as String,
      enrollmentCode: map['enrollment_code'] as String,
      enrolledAt: DateTime.parse(map['enrolled_at'] as String),
      consentAccepted: map['consent_accepted'] == 1,
      consentAcceptedAt: map['consent_accepted_at'] != null
          ? DateTime.parse(map['consent_accepted_at'] as String)
          : null,
      tutorialCompleted: map['tutorial_completed'] == 1,
    );
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================

  UserModel copyWith({
    int? id,
    String? studyId,
    String? enrollmentCode,
    DateTime? enrolledAt,
    bool? consentAccepted,
    DateTime? consentAcceptedAt,
    bool? tutorialCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      studyId: studyId ?? this.studyId,
      enrollmentCode: enrollmentCode ?? this.enrollmentCode,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      consentAccepted: consentAccepted ?? this.consentAccepted,
      consentAcceptedAt: consentAcceptedAt ?? this.consentAcceptedAt,
      tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
    );
  }

  // ==========================================================================
  // HELPERS
  // ==========================================================================

  /// Onboarding = consent + tutorial
  bool get hasCompletedOnboarding {
    return consentAccepted && tutorialCompleted;
  }

  /// Human-readable status
  String get enrollmentStatus {
    if (!consentAccepted) return 'Consent Pending';
    if (!tutorialCompleted) return 'Tutorial Pending';
    return 'Enrolled';
  }

  @override
  String toString() {
    return 'UserModel(id: $id, studyId: $studyId, status: $enrollmentStatus)';
  }
}
