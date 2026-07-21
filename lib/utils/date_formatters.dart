class DateFormatters {
  DateFormatters._();

  static String chatPreview(DateTime? time, {DateTime? now}) {
    if (time == null) return '';
    final current = now ?? DateTime.now();
    final local = time.toLocal();
    final today = DateTime(current.year, current.month, current.day);
    final messageDay = DateTime(local.year, local.month, local.day);
    final dayDiff = today.difference(messageDay).inDays;

    if (dayDiff == 0) return _clock(local);
    if (dayDiff == 1) return 'Yesterday';
    if (dayDiff < 7 && dayDiff > 1) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[local.weekday - 1];
    }
    return '${local.month}/${local.day}/${local.year}';
  }

  static String _clock(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final ampm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }
}
