import 'package:backstreet_pilates/features/admin/pages/today_operations_page.dart';
import 'package:backstreet_pilates/features/bookings/data/booking_gateway.dart';
import 'package:backstreet_pilates/features/purchases/data/purchase_gateway.dart';
import 'package:backstreet_pilates/l10n/app_localizations.dart';
import 'package:backstreet_pilates/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _testApp(AdminTodayOperations data) => AppLanguageScope(
      language: AppLanguage(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AdminTodayOperationsContent(
            data: data,
            bookings: const UnconfiguredAdminBookingGateway(),
            purchases: const UnconfiguredAdminPurchaseGateway(),
          ),
        ),
      ),
    );

AdminTodayOperations _operations({
  List<AdminTodayClass> classes = const [],
  List<AdminNoShow> noShows = const [],
  List<AdminPendingPayment> payments = const [],
}) =>
    AdminTodayOperations(
      classes: classes,
      noShows: noShows,
      endingPackages: const [],
      pendingPayments: payments,
    );

void main() {
  testWidgets('summarizes occupancy, no-shows and payment queue',
      (tester) async {
    await tester.pumpWidget(_testApp(_operations(
      classes: [
        AdminTodayClass(
          title: 'Morning Pilates',
          branchName: 'Oran',
          startsAt: DateTime(2026, 10, 14, 9),
          capacity: 6,
          bookedCount: 3,
        ),
      ],
      noShows: [
        AdminNoShow(
          memberName: 'Alex Taylor',
          title: 'Morning Pilates',
          branchName: 'Oran',
          startsAt: DateTime(2026, 10, 14, 9),
        ),
      ],
      payments: const [
        AdminPendingPayment(
            memberName: 'Alex Taylor',
            packageName: '8 classes',
            priceMinor: 500000),
        AdminPendingPayment(
            memberName: 'Sam Lee',
            packageName: '8 classes',
            priceMinor: 500000),
      ],
    )));
    await tester.pumpAndSettle();

    expect(find.text('AT A GLANCE'), findsOneWidget);
    expect(find.text('3 of 6 places filled'), findsOneWidget);
    expect(find.text('1 no-shows from 3 booked places'), findsOneWidget);
    expect(find.text('2 awaiting · ₺10.000'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pending-payment-tick-0')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('pending-payment-tick-1')), findsOneWidget);
    final occupancy = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('today-occupancy-progress')));
    expect(occupancy.value, 0.5);
    final noShow = tester.widget<LinearProgressIndicator>(
        find.byKey(const ValueKey('today-no-show-progress')));
    expect(noShow.value, 1 / 3);
  });

  testWidgets('renders safe empty summary charts', (tester) async {
    await tester.pumpWidget(_testApp(_operations()));
    await tester.pumpAndSettle();

    expect(find.text('0 of 0 places filled'), findsOneWidget);
    expect(find.text('0 no-shows from 0 booked places'), findsOneWidget);
    expect(find.text('0 awaiting · ₺0'), findsOneWidget);
    final occupancy = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('today-occupancy-progress')));
    expect(occupancy.value, 0);
  });
}
