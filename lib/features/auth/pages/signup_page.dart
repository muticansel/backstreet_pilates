import 'package:flutter/material.dart';

import '../data/auth_gateway.dart';
import '../validation/auth_validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/password_field.dart';
import '../../dashboard/dashboard_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key, required this.auth});

  final AuthGateway auth;

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final result = await widget.auth.signUp(
        displayName: _name.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      if (result == SignupResult.signedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
              builder: (_) => DashboardPage(auth: widget.auth)),
          (_) => false,
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Check your email'),
          content: const Text(
            'We sent a confirmation link to your email address. Confirm it, then return here to log in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to log in'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Start with you.',
      subtitle: 'A stronger, calmer everyday begins with one small step.',
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ...[
                Text(_errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 18),
              ],
              TextFormField(
                controller: _name,
                validator: AuthValidators.name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(labelText: 'Your name'),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _email,
                validator: AuthValidators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration: const InputDecoration(labelText: 'Email address'),
              ),
              const SizedBox(height: 18),
              PasswordField(
                controller: _password,
                validator: AuthValidators.newPassword,
                isNewPassword: true,
                textInputAction: TextInputAction.next,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 18),
                child: Text('Use at least 8 characters.',
                    style: TextStyle(fontSize: 12)),
              ),
              PasswordField(
                controller: _confirmation,
                validator: (value) =>
                    AuthValidators.confirmPassword(value, _password.text),
                label: 'Confirm password',
                isNewPassword: true,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(
                    _isSubmitting ? 'Creating account…' : 'Create account'),
              ),
              const SizedBox(height: 20),
              const Text('Already have an account?',
                  textAlign: TextAlign.center),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back to log in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
