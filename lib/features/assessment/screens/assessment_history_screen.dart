// ============================================================================
// ASSESSMENT HISTORY SCREEN - SCAFFOLDED FOR PHASE 2
// ============================================================================
// Students: This screen displays the user's assessment history.
//
// Phase 2 Learning Goals:
// - Work with lists in UI (ListView.builder)
// - Load data on screen init
// - Display data from Provider
// - Handle empty states
//
// Scaffolding Level: 60% (UI structure provided, data loading TODOs)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/assessment_provider.dart';
import '../models/assessment_model.dart';
import '../../authentication/providers/auth_provider.dart';

/// Assessment History Screen
///
/// Shows a list of all past assessments
/// with scores, dates, and pain levels
class AssessmentHistoryScreen extends StatefulWidget {
  const AssessmentHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AssessmentHistoryScreen> createState() =>
      _AssessmentHistoryScreenState();
}

class _AssessmentHistoryScreenState extends State<AssessmentHistoryScreen> {
  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  @override
  void initState() {
    super.initState();

    // Ładujemy dane po zbudowaniu ekranu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }


  // ========================================================================
  // TODO 2: IMPLEMENT LOAD HISTORY METHOD
  // ========================================================================

  /// Load assessment history from database
  ///
  /// TODO: Implement this method
  /// Hints:
  /// 1. Get AuthProvider to access current user
  /// 2. Get AssessmentProvider to load history
  /// 3. Get studyId from current user
  /// 4. Call assessmentProvider.loadAssessmentHistory(studyId)
  Future<void> _loadHistory() async {
    final authProvider = context.read<AuthProvider>();
    final assessmentProvider = context.read<AssessmentProvider>();

    final studyId = authProvider.currentUser?.studyId;
    if (studyId != null) {
      await assessmentProvider.refreshAssessments(studyId);
    }
  }

  // ========================================================================
  // UI BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ======================================================================
      // APP BAR
      // ======================================================================
      appBar: AppBar(
        title: const Text('Assessment History'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),

      // ======================================================================
      // BODY
      // ======================================================================
      body: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          // ==================================================================
          // LOADING STATE
          // ==================================================================
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ==================================================================
          // ERROR STATE
          // ==================================================================
          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadHistory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // ==================================================================
          // EMPTY STATE
          // ==================================================================
          if (provider.assessmentHistory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No assessments yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Complete your first assessment to see it here',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/assessment/nrs');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Assessment'),
                  ),
                ],
              ),
            );
          }

          // ==================================================================
          // LIST OF ASSESSMENTS
          // ==================================================================
          return RefreshIndicator(
            onRefresh: _loadHistory,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.assessmentHistory.length,
              itemBuilder: (context, index) {
                final assessment = provider.assessmentHistory[index];
                return _AssessmentCard(assessment: assessment);
              },
            ),
          );
        },
      ),

      // ======================================================================
      // FLOATING ACTION BUTTON
      // ======================================================================
      // TODO 3: Add FAB to create new assessment
      // Hint: Only show if user can submit today (check provider.canSubmitToday)
      // Pattern:
      // floatingActionButton: Consumer<AssessmentProvider>(
      //   builder: (context, provider, child) {
      //     if (!provider.canSubmitToday) return const SizedBox.shrink();
      //     return FloatingActionButton.extended(
      //       onPressed: () {
      //         Navigator.pushNamed(context, '/assessment/nrs');
      //       },
      //       icon: const Icon(Icons.add),
      //       label: const Text('New Assessment'),
      //     );
      //   },
      // ),
      floatingActionButton: Consumer<AssessmentProvider>(
        builder: (context, provider, child) {
          // Only show button if user hasn't submitted today
          if (!provider.canSubmitToday) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/assessment/nrs');
            },
            icon: const Icon(Icons.add),
            label: const Text('New Assessment'),
          );
        },
      ),
    );
  }
}

// ============================================================================
// ASSESSMENT CARD WIDGET
// ============================================================================

/// Card widget to display a single assessment
class _AssessmentCard extends StatelessWidget {
  final AssessmentModel assessment;

  const _AssessmentCard({required this.assessment});

  Color _getPainColor() {
    final score = assessment.nrsScore;
    if (score == 0) return Colors.green;
    if (score <= 3) return Colors.lightGreen;
    if (score <= 6) return Colors.orange;
    if (score <= 9) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _getPainColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _getPainColor(), width: 2),
          ),
          child: Center(
            child: Text(
              assessment.nrsScore.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getPainColor(),
              ),
            ),
          ),
        ),
        title: Text(
          assessment.painLevelDescription,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text('NRS: ${assessment.nrsScore}/10'),
            Text('VAS: ${assessment.vasScore}/100'),
            const SizedBox(height: 4),
            Text(
              '${assessment.formattedDate} at ${assessment.formattedTime}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: assessment.isTodayAssessment
            ? Chip(
                label: const Text(
                  'Today',
                  style: TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue.shade100,
              )
            : null,
      ),
    );
  }
}

// ============================================================================
// LEARNING NOTES:
// ============================================================================
//
// 1. Understanding ListView.builder:
//    - Efficiently builds list items on demand
//    - Only renders visible items (performance!)
//    - itemCount: Total number of items
//    - itemBuilder: Function that builds each item
//    - Returns widget for item at index
//
// 2. Why WidgetsBinding.instance.addPostFrameCallback()?
//    - initState() can't call Provider methods directly
//    - addPostFrameCallback() waits until after build completes
//    - Then safe to call context.read<Provider>()
//    - Common pattern for loading data on screen open
//
// 3. Multiple UI States Pattern:
//    - Loading: Show CircularProgressIndicator
//    - Error: Show error message with retry button
//    - Empty: Show "no data" message with action button
//    - Data: Show list of items
//    - Always handle all states for good UX!
//
// 4. Consumer vs context.read():
//    - Consumer: Listens to changes, rebuilds when state changes
//    - context.read(): One-time access, doesn't listen
//    - Use Consumer for displaying data
//    - Use context.read() for calling methods (buttons)
//
// 5. RefreshIndicator:
//    - Pull-to-refresh gesture
//    - onRefresh: Called when user pulls down
//    - Must return Future (async operation)
//    - Common mobile app pattern
//
// 6. FloatingActionButton.extended:
//    - FAB with icon AND text
//    - Positioned in bottom-right corner
//    - For primary action (create new assessment)
//    - Can be hidden with SizedBox.shrink()
//
// 7. Conditional Widget Rendering:
//    - if (!canSubmit) return SizedBox.shrink();
//    - SizedBox.shrink() = invisible, takes no space
//    - Better than using Visibility(visible: false)
//    - Cleaner code than ternary operators for complex widgets
//
// 8. Card and ListTile Pattern:
//    - Card: Material design card with shadow
//    - ListTile: Pre-styled layout (leading, title, subtitle, trailing)
//    - Perfect for list items
//    - Less code than custom layouts
//
// 9. Custom Widgets (_AssessmentCard):
//    - Private widget (starts with _)
//    - Keeps code organized
//    - Reusable component
//    - Easier to read build() method
//
// 10. Color-Coded Visual Feedback:
//     - Same color scheme as NRS/VAS screens
//     - Instant visual understanding of pain level
//     - User doesn't need to read numbers
//     - Good UX design principle
//
// ============================================================================
