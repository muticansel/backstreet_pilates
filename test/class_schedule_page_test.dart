import 'package:backstreet_pilates/features/admin/pages/class_schedule_page.dart';
import 'package:backstreet_pilates/features/bookings/data/booking_gateway.dart';
import 'package:backstreet_pilates/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ScheduleGateway extends UnconfiguredAdminBookingGateway {
  _ScheduleGateway(this.offer);

  final AdminFixedOffer offer;
  int updateCount = 0;

  @override
  Future<List<StudioBranch>> loadBranches() async =>
      const [StudioBranch(id: 'oran', name: 'Oran')];

  @override
  Future<List<AdminFixedOffer>> loadFixedOffers() async => [offer];

  @override
  Future<void> updateFixedOffer({
    required String offerId,
    required String name,
    required int priceMinor,
    required int capacity,
    required List<int> weekdays,
    required List<TimeOfDayValue> startTimes,
  }) async {
    updateCount++;
  }
}

void main() {
  testWidgets('series card opens its schedule details and saves edits',
      (tester) async {
    final gateway = _ScheduleGateway(AdminFixedOffer(
      id: 'offer-1',
      title: 'Morning Pilates',
      branchName: 'Oran',
      capacity: 3,
      priceMinor: 500000,
      totalClasses: 8,
      sessionsPerWeek: 2,
      startsOn: DateTime(2026, 10, 12),
      slots: const [
        FixedSeriesSlot(weekday: 1, time: TimeOfDayValue(hour: 9, minute: 0)),
        FixedSeriesSlot(weekday: 3, time: TimeOfDayValue(hour: 10, minute: 0)),
      ],
    ));
    await tester.pumpWidget(AppLanguageScope(
      language: AppLanguage(),
      child: MaterialApp(home: ClassSchedulePage(bookings: gateway)),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Morning Pilates'));
    await tester.pumpAndSettle();
    expect(find.text('PACKAGE DETAILS'), findsOneWidget);
    expect(find.text('Total classes: 8'), findsOneWidget);
    expect(find.text('Monday · 09:00'), findsOneWidget);

    await tester.tap(find.text('Edit package'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(gateway.updateCount, 1);
  });
}
