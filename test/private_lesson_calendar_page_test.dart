import 'package:backstreet_pilates/features/admin/pages/private_lesson_calendar_page.dart';
import 'package:backstreet_pilates/features/bookings/data/booking_gateway.dart';
import 'package:backstreet_pilates/features/bookings/pages/private_lesson_booking_page.dart';
import 'package:backstreet_pilates/features/bookings/pages/my_private_lessons_page.dart';
import 'package:backstreet_pilates/features/bookings/pages/upcoming_classes_page.dart';
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
  _PrivateLessonGateway();

  DateTime? requestedSlot;

  @override
  Future<List<PrivateLessonSlot>> loadPrivateLessonSlots(DateTime date) async =>
      [
        PrivateLessonSlot(
          startsAt: DateTime(date.year, date.month, date.day, 5),
          isAvailable: true,
          isDefaultClosed: false,
        ),
        PrivateLessonSlot(
          startsAt: DateTime(date.year, date.month, date.day, 21),
          isAvailable: false,
          isDefaultClosed: false,
        ),
        PrivateLessonSlot(
          startsAt: DateTime(date.year, date.month, date.day, 22),
          isAvailable: true,
          isDefaultClosed: false,
        ),
      ];

  @override
  Future<void> requestPrivateLesson(DateTime startsAt) async {
    requestedSlot = startsAt;
  }

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

  @override
  Future<bool> isPrivateLessonFeatureEnabled() async => true;
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
    final gateway = _PrivateLessonGateway();
    await tester
        .pumpWidget(_testApp(PrivateLessonBookingPage(bookings: gateway)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('private-lesson-daily-timeline')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('private-lesson-slot-05:00')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('private-lesson-slot-21:00')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('private-lesson-slot-22:00')), findsNothing);

    await tester.tap(find.text('Available times only'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('private-lesson-slot-05:00')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('private-lesson-slot-21:00')), findsNothing);

    await tester.tap(find.text('05:00'));
    await tester.pumpAndSettle();
    expect(gateway.requestedSlot?.hour, 5);
  });

  testWidgets('renders the member private lesson history', (tester) async {
    await tester.pumpWidget(
        _testApp(MyPrivateLessonsPage(bookings: _PrivateLessonGateway())));
    await tester.pumpAndSettle();

    expect(find.text('Approved'), findsOneWidget);
    expect(find.text('Awaiting approval'), findsOneWidget);
    expect(find.text('06:00 – 07:00'), findsOneWidget);
    expect(find.text('09:00 – 10:00'), findsOneWidget);
  });

  testWidgets('shows private lesson actions only when the feature is open',
      (tester) async {
    await tester.pumpWidget(_testApp(UpcomingClassesPage(
        key: ValueKey('private-lessons-closed'),
        bookings: UnconfiguredBookingGateway())));
    await tester.pumpAndSettle();

    expect(find.text('Book a private lesson'), findsNothing);
    expect(find.text('My private lessons'), findsNothing);

    await tester.pumpWidget(_testApp(UpcomingClassesPage(
        key: ValueKey('private-lessons-open'),
        bookings: _PrivateLessonGateway())));
    await tester.pumpAndSettle();

    expect(find.text('Book a private lesson'), findsOneWidget);
    expect(find.text('My private lessons'), findsOneWidget);
  });
}
