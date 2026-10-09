import 'package:backstreet_pilates/features/admin/pages/private_lesson_calendar_page.dart';
import 'package:backstreet_pilates/features/bookings/data/booking_gateway.dart';
import 'package:backstreet_pilates/features/bookings/pages/private_lesson_booking_page.dart';
import 'package:backstreet_pilates/features/bookings/pages/my_private_lessons_page.dart';
import 'package:backstreet_pilates/l10n/app_localizations.dart';
import 'package:backstreet_pilates/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _CalendarGateway extends UnconfiguredAdminBookingGateway {
  const _CalendarGateway();

  @override
  Future<List<AdminPrivateLessonEntry>> loadPrivateLessonCalendar(
          DateTime weekStart) async =>
      [
        AdminPrivateLessonEntry(
          id: 'pending-request',
          isBlock: false,
          startsAt: DateTime(2026, 10, 10, 6),
          endsAt: DateTime(2026, 10, 10, 7),
          status: 'pending',
          memberName: 'Cansel Muti',
        ),
        AdminPrivateLessonEntry(
          id: 'rejected-request',
          isBlock: false,
          startsAt: DateTime(2026, 10, 10, 6),
          endsAt: DateTime(2026, 10, 10, 7),
          status: 'rejected',
          memberName: 'Cansel Muti',
        ),
      ];
}

class _PrivateLessonGateway extends UnconfiguredBookingGateway {
  const _PrivateLessonGateway();

  @override
  Future<List<PrivateLessonSlot>> loadPrivateLessonSlots(DateTime date) async =>
      [
        PrivateLessonSlot(
          startsAt: DateTime(date.year, date.month, date.day, 6),
          isAvailable: true,
          isDefaultClosed: false,
        ),
        PrivateLessonSlot(
          startsAt: DateTime(date.year, date.month, date.day, 7),
          isAvailable: false,
          isDefaultClosed: false,
        ),
      ];

  @override
  Future<List<MemberPrivateLesson>> loadMyPrivateLessons() async => [
        MemberPrivateLesson(
          id: 'approved-lesson',
          startsAt: DateTime(2026, 10, 10, 6),
          endsAt: DateTime(2026, 10, 10, 7),
          status: 'approved',
        ),
        MemberPrivateLesson(
          id: 'pending-lesson',
          startsAt: DateTime(2026, 10, 11, 9),
          endsAt: DateTime(2026, 10, 11, 10),
          status: 'pending',
        ),
      ];
}

Widget _testApp(Widget home) => AppLanguageScope(
      language: AppLanguage(),
      child: MaterialApp(theme: AppTheme.light, home: home),
    );

void main() {
  testWidgets('renders every private lesson request as a separate row',
      (tester) async {
    await tester.pumpWidget(_testApp(
        const PrivateLessonCalendarPage(bookings: _CalendarGateway())));
    await tester.pumpAndSettle();

    expect(find.text('Cansel Muti'), findsNWidgets(2));
    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(find.text('Declined'), findsOneWidget);
    expect(find.text('06:00 – 07:00'), findsNWidgets(2));
  });

  testWidgets('renders slots returned by the member slot gateway',
      (tester) async {
    await tester.pumpWidget(_testApp(
        const PrivateLessonBookingPage(bookings: _PrivateLessonGateway())));
    await tester.pumpAndSettle();

    expect(find.text('06:00 – 07:00'), findsOneWidget);
    expect(find.text('07:00 – 08:00'), findsOneWidget);
  });

  testWidgets('renders the member private lesson history', (tester) async {
    await tester.pumpWidget(_testApp(
        const MyPrivateLessonsPage(bookings: _PrivateLessonGateway())));
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(find.text('06:00 – 07:00'), findsOneWidget);
    expect(find.text('09:00 – 10:00'), findsOneWidget);
  });
}
