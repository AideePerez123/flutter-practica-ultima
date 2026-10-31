import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../app_constants.dart';
import 'database_schema.dart';

/// Opens and configures the application SQLite database.
///
/// [databaseFactoryOverride] and [pathOverride] allow tests to use an
/// in-memory database instead of the on-device one.
class AppDatabase {
  AppDatabase({this.databaseFactoryOverride, this.pathOverride});

  final DatabaseFactory? databaseFactoryOverride;
  final String? pathOverride;

  Database? _database;

  /// Returns the database instance, opening it on first use.
  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    final factory = databaseFactoryOverride ?? databaseFactory;
    final path = pathOverride ??
        p.join(await factory.getDatabasesPath(), AppConstants.databaseName);

    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: AppConstants.databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: DatabaseSchema.create,
      ),
    );
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
