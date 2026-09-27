import 'package:flutter/material.dart';

import '../validation/auth_validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/demo_feedback.dart';
import '../widgets/password_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showDemoFeedback(context, isSignup: true);
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
                  onPressed: _submit, child: const Text('Create account')),
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
