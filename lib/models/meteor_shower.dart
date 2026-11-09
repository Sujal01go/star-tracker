/// A seasonal meteor radiant. It is rendered only during its active date range.
class MeteorShower {
  final String id;
  final String name;
  final double radiantRa;
  final double radiantDec;
  final (int, int) activeStart;
  final (int, int) activeEnd;

  const MeteorShower({
    required this.id,
    required this.name,
    required this.radiantRa,
    required this.radiantDec,
    required this.activeStart,
    required this.activeEnd,
  });

  bool isActive(DateTime date) {
    final day = date.month * 100 + date.day;
    final start = activeStart.$1 * 100 + activeStart.$2;
    final end = activeEnd.$1 * 100 + activeEnd.$2;
    return start <= end ? day >= start && day <= end : day >= start || day <= end;
  }
}
