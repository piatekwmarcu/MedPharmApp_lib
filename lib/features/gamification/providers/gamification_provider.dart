import 'package:flutter/foundation.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';

class GamificationProvider with ChangeNotifier {
  final GamificationService _gamificationService;

  GamificationProvider(this._gamificationService);

  UserStatsModel? _userStats;
  List<BadgeModel> _earnedBadges = [];
  List<BadgeModel> _newlyEarnedBadges = [];
  int _lastPointsAwarded = 0;
  bool _isLoading = false;
  String? _errorMessage;

  UserStatsModel? get userStats => _userStats;
  List<BadgeModel> get earnedBadges => _earnedBadges;
  List<BadgeModel> get newlyEarnedBadges => _newlyEarnedBadges;
  int get lastPointsAwarded => _lastPointsAwarded;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get currentLevel => _userStats?.level ?? 0;
  int get totalPoints => _userStats?.totalPoints ?? 0;
  int get currentStreak => _userStats?.currentStreak ?? 0;
  double get levelProgress => _userStats?.levelProgress ?? 0.0;
  int get pointsToNextLevel => _userStats?.pointsToNextLevel ?? 500;
  bool get hasNewBadges => _newlyEarnedBadges.isNotEmpty;

  Future<void> loadUserStats(String studyId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final stats = await _gamificationService.getOrCreateUserStats(studyId);
      _userStats = stats;

      final badges = await _gamificationService.getEarnedBadges(studyId);
      _earnedBadges = badges;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load gamification data';
      notifyListeners();
    }
  }

  // ✅ DONE - TODO 1
  Future<void> recordAssessmentCompletion({
    required String studyId,
    bool isEarly = false,
  }) async {
    try {
      _isLoading = true;
      _newlyEarnedBadges = [];
      notifyListeners();

      final awardedPoints = await _gamificationService.awardPointsForAssessment(
        studyId: studyId,
        isEarly: isEarly,
      );
      _lastPointsAwarded = awardedPoints;

      final newBadges = await _gamificationService.checkAndAwardBadges(studyId);
      _newlyEarnedBadges = newBadges;

      await loadUserStats(studyId); // refreshes userStats and earnedBadges

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to record assessment completion';
      notifyListeners();
    }
  }

  // ✅ DONE - TODO 2
  Future<void> refreshGamificationData(String studyId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _userStats = await _gamificationService.getOrCreateUserStats(studyId);
      _earnedBadges = await _gamificationService.getEarnedBadges(studyId);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to refresh gamification data';
      notifyListeners();
    }
  }

  // ✅ DONE - TODO 3
  void clearNewBadges() {
    _newlyEarnedBadges = [];
    _lastPointsAwarded = 0;
    notifyListeners();
  }

  Future<double> getCompletionPercentage(String studyId) async {
    try {
      return await _gamificationService.getCompletionPercentage(studyId);
    } catch (e) {
      return 0.0;
    }
  }

  Future<Map<String, bool>> getWeeklyCompletion(String studyId) async {
    try {
      return await _gamificationService.getWeeklyCompletion(studyId);
    } catch (e) {
      return {};
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void resetState() {
    _userStats = null;
    _earnedBadges = [];
    _newlyEarnedBadges = [];
    _lastPointsAwarded = 0;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  bool hasBadge(BadgeType badgeType) {
    return _earnedBadges.any((b) => b.badgeType == badgeType);
  }

  List<BadgeType> get unearnedBadgeTypes {
    final earnedTypes = _earnedBadges.map((b) => b.badgeType).toSet();
    return BadgeType.values.where((t) => !earnedTypes.contains(t)).toList();
  }
}
