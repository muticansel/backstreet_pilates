import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_snack_bars.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _password.dispose();
    _confirmation.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _password.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBars.success(
            AppLocalizations.of(context).text('passwordChanged')),
      );
      Navigator.pop(context);
    } on AuthException catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.terracotta,
          content:
              Text(error.message, style: const TextStyle(color: Colors.white)),
        ));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context).text('changePassword'))),
        body: SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(AppLocalizations.of(context)
                            .text('chooseNewPassword')),
                        const SizedBox(height: 24),
                        TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)
                                    .text('newPassword')),
                            validator: (value) =>
                                value == null || value.length < 8
                                    ? AppLocalizations.of(context)
                                        .text('enterEightCharacters')
                                    : null),
                        const SizedBox(height: 18),
                        TextFormField(
                            controller: _confirmation,
                            obscureText: true,
                            decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)
                                    .text('confirmNewPassword')),
                            validator: (value) => value != _password.text
                                ? AppLocalizations.of(context)
                                    .text('passwordsDoNotMatch')
                                : null),
                        const SizedBox(height: 28),
                        FilledButton(
                            onPressed: _saving ? null : _save,
                            child: Text(AppLocalizations.of(context)
                                .text(_saving ? 'saving' : 'changePassword'))),
                      ]),
                ))),
      );
}
