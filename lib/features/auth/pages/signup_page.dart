import 'package:flutter/material.dart';

import '../../account/data/account_role_resolver.dart';
import '../../account/pages/account_home_page.dart';
import '../../purchases/data/purchase_gateway.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_gateway.dart';
import '../validation/auth_validators.dart';
import '../widgets/auth_layout.dart';
import '../widgets/password_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage(
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
            builder: (_) => AccountHomePage(
                auth: widget.auth,
                roles: widget.roles,
                purchases: widget.purchases,
                adminPurchases: widget.adminPurchases),
          ),
          (_) => false,
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) {
          final strings = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(strings.text('checkYourEmail')),
            content: Text(strings.text('emailConfirmation')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.text('backToLogin')),
              ),
            ],
          );
        },
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
    final strings = AppLocalizations.of(context);
    return AuthLayout(
      title: strings.text('startWithYou'),
      subtitle: strings.text('signupSubtitle'),
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
                decoration:
                    InputDecoration(labelText: strings.text('yourName')),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _email,
                validator: AuthValidators.email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                decoration:
                    InputDecoration(labelText: strings.text('emailAddress')),
              ),
              const SizedBox(height: 18),
              PasswordField(
                controller: _password,
                validator: AuthValidators.newPassword,
                label: strings.text('password'),
                isNewPassword: true,
                textInputAction: TextInputAction.next,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 18),
                child: Text(strings.text('useEightCharacters'),
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
                child: Text(strings.text(
                    _isSubmitting ? 'creatingAccount' : 'createAccountAction')),
              ),
              const SizedBox(height: 20),
              Text(strings.text('alreadyHaveAccount'),
                  textAlign: TextAlign.center),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(strings.text('backToLogin')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
