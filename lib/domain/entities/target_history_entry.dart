/// Domain entity representing a single row in the target_history table.
///
/// Plain Dart class (no code-gen) so that it is resolvable by
/// riverpod_generator at build time without needing to inspect
/// generated Drift files.
class TargetHistoryEntry {
  const TargetHistoryEntry({
    required this.id,
    required this.effectiveDate,
    required this.targetMl,
  });

  final int id;

  /// Date the target became effective, formatted as YYYY-MM-DD.
  final String effectiveDate;

  /// Target daily water intake in millilitres.
  final int targetMl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          effectiveDate == other.effectiveDate &&
          targetMl == other.targetMl;

  @override
  int get hashCode => Object.hash(id, effectiveDate, targetMl);

  @override
  String toString() =>
      'TargetHistoryEntry(id: $id, effectiveDate: $effectiveDate, targetMl: $targetMl)';
}
