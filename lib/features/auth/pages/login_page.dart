import 'package:flutter/material.dart';

import '../validation/auth_validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/demo_feedback.dart';
import '../widgets/password_field.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    showDemoFeedback(context, isSignup: false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Welcome back.',
      subtitle: 'Take a breath. Make time for your practice.',
      child: AutofillGroup(
        onDisposeAction: AutofillContextAction.cancel,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                validator: AuthValidators.loginPassword,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),
              FilledButton(onPressed: _submit, child: const Text('Log in')),
              const SizedBox(height: 20),
              const Text('New to Backstreet Pilates?',
                  textAlign: TextAlign.center),
              TextButton(
                onPressed: () {
                  _password.clear();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const SignupPage(),
                  ));
                },
                child: const Text('Create an account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
