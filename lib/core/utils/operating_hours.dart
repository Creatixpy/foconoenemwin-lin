class OperatingHours {
  static const int startHour = 7; // 07h em Brasília
  static const int endHour = 23; // 23h em Brasília

  static bool isOpen(DateTime dateTime) {
    final hour = dateTime.toLocal().hour;
    return hour >= startHour && hour < endHour;
  }

  static Duration timeUntilOpen(DateTime dateTime) {
    if (isOpen(dateTime)) {
      return Duration.zero;
    }
    final local = dateTime.toLocal();
    final nextOpening = DateTime(
      local.year,
      local.month,
      local.day + (local.hour >= endHour ? 1 : 0),
      startHour,
      0,
    );
    return nextOpening.difference(local);
  }
}
