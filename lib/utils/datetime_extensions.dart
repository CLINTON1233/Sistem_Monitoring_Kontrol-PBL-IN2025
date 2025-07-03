extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final date = DateTime(year, month, day);
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return ((daysDiff + firstDayOfYear.weekday - 1) / 7).floor() + 1;
  }
}
