abstract final class Fmt {
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  /// e.g. "Apr 15"
  static String shortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

  /// e.g. "Apr 15 – Apr 30"
  static String dateRange(DateTime a, DateTime b) =>
      '${shortDate(a)} – ${shortDate(b)}';

  /// Relative due-date label with overdue/today awareness.
  static String dueLabel(DateTime due) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(due.year, due.month, due.day);
    final diff = target.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${diff.abs()}d overdue';
    if (diff < 7) return 'In ${diff}d';
    return shortDate(due);
  }

  /// Compact "time ago" — 2m, 5h, 3d, then a date.
  static String timeAgo(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return shortDate(ts);
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
