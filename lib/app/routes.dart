// ============================================================================
// APP ROUTES - Navigation configuration
// ============================================================================
// Students: Add new routes here as you create more screens
//
// A route is a named path to a screen. Instead of:
//   Navigator.push(context, MaterialPageRoute(builder: (_) => MyScreen()))
//
// You can use:
//   Navigator.pushNamed(context, '/my-screen')
//
// This makes navigation cleaner and easier to manage.
// ============================================================================

import 'package:flutter/material.dart';
import '../features/authentication/screens/enrollment_screen.dart';
import '../features/authentication/screens/consent_screen.dart';
import '../features/authentication/screens/tutorial_screen.dart';

import '../features/assessment/screens/nrs_assessment_screen.dart';
import '../features/assessment/screens/vas_assessment_screen.dart';
import '../features/assessment/screens/assessment_history_screen.dart';

import '../features/gamification/screens/home_screen.dart';
import '../features/gamification/screens/badge_gallery_screen.dart';
import '../features/gamification/screens/progress_screen.dart';

/// App routes configuration
class AppRoutes {
  // ========================================================================
  // ROUTE NAMES (constants)
  // ========================================================================
  static const String enrollment = '/';
  static const String consent = '/consent';
  static const String tutorial = '/tutorial';
  static const String home = '/home';

  // Assessment routes (Phase 2)
  static const String assessmentNrs = '/assessment/nrs';
  static const String assessmentVas = '/assessment/vas';
  static const String assessmentHistory = '/assessment/history';

  // Gamification routes (Phase 3)
  static const String badges = '/badges';
  static const String progress = '/progress';

  // ========================================================================
  // ROUTES MAP
  // ========================================================================
  static Map<String, WidgetBuilder> get routes {
    return {
      // Authentication
      enrollment: (context) => const EnrollmentScreen(),
      consent: (context) => const ConsentScreen(),
      tutorial: (context) => const TutorialScreen(),

      // Home / Gamification
      home: (context) => const HomeScreen(),
      badges: (context) => const BadgeGalleryScreen(),
      progress: (context) => const ProgressScreen(),

      // Assessments
      assessmentNrs: (context) => const NrsAssessmentScreen(),
      assessmentVas: (context) => const VasAssessmentScreen(),
      assessmentHistory: (context) => const AssessmentHistoryScreen(),
    };
  }

  // ========================================================================
  // ON UNKNOWN ROUTE
  // ========================================================================
  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Text('Route ${settings.name} not found'),
        ),
      ),
    );
  }
}
