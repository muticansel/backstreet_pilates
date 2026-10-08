import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../auth/data/auth_gateway.dart';
import '../../auth/pages/login_page.dart';
import '../data/account_role_resolver.dart';

class PendingApprovalPage extends StatefulWidget {
  const PendingApprovalPage({
    super.key,
    required this.auth,
    required this.roles,
    required this.status,
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final AccountApprovalStatus status;

  @override
  State<PendingApprovalPage> createState() => _PendingApprovalPageState();
}

class _PendingApprovalPageState extends State<PendingApprovalPage> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    await widget.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => LoginPage(auth: widget.auth, roles: widget.roles),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final waitingForEmail =
        widget.status == AccountApprovalStatus.awaitingEmailConfirmation;
    final inactive = widget.status == AccountApprovalStatus.inactive;
    final titleKey = inactive
        ? 'accountInactiveTitle'
        : waitingForEmail
            ? 'confirmEmailTitle'
            : 'approvalPendingTitle';
    final detailKey = inactive
        ? 'accountInactiveDetail'
        : waitingForEmail
            ? 'confirmEmailDetail'
            : 'approvalPendingDetail';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Icon(Icons.spa_outlined, color: AppTheme.sage, size: 28),
                SizedBox(width: 10),
                Text('Backstreet Pilates',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5)),
              ]),
              const Spacer(),
              Icon(
                inactive ? Icons.lock_outline : Icons.hourglass_top_outlined,
                color: AppTheme.sage,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(strings.text(titleKey),
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 12),
              Text(strings.text(detailKey),
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: _signingOut ? null : _signOut,
                child: Text(strings.text('signOut')),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
