/// A "grado" (grade level) catalog entry, e.g. "10°", "Grado 11".
/// Shared across teachers (§3: catalogs are shared, not per-teacher).
class AcademicLevelEntity {
  const AcademicLevelEntity({required this.id, required this.name, this.description});

  final int id;
  final String name;
  final String? description;
}
