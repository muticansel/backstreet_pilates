import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:backstreet_pilates/app.dart';

void main() {
  testWidgets('login rejects empty fields and valid input opens demo feedback',
      (tester) async {
    await tester.pumpWidget(const PilatesApp());
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);

    await tester.enterText(
        find.byType(TextFormField).at(0), 'hello@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'practice123');
    await tester.ensureVisible(find.text('Log in'));
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Your form is ready'), findsOneWidget);
    expect(find.textContaining('does not sign you in'), findsOneWidget);
  });

  testWidgets('signup checks confirmation and returns to login',
      (tester) async {
    await tester.pumpWidget(const PilatesApp());
    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Alex');
    await tester.enterText(fields.at(1), 'alex@example.com');
    await tester.enterText(fields.at(2), 'practice123');
    await tester.enterText(fields.at(3), 'different');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);

    await tester.enterText(fields.at(3), 'practice123');
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.textContaining('does not create an account'), findsOneWidget);
    await tester.tap(find.text('Keep exploring'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Back to log in'));
    await tester.tap(find.text('Back to log in'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);
  });

  testWidgets('small screens scroll without layout errors', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const PilatesApp());
    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    expect(tester.takeException(), isNull);
  });
}
