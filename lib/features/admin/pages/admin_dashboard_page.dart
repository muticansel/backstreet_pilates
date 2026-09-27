import 'package:flutter/material.dart';

import '../../account/data/account_role_resolver.dart';
import '../../auth/data/auth_gateway.dart';
import '../../auth/pages/login_page.dart';
import '../data/admin_dashboard_data.dart';
import '../../../theme/app_theme.dart';
import 'active_members_page.dart';
import 'manual_package_grant_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage(
      {super.key, required this.auth, required this.roles});

  final AuthGateway auth;
  final AccountRoleResolver roles;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _signingOut = false;
  final _data = AdminDashboardData.preview;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginPage(auth: widget.auth, roles: widget.roles),
        ),
        (_) => false,
      );
    } on AuthFailure catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_outlined,
                      color: AppTheme.sage, size: 28),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Backstreet Pilates',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: _signingOut ? null : _signOut,
                    icon: const Icon(Icons.logout_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              const Text(
                'ADMIN OVERVIEW',
                style: TextStyle(
                  color: AppTheme.sage,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your studio, at a glance.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Keep track of the month and support your members.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'THIS MONTH',
                      value: _formatTry(_data.monthlySalesMinor),
                      detail: '${_data.completedSales} completed sales',
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MetricCard(
                      label: 'ACTIVE MEMBERS',
                      value: '${_data.activeMembers}',
                      detail: 'Oran + İncek',
                      icon: Icons.people_outline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _SectionLabel(title: 'MEMBERSHIP MANAGEMENT'),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.group_outlined,
                title: 'Active member packages',
                detail: 'View every active package and remaining class rights.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActiveMembersPage(members: _data.members),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _AdminActionCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Record a cash payment',
                detail:
                    '${_data.cashPaymentsToRecord} cash payments awaiting entry.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ManualPackageGrantPage(members: _data.members),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reporting, members and cash-payment details are preview data until purchases and memberships are connected.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.sage),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTry(int amountMinor) {
    final amount = amountMinor ~/ 100;
    final digits = amount.toString();
    final groups = <String>[];
    for (var end = digits.length; end > 0; end -= 3) {
      groups.add(digits.substring(end - 3 < 0 ? 0 : end - 3, end));
    }
    return '₺${groups.reversed.join('.')}';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: AppTheme.sage,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8DED5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.sage),
            const SizedBox(height: 20),
            Text(label,
                style: const TextStyle(
                  color: AppTheme.sage,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                )),
            const SizedBox(height: 6),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(detail, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFFE3E9DD),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFCFDBC6),
                  foregroundColor: AppTheme.sage,
                  child: Icon(icon),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(detail),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: AppTheme.sage),
              ],
            ),
          ),
        ),
      );
}
