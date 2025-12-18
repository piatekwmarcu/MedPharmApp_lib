// ============================================================================
// ASSESSMENT MODEL - SCAFFOLDED FOR PHASE 2
// ============================================================================

class AssessmentModel {
  // ==========================================================================
  // PROPERTIES
  // ==========================================================================
  final String id; // Unique ID (generated from timestamp)
  final String studyId; // Links to user (foreign key)
  final int nrsScore; // Pain rating 0–10
  final int vasScore; // Visual analog 0–100
  final DateTime timestamp; // When assessment was taken
  final bool isSynced; // Has it been synced to server?
  final DateTime createdAt; // When record was created

  // ==========================================================================
  // CONSTRUCTOR + VALIDATION
  // ==========================================================================
  AssessmentModel({
    String? id,
    required this.studyId,
    required this.nrsScore,
    required this.vasScore,
    required this.timestamp,
    this.isSynced = false,
    DateTime? createdAt,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = createdAt ?? DateTime.now() {
    if (nrsScore < 0 || nrsScore > 10) {
      throw ArgumentError('NRS score must be between 0 and 10');
    }
    if (vasScore < 0 || vasScore > 100) {
      throw ArgumentError('VAS score must be between 0 and 100');
    }
  }

  // ==========================================================================
  // TO MAP (for DB)
  // ==========================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'study_id': studyId,
      'nrs_score': nrsScore,
      'vas_score': vasScore,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // ==========================================================================
  // FROM MAP (for DB)
  // ==========================================================================
  factory AssessmentModel.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      if (v is String) return int.parse(v);
      throw ArgumentError('Cannot convert $v to int');
    }

    bool _toBool(dynamic v) {
      if (v is bool) return v;
      if (v is int) return v == 1;
      if (v is String) return v == '1' || v.toLowerCase() == 'true';
      return false;
    }

    DateTime _toDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Cannot convert $v to DateTime');
    }

    return AssessmentModel(
      id: map['id']?.toString(),
      studyId: map['study_id'] as String,
      nrsScore: _toInt(map['nrs_score']),
      vasScore: _toInt(map['vas_score']),
      timestamp: _toDate(map['timestamp']),
      isSynced: _toBool(map['is_synced']),
      createdAt: map['created_at'] == null ? DateTime.now() : _toDate(map['created_at']),
    );
  }

  // ==========================================================================
  // COPY WITH
  // ==========================================================================
  AssessmentModel copyWith({
    String? id,
    String? studyId,
    int? nrsScore,
    int? vasScore,
    DateTime? timestamp,
    bool? isSynced,
    DateTime? createdAt,
  }) {
    return AssessmentModel(
      id: id ?? this.id,
      studyId: studyId ?? this.studyId,
      nrsScore: nrsScore ?? this.nrsScore,
      vasScore: vasScore ?? this.vasScore,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ==========================================================================
  // UI HELPERS
  // ==========================================================================
  String get painLevelDescription {
    if (nrsScore == 0) return 'No Pain';
    if (nrsScore <= 3) return 'Mild Pain';
    if (nrsScore <= 6) return 'Moderate Pain';
    if (nrsScore <= 9) return 'Severe Pain';
    return 'Worst Possible Pain';
  }

  String get painLevelColor {
    if (nrsScore == 0) return '#4CAF50'; // Green
    if (nrsScore <= 3) return '#8BC34A'; // Light Green
    if (nrsScore <= 6) return '#FFC107'; // Yellow
    if (nrsScore <= 9) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  bool get isTodayAssessment {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  String get formattedDate {
    return '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'AssessmentModel(id: $id, NRS: $nrsScore, VAS: $vasScore, date: $formattedDate)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AssessmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
