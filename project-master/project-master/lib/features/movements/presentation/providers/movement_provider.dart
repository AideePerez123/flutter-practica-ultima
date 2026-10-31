import 'package:flutter/foundation.dart';

import '../../domain/entities/movement.dart';
import '../../domain/repositories/movement_repository.dart';

/// Exposes movement history and registration to the UI.
class MovementProvider extends ChangeNotifier {
  MovementProvider(this._repository);

  final MovementRepository _repository;

  List<Movement> _movements = const [];
  bool _loading = false;
  Object? _error;
  MovementQuery _query = const MovementQuery();

  List<Movement> get movements => _movements;
  bool get isLoading => _loading;
  Object? get error => _error;
  MovementQuery get query => _query;

  Future<void> load({MovementQuery? query}) async {
    if (query != null) _query = query;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _movements = await _repository.getMovements(query: _query);
    } catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Applies a new filter set and reloads.
  Future<void> applyFilters(MovementQuery query) => load(query: query);

  Future<void> clearFilters() => load(query: const MovementQuery());

  Future<void> register(Movement movement) async {
    await _repository.registerMovement(movement);
  }

  Future<List<Movement>> forProduct(int productId) =>
      _repository.getMovements(query: MovementQuery(productId: productId));
}
