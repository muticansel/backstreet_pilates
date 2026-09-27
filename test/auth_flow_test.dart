import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:backstreet_pilates/app.dart';
import 'package:backstreet_pilates/features/auth/data/auth_gateway.dart';

class FakeAuthGateway implements AuthGateway {
  FakeAuthGateway({this.signUpResult = SignupResult.confirmationRequired});

  final SignupResult signUpResult;
  AuthFailure? signInFailure;
  AuthFailure? signUpFailure;
  int signOutCount = 0;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (signInFailure != null) throw signInFailure!;
  }

  @override
  Future<SignupResult> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (signUpFailure != null) throw signUpFailure!;
    return signUpResult;
  }

  @override
  Future<void> signOut() async => signOutCount++;
}

void main() {
  testWidgets(
      'login rejects empty fields and valid input opens signed-in state',
      (tester) async {
    await tester.pumpWidget(PilatesApp(auth: FakeAuthGateway()));
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
    expect(find.text('You’re signed in.'), findsOneWidget);
  });

  testWidgets('signup checks confirmation and returns to login',
      (tester) async {
    await tester.pumpWidget(PilatesApp(auth: FakeAuthGateway()));
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
    expect(find.text('Check your email'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Back to log in'),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);
  });

  testWidgets('small screens scroll without layout errors', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PilatesApp(auth: FakeAuthGateway()));
    await tester.ensureVisible(find.text('Create an account'));
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create account'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('auth failures stay on login and show a message', (tester) async {
    final auth = FakeAuthGateway()
      ..signInFailure = const AuthFailure('Check your details and try again.');
    await tester.pumpWidget(PilatesApp(auth: auth));
    await tester.enterText(
        find.byType(TextFormField).at(0), 'hello@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'practice123');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Check your details and try again.'), findsOneWidget);
    expect(find.text('Welcome back.'), findsOneWidget);
  });
}
