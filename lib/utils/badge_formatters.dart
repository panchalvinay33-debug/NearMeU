class BadgeFormatters {
  const BadgeFormatters._();

  static String unread(int count) {
    if (count <= 0) return '';
    return count > 99 ? '99+' : count.toString();
  }
}
