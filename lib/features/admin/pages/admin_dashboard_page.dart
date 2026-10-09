import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../notifications/push_notification_service.dart';
import '../../../theme/app_theme.dart';
import '../../account/data/account_role_resolver.dart';
import '../../auth/data/auth_gateway.dart';
import '../../auth/pages/login_page.dart';
import '../../bookings/data/booking_gateway.dart';
import '../../purchases/data/purchase_gateway.dart';
import 'admin_users_page.dart';
import 'attendance_page.dart';
import 'cash_purchase_requests_page.dart';
import 'class_schedule_page.dart';
import 'individual_lessons_page.dart';
import 'private_lesson_calendar_page.dart';
import 'today_operations_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({
    super.key,
    required this.auth,
    required this.roles,
    required this.purchases,
    required this.adminPurchases,
    required this.adminBookings,
  });

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
  int _selectedIndex = 0;
  late Future<AdminDashboardMetrics> _metrics;
  late Future<AdminTodayOperations> _operations;
  late Future<List<AdminAttendanceRecord>> _attendance;

  @override
  void initState() {
    super.initState();
    _reloadData();
  }

  void _reloadData() {
    _metrics = widget.adminPurchases.loadDashboardMetrics();
    _operations = widget.adminBookings.loadTodayOperations();
    _attendance = widget.adminBookings.loadPastAttendance();
  }

  Future<void> _refresh() async {
    setState(_reloadData);
    await Future.wait([_metrics, _operations, _attendance]);
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

  int _pendingAttendanceCount(List<AdminAttendanceRecord> records) {
    final today = DateTime.now();
    return records
        .where((record) =>
            record.status == 'booked' &&
            record.startsAt.year == today.year &&
            record.startsAt.month == today.month &&
            record.startsAt.day == today.day)
        .length;
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex) {
      if (index == 0) _refresh();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return FutureBuilder<AdminTodayOperations>(
      future: _operations,
      builder: (context, operationsSnapshot) =>
          FutureBuilder<List<AdminAttendanceRecord>>(
        future: _attendance,
        builder: (context, attendanceSnapshot) => Scaffold(
          body: SafeArea(
            child: Column(children: [
              _AdminHeader(signingOut: _signingOut, onSignOut: _signOut),
              Expanded(child: _buildTab(operationsSnapshot)),
            ]),
          ),
          bottomNavigationBar: _navigationBar(
            strings,
            pendingAttendance: attendanceSnapshot.hasData
                ? _pendingAttendanceCount(attendanceSnapshot.data!)
                : 0,
            pendingPayments: operationsSnapshot.hasData
                ? operationsSnapshot.data!.pendingPayments.length
                : 0,
          ),
        ),
      ),
    );
  }

  Widget _buildTab(AsyncSnapshot<AdminTodayOperations> operationsSnapshot) {
    final strings = AppLocalizations.of(context);
    switch (_selectedIndex) {
      case 0:
        if (operationsSnapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (operationsSnapshot.hasError) return _LoadError(onRetry: _refresh);
        return RefreshIndicator(
          onRefresh: _refresh,
          child: AdminTodayOperationsContent(
            data: operationsSnapshot.data!,
            bookings: widget.adminBookings,
            purchases: widget.adminPurchases,
          ),
        );
      case 1:
        return _ActionTab(
          title: strings.text('adminClasses'),
          subtitle: strings.text('adminClassesSubtitle'),
          children: [
            _AdminActionCard(
              icon: Icons.calendar_month_outlined,
              title: strings.text('classSchedule'),
              detail: strings.text('manageClassSchedule'),
              onTap: () =>
                  _open(ClassSchedulePage(bookings: widget.adminBookings)),
            ),
            _AdminActionCard(
              icon: Icons.fact_check_outlined,
              title: strings.text('attendance'),
              detail: strings.text('manageAttendance'),
              onTap: () =>
                  _open(AttendancePage(bookings: widget.adminBookings)),
            ),
          ],
        );
      case 2:
        return _ActionTab(
          title: strings.text('adminIndividual'),
          subtitle: strings.text('adminIndividualSubtitle'),
          children: [
            _AdminActionCard(
              icon: Icons.person_outline,
              title: strings.text('privateLessons'),
              detail: strings.text('privateLessonsSubtitle'),
              onTap: () =>
                  _open(IndividualLessonsPage(bookings: widget.adminBookings)),
            ),
            _AdminActionCard(
              icon: Icons.calendar_view_week_outlined,
              title: strings.text('privateLessonCalendar'),
              detail: strings.text('privateLessonCalendarDetail'),
              onTap: () => _open(
                  PrivateLessonCalendarPage(bookings: widget.adminBookings)),
            ),
          ],
        );
      default:
        return _ManagementTab(
          metrics: _metrics,
          onRetry: _refresh,
          onOpenUsers: () => _open(const AdminUsersPage()),
          onOpenPayments: () => _open(
            CashPurchaseRequestsPage(purchases: widget.adminPurchases),
          ),
        );
    }
  }

  NavigationBar _navigationBar(
    AppLocalizations strings, {
    required int pendingAttendance,
    required int pendingPayments,
  }) =>
      NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: strings.text('today'),
          ),
          NavigationDestination(
            icon: _BadgeIcon(
                icon: Icons.calendar_month_outlined, count: pendingAttendance),
            selectedIcon: _BadgeIcon(
                icon: Icons.calendar_month, count: pendingAttendance),
            label: strings.text('adminClasses'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: strings.text('adminIndividual'),
          ),
          NavigationDestination(
            icon: _BadgeIcon(
              icon: Icons.settings_outlined,
              count: pendingPayments,
              critical: true,
            ),
            selectedIcon: _BadgeIcon(
              icon: Icons.settings,
              count: pendingPayments,
              critical: true,
            ),
            label: strings.text('management'),
          ),
        ],
      );
}

class _AdminHeader extends StatelessWidget {
  const _AdminHeader({required this.signingOut, required this.onSignOut});
  final bool signingOut;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
      child: Row(children: [
        const Icon(Icons.spa_outlined, color: AppTheme.sage, size: 28),
        const SizedBox(width: 10),
        const Expanded(
          child: Text('Backstreet Pilates',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5)),
        ),
        const LanguageMenuButton(),
        IconButton(
          tooltip: strings.text('signOut'),
          onPressed: signingOut ? null : onSignOut,
          icon: const Icon(Icons.logout_outlined),
        ),
      ]),
    );
  }
}

class _ActionTab extends StatelessWidget {
  const _ActionTab(
      {required this.title, required this.subtitle, required this.children});
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 28),
          ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 14), child: child)),
        ],
      );
}

class _ManagementTab extends StatelessWidget {
  const _ManagementTab({
    required this.metrics,
    required this.onRetry,
    required this.onOpenUsers,
    required this.onOpenPayments,
  });
  final Future<AdminDashboardMetrics> metrics;
  final Future<void> Function() onRetry;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenPayments;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 36),
      children: [
        Text(strings.text('management'),
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text(strings.text('managementSubtitle'),
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        FutureBuilder<AdminDashboardMetrics>(
          future: metrics,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                  height: 154,
                  child: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError) {
              return TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(strings.text('tryAgain')),
              );
            }
            final value = snapshot.data!;
            return Row(children: [
              Expanded(
                child: _MetricCard(
                  label: strings.text('thisMonth'),
                  value: _formatTry(value.monthlySalesMinor),
                  detail: '${strings.text('groupClassEarnings')}: '
                      '${_formatTry(value.groupClassIncomeMinor)}\n'
                      '${strings.text('individualLessonEarnings')}: '
                      '${_formatTry(value.individualLessonEarningsMinor)}',
                  icon: Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricCard(
                  label: strings.text('activeMembers'),
                  value: '${value.activeMembers}',
                  detail: strings
                      .text('activeMembersByBranch')
                      .replaceAll('{oran}', '${value.oranActiveMembers}')
                      .replaceAll('{incek}', '${value.incekActiveMembers}'),
                  icon: Icons.people_outline,
                ),
              ),
            ]);
          },
        ),
        const SizedBox(height: 28),
        _AdminActionCard(
          icon: Icons.people_outline,
          title: strings.text('users'),
          detail: strings.text('manageUsers'),
          onTap: onOpenUsers,
        ),
        const SizedBox(height: 14),
        _AdminActionCard(
          icon: Icons.pending_actions_outlined,
          title: strings.text('paymentsAwaitingApproval'),
          detail: strings.text('reviewCashPayments'),
          onTap: onOpenPayments,
        ),
      ],
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon(
      {required this.icon, required this.count, this.critical = false});
  final IconData icon;
  final int count;
  final bool critical;

  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        backgroundColor: critical ? const Color(0xFFB6543C) : AppTheme.sage,
        child: Icon(icon),
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: Text(AppLocalizations.of(context).text('tryAgain')),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.detail,
      required this.icon});
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppTheme.sage),
          const SizedBox(height: 20),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.sage,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Text(value,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(fontSize: 12)),
        ]),
      );
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard(
      {required this.icon,
      required this.title,
      required this.detail,
      required this.onTap});
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
            child: Row(children: [
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
                    ]),
              ),
              const Icon(Icons.arrow_forward, color: AppTheme.sage),
            ]),
          ),
        ),
      );
}

String _formatTry(int amountMinor) {
  final digits = (amountMinor ~/ 100).toString();
  final groups = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    groups.add(digits.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  return '₺${groups.reversed.join('.')}';
}
