import 'package:flutter_test/flutter_test.dart';

import 'package:foconoenem/core/utils/operating_hours.dart';

void main() {
  group('OperatingHours', () {
    test('returns true inside the default window', () {
      final morning = DateTime(2024, 5, 10, OperatingHours.startHour + 1);
      expect(OperatingHours.isOpen(morning), isTrue);
    });

    test('returns false outside the window', () {
      final overnight = DateTime(2024, 5, 10, OperatingHours.endHour + 1);
      expect(OperatingHours.isOpen(overnight), isFalse);
    });

    test('computes remaining duration until opening', () {
      final lateNight = DateTime(2024, 5, 10, 2);
      final remaining = OperatingHours.timeUntilOpen(lateNight);
      expect(remaining.inHours, OperatingHours.startHour - 2);
    });
  });
}
