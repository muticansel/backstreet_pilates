import 'package:backstreet_pilates/features/admin/pages/attendance_page.dart';
import 'package:backstreet_pilates/features/bookings/data/booking_gateway.dart';
import 'package:backstreet_pilates/l10n/app_localizations.dart';
import 'package:backstreet_pilates/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _AttendanceGateway extends UnconfiguredAdminBookingGateway {
  const _AttendanceGateway(this.records);

  final List<AdminAttendanceRecord> records;

  @override
  Future<List<AdminAttendanceRecord>> loadPastAttendance() async => records;
}

Widget _testApp(List<AdminAttendanceRecord> records) => AppLanguageScope(
      language: AppLanguage(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: AttendancePage(bookings: _AttendanceGateway(records)),
      ),
    );

AdminAttendanceRecord _record({
  required String id,
  required String title,
  required DateTime startsAt,
}) =>
    AdminAttendanceRecord(
      bookingId: id,
      memberId: 'member-1',
      memberName: 'Alex Taylor',
      title: title,
      branchName: 'Oran',
      startsAt: startsAt,
      status: 'booked',
    );

void main() {
  testWidgets('shows attendance records from newest date to oldest',
      (tester) async {
    await tester.pumpWidget(_testApp([
      _record(
        id: 'oldest',
        title: 'Oldest class',
        startsAt: DateTime(2026, 10, 1, 9),
      ),
      _record(
        id: 'newest',
        title: 'Newest class',
        startsAt: DateTime(2026, 10, 20, 9),
      ),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('attendance-member-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attendance-member-member-1')));
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.text('Newest class')).dy,
      lessThan(tester.getTopLeft(find.text('Oldest class')).dy),
    );
  });

  testWidgets('keeps the list position after recording attendance',
      (tester) async {
    final records = List.generate(
      16,
      (index) => _record(
        id: 'booking-$index',
        title: 'Class $index',
        startsAt: DateTime(2026, 10, 1).add(Duration(days: index)),
      ),
    );
    await tester.pumpWidget(_testApp(records));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('attendance-member-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('attendance-member-member-1')));
    await tester.pumpAndSettle();

    final list = find.byKey(const PageStorageKey('attendance-list'));
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final attendedButton =
        find.byKey(const ValueKey('attendance-attended-booking-8'));
    await tester.scrollUntilVisible(attendedButton, 160,
        scrollable: scrollable);
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(scrollable).position.pixels;
    expect(before, greaterThan(0));

    await tester.tap(attendedButton);
    await tester.pumpAndSettle();

    expect(
      tester.state<ScrollableState>(scrollable).position.pixels,
      closeTo(before, 1),
    );
  });
}
