/// Product category used to group inventory items.
class Category {
  const Category({
    this.id,
    required this.name,
    this.createdAt,
  });

  final int? id;
  final String name;
  final DateTime? createdAt;

  Category copyWith({int? id, String? name, DateTime? createdAt}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'Category(id: $id, name: $name)';
}
