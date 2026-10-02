enum SignupResult { signedIn, confirmationRequired }

abstract interface class AuthGateway {
  /// Whether a previous, valid signed-in session is available on this device.
  ///
  /// Implementations must never expose or persist the user's password here.
  Future<bool> hasActiveSession();

  Future<void> signIn({required String email, required String password});

  Future<SignupResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  });

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}

class UnconfiguredAuthGateway implements AuthGateway {
  const UnconfiguredAuthGateway();

  static const _message =
      'Account service is not configured. Start the app with its Supabase settings.';

  @override
  Future<bool> hasActiveSession() async => false;

  @override
  Future<void> signIn({required String email, required String password}) {
    throw const AuthFailure(_message);
  }

  @override
  Future<SignupResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) {
    throw const AuthFailure(_message);
  }

  @override
  Future<void> signOut() async {}
}
