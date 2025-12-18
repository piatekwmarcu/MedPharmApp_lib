// ============================================================================
// DATABASE SERVICE - FULLY IMPLEMENTED
// ============================================================================
// Students: This file is COMPLETE. You don't need to modify it.
// Study this code to understand how the Singleton pattern works
// and how to set up SQLite database in Flutter.
//
// This service provides a single shared instance of the database
// that can be used throughout the app.
// ============================================================================

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// DatabaseService using Singleton pattern
///
/// The Singleton pattern ensures only ONE instance of the database exists.
/// This is important because:
/// 1. Multiple database connections can cause conflicts
/// 2. Database operations are expensive
/// 3. Shared instance improves performance
///
/// Usage in other classes:
/// ```dart
/// final dbService = DatabaseService();
/// final db = await dbService.database;
/// ```
class DatabaseService {
  // Private constructor - prevents creating instances with DatabaseService()
  DatabaseService._internal();

  // The single instance (singleton)
  static final DatabaseService _instance = DatabaseService._internal();

  // Factory constructor - always returns the same instance
  factory DatabaseService() {
    return _instance;
  }

  // The database instance
  static Database? _database;

  /// Get the database instance
  /// If it doesn't exist yet, create it (lazy initialization)
  Future<Database> get database async {
    // If database already exists, return it
    if (_database != null) {
      return _database!;
    }

    // Otherwise, initialize it first
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  /// This creates the database file and all tables
  Future<Database> _initDatabase() async {
    // Get the default databases location
    final dbPath = await getDatabasesPath();

    // Create the database file path
    final path = join(dbPath, 'medpharm.db');

    // Open the database (creates it if it doesn't exist)
    return await openDatabase(
      path,
      version: 1,  // Database version (increment when you change schema)
      onCreate: _onCreate,  // Called when database is created for first time
      onUpgrade: _onUpgrade,  // Called when version number increases
    );
  }

  /// Create all database tables
  /// This is called ONLY when the database is created for the first time
  Future<void> _onCreate(Database db, int version) async {
    print('📊 Creating database tables...');

    // ========================================================================
    // TABLE 1: user_session
    // Stores information about the enrolled user
    // ========================================================================
    await db.execute('''
      CREATE TABLE user_session (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        study_id TEXT NOT NULL UNIQUE,
        enrollment_code TEXT NOT NULL,
        enrolled_at TEXT NOT NULL,
        consent_accepted INTEGER DEFAULT 0,
        consent_accepted_at TEXT,
        tutorial_completed INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========================================================================
    // TABLE 2: assessments
    // Stores daily pain assessment data
    // ========================================================================
    await db.execute('''
      CREATE TABLE assessments (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        nrs_score INTEGER NOT NULL CHECK(nrs_score >= 0 AND nrs_score <= 10),
        vas_score INTEGER NOT NULL CHECK(vas_score >= 0 AND vas_score <= 100),
        timestamp TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Add index for faster queries by timestamp
    await db.execute('''
      CREATE INDEX idx_assessments_timestamp
      ON assessments(timestamp)
    ''');

    // Add index for finding unsynced assessments quickly
    await db.execute('''
      CREATE INDEX idx_assessments_synced
      ON assessments(is_synced)
    ''');

    // ========================================================================
    // TABLE 3: gamification_progress
    // Stores user's points, level, and achievement progress
    // ========================================================================
    await db.execute('''
      CREATE TABLE gamification_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        study_id TEXT NOT NULL UNIQUE,
        total_points INTEGER DEFAULT 0,
        current_level INTEGER DEFAULT 1,
        assessments_completed INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_assessment_date TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // ========================================================================
    // TABLE 4: sync_queue (Phase 4 - Offline-First Sync)
    // Tracks all data that needs to be synced to the server
    // ========================================================================
    await db.execute('''
      CREATE TABLE sync_queue (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        item_type TEXT NOT NULL,
        data_id TEXT NOT NULL,
        payload TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        retry_count INTEGER DEFAULT 0,
        last_error TEXT,
        created_at TEXT NOT NULL,
        last_attempt_at TEXT,
        synced_at TEXT,
        deadline TEXT NOT NULL
      )
    ''');

    // Add index for faster queries by status
    await db.execute('''
      CREATE INDEX idx_sync_queue_status
      ON sync_queue(status)
    ''');

    // Add index for deadline tracking
    await db.execute('''
      CREATE INDEX idx_sync_queue_deadline
      ON sync_queue(deadline)
    ''');

    // ========================================================================
    // TABLE 5: user_stats (Phase 3 - Gamification)
    // Stores user's points, streaks, and progress
    // ========================================================================
    await db.execute('''
      CREATE TABLE user_stats (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL UNIQUE,
        total_points INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        total_assessments INTEGER DEFAULT 0,
        early_completions INTEGER DEFAULT 0,
        last_assessment_date TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // ========================================================================
    // TABLE 6: user_badges (Phase 3 - Gamification)
    // Stores badges earned by users
    // ========================================================================
    await db.execute('''
      CREATE TABLE user_badges (
        id TEXT PRIMARY KEY,
        study_id TEXT NOT NULL,
        badge_type TEXT NOT NULL,
        earned_at TEXT NOT NULL,
        UNIQUE(study_id, badge_type)
      )
    ''');

    // Add index for faster badge queries
    await db.execute('''
      CREATE INDEX idx_user_badges_study_id
      ON user_badges(study_id)
    ''');

    print('Database tables created successfully!');
  }

  /// Handle database upgrades
  /// This is called when you increase the version number
  ///
  /// Example: If you add a new column to a table later:
  /// 1. Change version from 1 to 2
  /// 2. Add migration code here
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('📊 Upgrading database from v$oldVersion to v$newVersion...');

    // Example migration (students will learn this later):
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE assessments ADD COLUMN new_field TEXT');
    // }

    print('✅ Database upgraded successfully!');
  }

  /// Close the database connection
  /// Call this when the app is closing (rarely needed)
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('🔒 Database closed');
  }

  /// Delete the database (useful for testing)
  /// WARNING: This will delete ALL data!
  Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medpharm.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    print('🗑️ Database deleted');
  }
}
