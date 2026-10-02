import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_gateway.dart';

class SupabaseAuthGateway implements AuthGateway {
  SupabaseAuthGateway(this._client);

  final GoTrueClient _client;

  static const _confirmationRedirect = 'backstreetpilates://login-callback/';

  @override
  Future<bool> hasActiveSession() async => _client.currentSession != null;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure(
          'Unable to reach the account service. Try again.');
    }
  }

  @override
  Future<SignupResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.signUp(
        email: email,
        password: password,
        emailRedirectTo: _confirmationRedirect,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'display_name': '$firstName $lastName',
        },
      );
      return response.session == null
          ? SignupResult.confirmationRequired
          : SignupResult.signedIn;
    } on AuthException catch (error) {
      throw AuthFailure(_messageFor(error));
    } catch (_) {
      throw const AuthFailure('Unable to create the account. Try again.');
    }
  }

  @override
  Future<void> signOut() => _client.signOut();

  String _messageFor(AuthException error) {
    if (error.statusCode == '400') {
      return 'Check your email address and password, then try again.';
    }
    if (error.statusCode == '429') {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'We could not complete that request. Try again.';
  }
}
