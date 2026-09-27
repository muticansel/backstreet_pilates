import 'package:flutter/material.dart';

import '../../account/data/account_role_resolver.dart';
import '../../account/pages/account_home_page.dart';
import '../../purchases/data/purchase_gateway.dart';
import '../data/auth_gateway.dart';
import '../validation/auth_validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/password_field.dart';
import 'signup_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage(
      {super.key,
      required this.auth,
      required this.roles,
      this.purchases = const UnconfiguredPurchaseGateway(),
      this.adminPurchases = const UnconfiguredAdminPurchaseGateway()});

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final AdminPurchaseGateway adminPurchases;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
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
      await widget.auth
          .signIn(email: _email.text.trim(), password: _password.text);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => AccountHomePage(
              auth: widget.auth,
              roles: widget.roles,
              purchases: widget.purchases,
              adminPurchases: widget.adminPurchases),
        ),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
              if (_errorMessage != null) ...[
                Text(_errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 18),
              ],
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
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'Logging in…' : 'Log in'),
              ),
              const SizedBox(height: 20),
              const Text('New to Backstreet Pilates?',
                  textAlign: TextAlign.center),
              TextButton(
                onPressed: () {
                  _password.clear();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => SignupPage(
                        auth: widget.auth,
                        roles: widget.roles,
                        purchases: widget.purchases,
                        adminPurchases: widget.adminPurchases),
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
