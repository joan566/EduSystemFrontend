class AcademicPeriodEntity {
  const AcademicPeriodEntity({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final int id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;

  bool get isActive {
    final now = DateTime.now();
    return !now.isBefore(startDate) && !now.isAfter(endDate);
  }
}
