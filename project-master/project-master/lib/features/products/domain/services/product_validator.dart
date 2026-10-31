import '../../../../core/error/domain_exception.dart';
import '../entities/product.dart';

/// Validates product data before it reaches the repository.
class ProductValidator {
  const ProductValidator();

  void validate(Product product) {
    if (product.code.trim().isEmpty) {
      throw const DomainException(
        'El código único es obligatorio.',
        code: DomainErrorCodes.codeRequired,
      );
    }
    if (product.name.trim().isEmpty) {
      throw const DomainException(
        'El nombre del producto es obligatorio.',
        code: DomainErrorCodes.nameRequired,
      );
    }
    if (product.purchasePrice < 0 || product.salePrice < 0) {
      throw const DomainException(
        'Los precios no pueden ser negativos.',
        code: DomainErrorCodes.invalidPrice,
      );
    }
    if (product.minStock < 0) {
      throw const DomainException(
        'El stock mínimo no puede ser negativo.',
        code: DomainErrorCodes.invalidMinStock,
      );
    }
  }
}
