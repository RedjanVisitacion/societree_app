class PositionUtils {
  static int getPositionIndex(String pos) {
    final order = [
      'President',
      'Vice President',
      'Secretary',
      'Treasurer',
      'Auditor',
      'P.I.O.',
      'PIO',
      'Public Information Officer',
      'Representative',
    ];
    final i = order.indexWhere((e) => e.toLowerCase() == pos.toLowerCase());
    return i >= 0 ? i : 1000;
  }

  static List<String> sortPositions(List<String> positions) {
    final sorted = List<String>.from(positions);
    sorted.sort((a, b) => getPositionIndex(a).compareTo(getPositionIndex(b)));
    return sorted;
  }
}
