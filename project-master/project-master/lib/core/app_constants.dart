/// Application-wide constant values.
class AppConstants {
  AppConstants._();

  static const String appName = 'Inventario Inteligente';
  static const String databaseName = 'inventario_inteligente.db';
  static const int databaseVersion = 1;

  /// Default responsible person used until a local profile is configured.
  static const String defaultResponsible = 'Usuario local';

  static const String csvFileNamePrefix = 'productos';
  static const String movementsCsvFileNamePrefix = 'movimientos';
}
