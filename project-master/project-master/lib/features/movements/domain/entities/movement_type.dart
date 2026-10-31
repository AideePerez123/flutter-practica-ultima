/// Types of stock movements supported by the system.
enum MovementType {
  entrada,
  salida,
  ajuste;

  String get label {
    switch (this) {
      case MovementType.entrada:
        return 'Entrada';
      case MovementType.salida:
        return 'Salida';
      case MovementType.ajuste:
        return 'Ajuste';
    }
  }

  /// Whether the movement increases stock.
  bool get increasesStock => this == MovementType.entrada;

  /// Whether the movement requires an explicit justification.
  bool get requiresJustification => this == MovementType.ajuste;

  static MovementType fromName(String name) {
    return MovementType.values.firstWhere(
      (type) => type.name == name,
      orElse: () => MovementType.entrada,
    );
  }
}
