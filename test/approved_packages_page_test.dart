import 'package:backstreet_pilates/features/purchases/data/purchase_gateway.dart';
import 'package:backstreet_pilates/features/purchases/pages/approved_packages_page.dart';
import 'package:backstreet_pilates/l10n/app_localizations.dart';
import 'package:backstreet_pilates/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PackageGateway extends UnconfiguredPurchaseGateway {
  const _PackageGateway(this.packages);

  final List<ApprovedPackage> packages;

  @override
  Future<List<ApprovedPackage>> loadApprovedPackages() async => packages;
}

Widget _testApp(List<ApprovedPackage> packages) => AppLanguageScope(
      language: AppLanguage(),
      child: MaterialApp(
        theme: AppTheme.light,
        home: ApprovedPackagesPage(purchases: _PackageGateway(packages)),
      ),
    );

ApprovedPackage _package({
  required String id,
  required String status,
  required int totalCredits,
  required int remainingCredits,
  required DateTime startDate,
  required DateTime endDateExclusive,
}) =>
    ApprovedPackage(
      id: id,
      title: '$id package',
      branchName: 'Oran',
      status: status,
      totalCredits: totalCredits,
      remainingCredits: remainingCredits,
      startDate: startDate,
      endDateExclusive: endDateExclusive,
    );

void main() {
  testWidgets('shows the active package remaining-credit ring', (tester) async {
    final package = _package(
      id: 'active',
      status: 'active',
      totalCredits: 8,
      remainingCredits: 3,
      startDate: DateTime(2026, 10, 1),
      endDateExclusive: DateTime(2026, 11, 1),
    );

    await tester.pumpWidget(_testApp([package]));
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('classes\nremaining'), findsOneWidget);
    final progress = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('package-credit-progress-active')));
    expect(progress.value, 3 / 8);
  });

  testWidgets('shows a full available-credit ring for an upcoming package',
      (tester) async {
    final package = _package(
      id: 'upcoming',
      status: 'pending_start',
      totalCredits: 8,
      remainingCredits: 0,
      startDate: DateTime(2026, 11, 1),
      endDateExclusive: DateTime(2026, 12, 1),
    );

    await tester.pumpWidget(_testApp([package]));
    await tester.pumpAndSettle();

    expect(find.text('8'), findsOneWidget);
    expect(find.text('classes\navailable'), findsOneWidget);
    final progress = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('package-credit-progress-upcoming')));
    expect(progress.value, 1);
  });

  testWidgets('keeps the total-credit summary for an old package',
      (tester) async {
    final package = _package(
      id: 'old',
      status: 'expired',
      totalCredits: 8,
      remainingCredits: 0,
      startDate: DateTime(2026, 8, 1),
      endDateExclusive: DateTime(2026, 9, 1),
    );

    await tester.pumpWidget(_testApp([package]));
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('8 classes'), findsOneWidget);
  });

  testWidgets('handles packages with no total credits safely', (tester) async {
    final package = _package(
      id: 'zero',
      status: 'active',
      totalCredits: 0,
      remainingCredits: 0,
      startDate: DateTime(2026, 10, 1),
      endDateExclusive: DateTime(2026, 11, 1),
    );

    await tester.pumpWidget(_testApp([package]));
    await tester.pumpAndSettle();

    final progress = tester.widget<CircularProgressIndicator>(
        find.byKey(const ValueKey('package-credit-progress-zero')));
    expect(progress.value, 0);
  });
}
