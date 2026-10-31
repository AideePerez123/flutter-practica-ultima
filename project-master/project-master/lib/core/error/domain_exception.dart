/// Domain-level error carrying a user presentable message.
///
/// Domain services and repositories throw this when a business rule is
/// violated, so the presentation layer can surface a consistent message.
class DomainException implements Exception {
  const DomainException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => 'DomainException(${code ?? '-'}): $message';
}

/// Well known business rule error codes.
class DomainErrorCodes {
  DomainErrorCodes._();

  static const String codeRequired = 'code_required';
  static const String codeDuplicated = 'code_duplicated';
  static const String nameRequired = 'name_required';
  static const String invalidPrice = 'invalid_price';
  static const String invalidQuantity = 'invalid_quantity';
  static const String invalidMinStock = 'invalid_min_stock';
  static const String insufficientStock = 'insufficient_stock';
  static const String justificationRequired = 'justification_required';
  static const String reasonRequired = 'reason_required';
  static const String productNotFound = 'product_not_found';
  static const String productHasMovements = 'product_has_movements';
}
