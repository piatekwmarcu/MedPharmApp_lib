import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../models/user_model.dart';

class AuthService {
  final DatabaseService _databaseService;

  AuthService(this._databaseService);

  // ===========================================================================
  // SAVE USER
  // ===========================================================================
  Future<int> saveUser(UserModel user) async {
    try {
      final db = await _databaseService.database;

      final id = await db.insert(
        'user_session',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ User saved with ID: $id');
      return id;
    } catch (e) {
      print('❌ Error saving user: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // GET CURRENT USER
  // ===========================================================================
  Future<UserModel?> getCurrentUser() async {
    try {
      final db = await _databaseService.database;

      final results = await db.query(
        'user_session',
        limit: 1,
      );

      if (results.isEmpty) {
        print('ℹ️ No user enrolled');
        return null;
      }

      final user = UserModel.fromMap(results.first);
      print('✅ Loaded user: ${user.studyId}');
      return user;
    } catch (e) {
      print('❌ Error getting current user: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // UPDATE CONSENT STATUS
  // ===========================================================================
  Future<int> updateConsentStatus(String studyId) async {
    try {
      final db = await _databaseService.database;

      final rows = await db.update(
        'user_session',
        {
          'consent_accepted': 1,
          'consent_accepted_at': DateTime.now().toIso8601String(),
        },
        where: 'study_id = ?',
        whereArgs: [studyId],
      );

      print('✅ Consent accepted for $studyId');
      return rows;
    } catch (e) {
      print('❌ Error updating consent: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // UPDATE TUTORIAL STATUS
  // ===========================================================================
  Future<int> updateTutorialStatus(String studyId) async {
    try {
      final db = await _databaseService.database;

      final rows = await db.update(
        'user_session',
        {'tutorial_completed': 1},
        where: 'study_id = ?',
        whereArgs: [studyId],
      );

      print('✅ Tutorial completed for $studyId');
      return rows;
    } catch (e) {
      print('❌ Error updating tutorial: $e');
      rethrow;
    }
  }

  // ===========================================================================
  // VALIDATE ENROLLMENT CODE
  // ===========================================================================
  Future<bool> validateEnrollmentCode(String code) async {
    if (code.isEmpty) return false;
    if (code.length < 8 || code.length > 12) return false;

    final alphanumeric = RegExp(r'^[a-zA-Z0-9]+$');
    if (!alphanumeric.hasMatch(code)) return false;

    print('✅ Enrollment code valid');
    return true;
  }

  // ===========================================================================
  // CHECK IF USER EXISTS
  // ===========================================================================
  Future<bool> isUserEnrolled() async {
    try {
      final db = await _databaseService.database;
      final results = await db.query('user_session');

      return results.isNotEmpty;
    } catch (e) {
      print('❌ Error checking enrollment: $e');
      return false;
    }
  }

  // ===========================================================================
  // GENERATE STUDY ID
  // ===========================================================================
  String generateStudyId(String enrollmentCode) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'STUDY_${enrollmentCode}_$timestamp';
  }

  // ===========================================================================
  // DELETE USER DATA (LOGOUT)
  // ===========================================================================
  Future<void> deleteUserData() async {
    final db = await _databaseService.database;
    await db.delete('user_session');
    print('🗑️ User data deleted');
  }
}
