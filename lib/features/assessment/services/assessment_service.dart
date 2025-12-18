import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../models/assessment_model.dart';

class AssessmentService {
  final DatabaseService _databaseService;

  AssessmentService(this._databaseService);

  /// Save assessment
  Future<String> saveAssessment(AssessmentModel assessment) async {
    try {
      print('💾 Saving assessment: ${assessment.toString()}');
      final db = await _databaseService.database;
      await db.insert(
        'assessments',
        assessment.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('✅ Assessment saved: ${assessment.id}');
      return assessment.id;
    } catch (e) {
      print('❌ Error saving assessment: $e');
      rethrow;
    }
  }

  /// Get today's assessment
  Future<AssessmentModel?> getTodayAssessment(String studyId) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final results = await db.query(
        'assessments',
        where: 'study_id = ? AND timestamp >= ? AND timestamp < ?',
        whereArgs: [
          studyId,
          startOfDay.toIso8601String(),
          endOfDay.toIso8601String(),
        ],
        limit: 1,
      );

      if (results.isEmpty) {
        print('ℹ️ No assessment found for today');
        return null;
      }

      final assessment = AssessmentModel.fromMap(results.first);
      print('✅ Found today\'s assessment: ${assessment.id}');
      return assessment;
    } catch (e) {
      print('❌ Error getting today\'s assessment: $e');
      rethrow;
    }
  }

  /// ✅ Get assessment history
  Future<List<AssessmentModel>> getAssessmentHistory(
      String studyId, {
        int limit = 30,
      }) async {
    try {
      print('📜 Loading assessment history for $studyId');
      final db = await _databaseService.database;

      final results = await db.query(
        'assessments',
        where: 'study_id = ?',
        whereArgs: [studyId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );

      final history = results.map((map) => AssessmentModel.fromMap(map)).toList();
      print('✅ Loaded ${history.length} assessments');
      return history;
    } catch (e) {
      print('❌ Error getting assessment history: $e');
      rethrow;
    }
  }

  /// ✅ Get assessment count
  Future<int> getAssessmentCount(String studyId) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'assessments',
        where: 'study_id = ?',
        whereArgs: [studyId],
      );
      print('📊 Assessment count for $studyId: ${results.length}');
      return results.length;
    } catch (e) {
      print('❌ Error counting assessments: $e');
      return 0;
    }
  }

  /// ✅ Check if today’s assessment exists
  Future<bool> hasTodayAssessment(String studyId) async {
    final todayAssessment = await getTodayAssessment(studyId);
    return todayAssessment != null;
  }

  /// Get recent assessments from last N days
  Future<List<AssessmentModel>> getRecentAssessments(
      String studyId, {
        int days = 7,
      }) async {
    try {
      final db = await _databaseService.database;
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: days));

      final results = await db.query(
        'assessments',
        where: 'study_id = ? AND timestamp >= ?',
        whereArgs: [studyId, startDate.toIso8601String()],
        orderBy: 'timestamp DESC',
      );

      return results.map((map) => AssessmentModel.fromMap(map)).toList();
    } catch (e) {
      print('❌ Error getting recent assessments: $e');
      rethrow;
    }
  }

  /// Get average NRS and VAS scores
  Future<Map<String, double>> getAverageScores(String studyId) async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'assessments',
        where: 'study_id = ?',
        whereArgs: [studyId],
      );

      if (results.isEmpty) {
        return {'nrs': 0.0, 'vas': 0.0};
      }

      double totalNrs = 0;
      double totalVas = 0;

      for (var map in results) {
        totalNrs += (map['nrs_score'] as int).toDouble();
        totalVas += (map['vas_score'] as int).toDouble();
      }

      return {
        'nrs': totalNrs / results.length,
        'vas': totalVas / results.length,
      };
    } catch (e) {
      print('❌ Error calculating averages: $e');
      return {'nrs': 0.0, 'vas': 0.0};
    }
  }

  /// Delete single assessment by ID
  Future<void> deleteAssessment(String assessmentId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'assessments',
        where: 'id = ?',
        whereArgs: [assessmentId],
      );
      print('🗑️ Assessment deleted: $assessmentId');
    } catch (e) {
      print('❌ Error deleting assessment: $e');
      rethrow;
    }
  }

  /// Delete all assessments for a user
  Future<void> deleteAllAssessments(String studyId) async {
    try {
      final db = await _databaseService.database;
      await db.delete(
        'assessments',
        where: 'study_id = ?',
        whereArgs: [studyId],
      );
      print('🗑️ All assessments deleted for $studyId');
    } catch (e) {
      print('❌ Error deleting assessments: $e');
      rethrow;
    }
  }
}