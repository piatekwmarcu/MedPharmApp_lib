// ============================================================================
// MAIN.DART - App Entry Point
// ============================================================================
// Students: This file sets up the entire app.
// Study this carefully to understand how everything connects:
//
// 1. Database initialization
// 2. Provider setup (dependency injection)
// 3. Theme configuration
// 4. Routes configuration
//
// This file is COMPLETE - you don't need to modify it (for now).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core services
import 'core/services/database_service.dart';

// Authentication feature
import 'features/authentication/services/auth_service.dart';
import 'features/authentication/providers/auth_provider.dart';

// Assessment feature (Phase 2)
import 'features/assessment/services/assessment_service.dart';
import 'features/assessment/providers/assessment_provider.dart';

// Gamification feature (Phase 3)
import 'features/gamification/services/gamification_service.dart';
import 'features/gamification/providers/gamification_provider.dart';

// Sync feature (Phase 4)
import 'core/network/api_client.dart';
import 'features/sync/services/sync_service.dart';
import 'features/sync/services/network_service.dart';
import 'features/sync/providers/sync_provider.dart';

// App configuration
import 'app/theme.dart';
import 'app/routes.dart';

void main() async {
  // ========================================================================
  // STEP 1: Initialize Flutter
  // ========================================================================
  // This ensures Flutter is ready before we do async operations
  // Required when doing async work before runApp()
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 Starting MedPharm Pain Assessment App...');

  // ========================================================================
  // STEP 2: Initialize Database
  // ========================================================================
  // Create DatabaseService instance (singleton)
  final databaseService = DatabaseService();

  // Force database initialization before app starts
  // This creates all tables if database doesn't exist
  await databaseService.database;
  print('✅ Database initialized');

  // ========================================================================
  // STEP 3: Run App
  // ========================================================================
  runApp(MedPharmApp(databaseService: databaseService));
}

/// Main application widget
///
/// This widget sets up:
/// - Providers (state management and dependency injection)
/// - Theme
/// - Routes
class MedPharmApp extends StatelessWidget {
  final DatabaseService databaseService;

  const MedPharmApp({
    Key? key,
    required this.databaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ========================================================================
    // MULTI-PROVIDER SETUP
    // ========================================================================
    // MultiProvider allows us to provide multiple providers to the widget tree
    //
    // There are two types of providers here:
    // 1. Provider - For services (doesn't change)
    // 2. ChangeNotifierProvider - For state that changes and notifies UI
    return MultiProvider(
      providers: [
        // ====================================================================
        // SERVICES (Don't change, just provide access to them)
        // ====================================================================

        // 1. Database Service
        // Provided as a value (already created)
        Provider<DatabaseService>.value(
          value: databaseService,
        ),

        // 2. Authentication Service
        // Created using the database service
        // Uses Provider because AuthService doesn't extend ChangeNotifier
        Provider<AuthService>(
          create: (context) => AuthService(
            context.read<DatabaseService>(),  // Get database service
          ),
        ),

        // 3. Assessment Service (Phase 2)
        Provider<AssessmentService>(
          create: (context) => AssessmentService(
            context.read<DatabaseService>(),
          ),
        ),

        // ====================================================================
        // STATE PROVIDERS (Change and notify UI)
        // ====================================================================

        // 1. Authentication Provider
        // Uses ChangeNotifierProvider because AuthProvider extends ChangeNotifier
        // This provider manages authentication state
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),  // Get auth service
          ),
        ),

        // 2. Assessment Provider (Phase 2)
        ChangeNotifierProvider<AssessmentProvider>(
          create: (context) => AssessmentProvider(
            context.read<AssessmentService>(),
          ),
        ),

        // 3. Gamification Service (Phase 3)
        Provider<GamificationService>(
          create: (context) => GamificationService(
            context.read<DatabaseService>(),
            context.read<AssessmentService>(),
          ),
        ),

        // 4. Gamification Provider (Phase 3)
        ChangeNotifierProvider<GamificationProvider>(
          create: (context) => GamificationProvider(
            context.read<GamificationService>(),
          ),
        ),

        // 5. API Client (Phase 4)
        Provider<ApiClient>(
          create: (context) => ApiClient(),
        ),

        // 6. Network Service (Phase 4)
        Provider<NetworkService>(
          create: (context) => NetworkService(),
        ),

        // 7. Sync Service (Phase 4)
        Provider<SyncService>(
          create: (context) => SyncService(
            context.read<DatabaseService>(),
            context.read<ApiClient>(),
          ),
        ),

        // 8. Sync Provider (Phase 4)
        ChangeNotifierProvider<SyncProvider>(
          create: (context) => SyncProvider(
            context.read<SyncService>(),
            context.read<NetworkService>(),
          ),
        ),
      ],

      // ======================================================================
      // MATERIAL APP
      // ======================================================================
      child: MaterialApp(
        // App title (shown in task manager)
        title: 'MedPharm Pain Assessment',

        // Theme
        theme: AppTheme.lightTheme,

        // Remove debug banner
        debugShowCheckedModeBanner: false,

        // Routes
        routes: AppRoutes.routes,
        initialRoute: AppRoutes.enrollment,
        onUnknownRoute: AppRoutes.onUnknownRoute,
      ),
    );
  }
}

// ============================================================================
// LEARNING NOTES:
// ============================================================================
//
// 1. What is WidgetsFlutterBinding.ensureInitialized()?
//    - Initializes Flutter framework
//    - Required before any async operations in main()
//    - Must be called before database, Firebase, etc.
//
// 2. Why is main() async?
//    - We need to initialize database before app starts
//    - Database initialization is async (takes time)
//    - await ensures database is ready before showing UI
//
// 3. What is MultiProvider?
//    - Provides multiple providers to the widget tree
//    - Better than nesting many Providers
//    - All child widgets can access these providers
//
// 4. What's the difference between Provider and ChangeNotifierProvider?
//    - Provider: For objects that don't change (services)
//    - ChangeNotifierProvider: For objects that change and notify listeners
//    - Use ChangeNotifierProvider for state management
//
// 5. What is context.read()?
//    - Gets a provider from the tree
//    - Doesn't listen for changes
//    - Used here to inject dependencies
//
// 6. How does dependency injection work here?
//    - DatabaseService created in main()
//    - AuthService receives DatabaseService
//    - AuthProvider receives AuthService
//    - This makes code modular and testable!
//
// 7. Why create services in Provider.create()?
//    - Lazy initialization (created only when first accessed)
//    - Access to BuildContext (can read other providers)
//    - Automatic disposal when no longer needed
//
// 8. What is initialRoute?
//    - The first screen shown when app starts
//    - Here it's AppRoutes.enrollment (enrollment screen)
//    - Can be changed to test different screens
//
// 9. What is onUnknownRoute?
//    - Called when navigating to a route that doesn't exist
//    - Shows a "Page Not Found" screen
//    - Prevents app from crashing on invalid routes
//
// 10. How do child widgets access these providers?
//     - context.read<AuthProvider>() - Get provider (no rebuild)
//     - context.watch<AuthProvider>() - Get provider and listen (rebuild on changes)
//     - Consumer<AuthProvider> - Widget that rebuilds on changes
//
// ============================================================================
//
// DEBUGGING TIPS:
// ============================================================================
//
// If you see "Could not find Provider<X>":
// - Check that provider is in MultiProvider list
// - Check that you're using correct type (AuthProvider vs AuthService)
// - Make sure you're inside MaterialApp (providers are above it)
//
// If database errors occur:
// - Check database_service.dart for table creation
// - Use databaseService.deleteDatabase() to start fresh (loses all data!)
// - Check that column names match between model and database
//
// If navigation doesn't work:
// - Check route name matches exactly (case-sensitive)
// - Check route is defined in AppRoutes.routes
// - Use AppRoutes.enrollment instead of '/enrollment' (prevents typos)
//
// ============================================================================
