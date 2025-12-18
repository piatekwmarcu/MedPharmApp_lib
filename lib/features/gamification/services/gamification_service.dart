// ignore_for_file: avoid_print

import 'package:sqflite/sqflite.dart';
import '../../../core/services/database_service.dart';
import '../../assessment/services/assessment_service.dart';
import '../models/gamification_model.dart';

class GamificationService {
  final DatabaseService _databaseService;
  final AssessmentService _assessmentService;

  GamificationService(this._databaseService, this._assessmentService);

  Future<UserStatsModel> getOrCreateUserStats(String studyId) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'user_stats',
        where: 'study_id = ?',
        whereArgs: [studyId],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return UserStatsModel.fromMap(results.first);
      }

      final newStats = UserStatsModel(studyId: studyId);
      await db.insert('user_stats', newStats.toMap());
      return newStats;
    } catch (e) {
      print('Error getting/creating user stats: $e');
      rethrow;
    }
  }

  Future<void> saveUserStats(UserStatsModel stats) async {
    try {
      final db = await _databaseService.database;
      final updatedStats = stats.copyWith(updatedAt: DateTime.now());
      await db.insert(
        'user_stats',
        updatedStats.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error saving user stats: $e');
      rethrow;
    }
  }

  Future<int> awardPointsForAssessment({
    required String studyId,
    bool isEarly = false,
  }) async {
    try {
      final stats = await getOrCreateUserStats(studyId);
      int points = PointValues.assessmentComplete;

      if (stats.totalAssessments == 0) {
        points += PointValues.firstAssessment;
      }

      if (isEarly) {
        points += PointValues.earlyBonus;
      }

      final now = DateTime.now();
      final last = stats.lastAssessmentDate;
      int newStreak = 1;

      if (_isSameDay(now, last)) {
        newStreak = stats.currentStreak;
      } else if (_wasYesterday(last)) {
        newStreak = stats.currentStreak + 1;
      }

      final updatedStats = stats.copyWith(
        totalPoints: stats.totalPoints + points,
        currentStreak: newStreak,
        longestStreak: newStreak > stats.longestStreak ? newStreak : stats.longestStreak,
        totalAssessments: stats.totalAssessments + 1,
        earlyCompletions: isEarly ? stats.earlyCompletions + 1 : stats.earlyCompletions,
        lastAssessmentDate: now,
      );

      await saveUserStats(updatedStats);
      await checkAndAwardBadges(studyId);

      return points;
    } catch (e) {
      print('Error awarding points: $e');
      return 0;
    }
  }

  Future<List<BadgeModel>> checkAndAwardBadges(String studyId) async {
    try {
      final stats = await getOrCreateUserStats(studyId);
      final earned = await getEarnedBadges(studyId);
      final earnedTypes = earned.map((b) => b.badgeType).toSet();
      final newBadges = <BadgeModel>[];

      void tryAward(BadgeType type, bool condition) async {
        if (condition && !earnedTypes.contains(type)) {
          final badge = BadgeModel(studyId: studyId, badgeType: type);
          await saveBadge(badge);
          newBadges.add(badge);
        }
      }

      tryAward(BadgeType.firstAssessment, stats.totalAssessments >= 1);
      tryAward(BadgeType.tenthAssessment, stats.totalAssessments >= 10);
      tryAward(BadgeType.twentyFifthAssessment, stats.totalAssessments >= 25);
      tryAward(BadgeType.fiftiethAssessment, stats.totalAssessments >= 50);
      tryAward(BadgeType.hundredthAssessment, stats.totalAssessments >= 100);

      tryAward(BadgeType.streak3Day, stats.currentStreak >= 3);
      tryAward(BadgeType.streak7Day, stats.currentStreak >= 7);
      tryAward(BadgeType.streak14Day, stats.currentStreak >= 14);
      tryAward(BadgeType.streak30Day, stats.currentStreak >= 30);

      tryAward(BadgeType.earlyBird, stats.earlyCompletions >= 5);
      tryAward(BadgeType.dedicated, stats.longestStreak >= 30);

      final week = await getWeeklyCompletion(studyId);
      final all7 = week.values.length == 7 && week.values.every((v) => v);
      tryAward(BadgeType.perfectWeek, all7);

      return newBadges;
    } catch (e) {
      print('Error checking badges: $e');
      return [];
    }
  }

  Future<List<BadgeModel>> getEarnedBadges(String studyId) async {
    try {
      final db = await _databaseService.database;
      final results = await db.query(
        'user_badges',
        where: 'study_id = ?',
        whereArgs: [studyId],
        orderBy: 'earned_at DESC',
      );
      return results.map((r) => BadgeModel.fromMap(r)).toList();
    } catch (e) {
      print('Error getting badges: $e');
      return [];
    }
  }

  Future<void> saveBadge(BadgeModel badge) async {
    try {
      final db = await _databaseService.database;
      await db.insert(
        'user_badges',
        badge.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    } catch (e) {
      print('Error saving badge: $e');
      rethrow;
    }
  }

  Future<int> calculateCurrentStreak(String studyId) async {
    try {
      final history = await _assessmentService.getAssessmentHistory(studyId);
      if (history.isEmpty) return 0;

      int streak = 0;
      DateTime day = DateTime.now();

      while (true) {
        final found = history.any((a) => _isSameDay(a.timestamp, day));
        if (found) {
          streak++;
          day = day.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      return streak;
    } catch (e) {
      print('Error calculating streak: $e');
      return 0;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _wasYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _isSameDay(date, yesterday);
  }

  bool _isToday(DateTime date) {
    return _isSameDay(date, DateTime.now());
  }

  Future<double> getCompletionPercentage(String studyId) async {
    try {
      final stats = await getOrCreateUserStats(studyId);
      final daysSinceCreation = DateTime.now().difference(stats.createdAt).inDays + 1;
      if (daysSinceCreation <= 0) return 0.0;
      final percentage = (stats.totalAssessments / daysSinceCreation) * 100;
      return percentage.clamp(0.0, 100.0);
    } catch (e) {
      print('Error calculating completion %: $e');
      return 0.0;
    }
  }

  Future<Map<String, bool>> getWeeklyCompletion(String studyId) async {
    try {
      final assessments = await _assessmentService.getRecentAssessments(
        studyId,
        days: 7,
      );

      final completion = <String, bool>{};
      final today = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = today.subtract(Duration(days: i));
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final hasAssessment = assessments.any((a) => _isSameDay(a.timestamp, date));
        completion[dateKey] = hasAssessment;
      }

      return completion;
    } catch (e) {
      print('Error getting weekly completion: $e');
      return {};
    }
  }

  Future<void> deleteUserGamificationData(String studyId) async {
    try {
      final db = await _databaseService.database;
      await db.delete('user_stats', where: 'study_id = ?', whereArgs: [studyId]);
      await db.delete('user_badges', where: 'study_id = ?', whereArgs: [studyId]);
    } catch (e) {
      print('Error deleting gamification data: $e');
      rethrow;
    }
  }
}