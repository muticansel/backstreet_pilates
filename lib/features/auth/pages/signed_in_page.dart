import 'package:flutter/material.dart';

import '../data/auth_gateway.dart';
import '../../../theme/app_theme.dart';
import 'login_page.dart';

class SignedInPage extends StatefulWidget {
  const SignedInPage({super.key, required this.auth});

  final AuthGateway auth;

  @override
  State<SignedInPage> createState() => _SignedInPageState();
}

class _SignedInPageState extends State<SignedInPage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => LoginPage(auth: widget.auth)),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.spa_outlined, size: 54, color: AppTheme.sage),
                const SizedBox(height: 24),
                Text('You’re signed in.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                const Text(
                  'Your member experience is the next page we’ll build.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: _signingOut ? null : _signOut,
                  child: Text(_signingOut ? 'Signing out…' : 'Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
