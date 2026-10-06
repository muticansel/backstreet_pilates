import 'package:flutter/material.dart';

import '../../account/data/account_role_resolver.dart';
import '../../auth/data/auth_gateway.dart';
import '../../auth/pages/login_page.dart';
import '../../bookings/data/booking_gateway.dart';
import '../../purchases/data/purchase_gateway.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../notifications/push_notification_service.dart';
import 'cash_purchase_requests_page.dart';
import 'admin_users_page.dart';
import 'attendance_page.dart';
import 'class_schedule_page.dart';
import 'today_operations_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage(
      {super.key,
      required this.auth,
      required this.roles,
      required this.purchases,
      required this.adminPurchases,
      required this.adminBookings});

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final AdminPurchaseGateway adminPurchases;
  final AdminBookingGateway adminBookings;

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _signingOut = false;
  late Future<AdminDashboardMetrics> _metrics;

  @override
  void initState() {
    super.initState();
    _metrics = widget.adminPurchases.loadDashboardMetrics();
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await PushNotificationService.instance.unregisterCurrentDevice();
      await widget.auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => LoginPage(
            auth: widget.auth,
            roles: widget.roles,
            purchases: widget.purchases,
            adminPurchases: widget.adminPurchases,
          ),
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
    final strings = AppLocalizations.of(context);
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
                    tooltip: strings.text('signOut'),
                    onPressed: _signingOut ? null : _signOut,
                    icon: const Icon(Icons.logout_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 34),
              Text(
                strings.text('adminOverview'),
                style: TextStyle(
                  color: AppTheme.sage,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                strings.text('studioAtGlance'),
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                strings.text('adminSubtitle'),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 28),
              FutureBuilder<AdminDashboardMetrics>(
                future: _metrics,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 154,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return TextButton.icon(
                      onPressed: () => setState(() => _metrics =
                          widget.adminPurchases.loadDashboardMetrics()),
                      icon: const Icon(Icons.refresh),
                      label:
                          const Text('Dashboard metrics could not be loaded.'),
                    );
                  }
                  final metrics = snapshot.data!;
                  return Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: strings.text('thisMonth'),
                          value: _formatTry(metrics.monthlySalesMinor),
                          detail: strings.text('completedSales').replaceAll(
                              '{count}', '${metrics.completedSales}'),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _MetricCard(
                          label: strings.text('activeMembers'),
                          value: '${metrics.activeMembers}',
                          detail: strings.text('oranAndIncek'),
                          icon: Icons.people_outline,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 14),
              _AdminActionCard(
                icon: Icons.today_outlined,
                title: strings.text('todayOperations'),
                detail: strings.text('todayOperationsDashboardDetail'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => TodayOperationsPage(
                    bookings: widget.adminBookings,
                    purchases: widget.adminPurchases,
                  ),
                )),
              ),
              const SizedBox(height: 30),
              _AdminActionCard(
                  icon: Icons.people_outline,
                  title: strings.text('users'),
                  detail: strings.text('manageUsers'),
                  onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const AdminUsersPage()))),
              const SizedBox(height: 14),
              _SectionLabel(title: strings.text('membershipManagement')),
              const SizedBox(height: 10),
              _AdminActionCard(
                icon: Icons.calendar_month_outlined,
                title: strings.text('classSchedule'),
                detail: strings.text('manageClassSchedule'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        ClassSchedulePage(bookings: widget.adminBookings))),
              ),
              const SizedBox(height: 14),
              _AdminActionCard(
                icon: Icons.fact_check_outlined,
                title: strings.text('attendance'),
                detail: strings.text('manageAttendance'),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        AttendancePage(bookings: widget.adminBookings))),
              ),
              const SizedBox(height: 14),
              _AdminActionCard(
                icon: Icons.pending_actions_outlined,
                title: strings.text('paymentsAwaitingApproval'),
                detail: strings.text('reviewCashPayments'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CashPurchaseRequestsPage(
                      purchases: widget.adminPurchases,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                  alignment: Alignment.centerRight,
                  child: LanguageMenuButton()),
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
