// Client-side feedback only. A future auth service must validate independently.
class AuthValidators {
  static String? name(String? value) {
    return (value ?? '').trim().isEmpty ? 'Enter your name.' : null;
  }

  static String? email(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter your email address.';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? loginPassword(String? value) {
    return (value ?? '').isEmpty ? 'Enter your password.' : null;
  }

  static String? newPassword(String? value) {
    if ((value ?? '').length < 8) return 'Use at least 8 characters.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Confirm your password.';
    return value == password ? null : 'Passwords do not match.';
  }
}
