import 'package:flutter/material.dart';

import '../account/data/account_role_resolver.dart';
import '../auth/data/auth_gateway.dart';
import '../auth/pages/login_page.dart';
import '../bookings/data/booking_gateway.dart';
import '../bookings/pages/upcoming_classes_page.dart';
import '../purchases/data/purchase_gateway.dart';
import '../purchases/pages/approved_packages_page.dart';
import '../profile/pages/profile_page.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../../l10n/app_localizations.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.auth,
    required this.roles,
    required this.purchases,
    required this.bookings,
    this.dashboard,
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final BookingGateway bookings;
  final DashboardData? dashboard;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _signingOut = false;
  int _selectedIndex = 0;
  late final Future<List<DateTime>> _completedClassDates;

  DashboardData get _dashboard => widget.dashboard ?? DashboardData.preview;

  @override
  void initState() {
    super.initState();
    _completedClassDates = widget.bookings.loadCompletedClassDates();
  }

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
      AppNotifications.error(error.message);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  void _showPurchasePreview() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).text('packages'),
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            const Text(
              'This is where you’ll compare packages and purchase the one that suits your practice.',
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context).text('gotIt')),
            ),
          ],
        ),
      ),
    );
  }

  NavigationBar _navigationBar() {
    final strings = AppLocalizations.of(context);
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home),
          label: strings.text('home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.style_outlined),
          selectedIcon: const Icon(Icons.style),
          label: strings.text('packages'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: strings.text('classes'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.verified_outlined),
          selectedIcon: const Icon(Icons.verified),
          label: strings.text('myPackages'),
        ),
      ],
    );
  }

  Widget _placeholderScaffold(Widget child) {
    return Scaffold(
      body: SafeArea(child: child),
      bottomNavigationBar: _navigationBar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex == 1) {
      return _placeholderScaffold(
        _PackagesPlaceholder(purchases: widget.purchases),
      );
    }
    if (_selectedIndex == 2) {
      return _placeholderScaffold(
        UpcomingClassesPage(bookings: widget.bookings),
      );
    }
    if (_selectedIndex == 3) {
      return _placeholderScaffold(
        ApprovedPackagesPage(purchases: widget.purchases),
      );
    }

    final dashboard = _dashboard;
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
                  IconButton(
                    tooltip: AppLocalizations.of(context).text('editProfile'),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) => const ProfilePage()),
                    ),
                    icon: const CircleAvatar(
                      radius: 15,
                      backgroundColor: AppTheme.sage,
                      foregroundColor: Colors.white,
                      child: Icon(Icons.person, size: 18),
                    ),
                  ),
                  const LanguageMenuButton(),
                ],
              ),
              const SizedBox(height: 34),
              Text(
                'Welcome back.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'A little movement can change your whole day.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 30),
              const _SectionLabel(titleKey: 'currentPackage'),
              const SizedBox(height: 10),
              _MembershipCard(membership: dashboard.membership),
              const SizedBox(height: 30),
              const _SectionLabel(titleKey: 'yourProgress'),
              const SizedBox(height: 10),
              _PracticeProgressSection(
                  completedClassDates: _completedClassDates),
              const SizedBox(height: 30),
              const _SectionLabel(titleKey: 'nextRhythm'),
              const SizedBox(height: 10),
              _ExplorePackagesCard(onPressed: _showPurchasePreview),
              const SizedBox(height: 30),
              const _SectionLabel(titleKey: 'recentPractice'),
              const SizedBox(height: 10),
              _HistoryCard(activities: dashboard.recentActivities),
              const SizedBox(height: 20),
              const Text(
                'Dashboard content is currently preview data while memberships and bookings are being connected.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.sage),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _navigationBar(),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.membership,
    required this.recentActivities,
  });

  final MembershipSummary membership;
  final List<PracticeActivity> recentActivities;

  static const preview = DashboardData(
    membership: MembershipSummary(
      packageName: '8 class package',
      branchName: 'Oran studio',
      totalCredits: 8,
      remainingCredits: 4,
      validUntil: '24 October',
    ),
    recentActivities: [
      PracticeActivity(title: 'Mat Pilates', detail: 'Tuesday, 08 October'),
      PracticeActivity(
        title: 'Reformer Pilates',
        detail: 'Saturday, 05 October',
      ),
    ],
  );
}

class MembershipSummary {
  const MembershipSummary({
    required this.packageName,
    required this.branchName,
    required this.totalCredits,
    required this.remainingCredits,
    required this.validUntil,
  });

  final String packageName;
  final String branchName;
  final int totalCredits;
  final int remainingCredits;
  final String validUntil;

  double get progress => (totalCredits - remainingCredits) / totalCredits;
}

class PracticeActivity {
  const PracticeActivity({required this.title, required this.detail});

  final String title;
  final String detail;
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.titleKey});

  final String titleKey;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).text(titleKey),
      style: const TextStyle(
        color: AppTheme.sage,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.8,
      ),
    );
  }
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership});

  final MembershipSummary membership;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.sage,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            membership.branchName.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD6E3CE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            membership.packageName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              Text(
                '${membership.remainingCredits}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'classes\nremaining',
                style: TextStyle(color: Color(0xFFD6E3CE), height: 1.35),
              ),
              const Spacer(),
              const Icon(
                Icons.self_improvement_outlined,
                color: Color(0xFFD6E3CE),
                size: 34,
              ),
            ],
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: membership.progress,
              minHeight: 7,
              color: const Color(0xFFE0C89B),
              backgroundColor: const Color(0xFF668273),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${membership.totalCredits - membership.remainingCredits} of ${membership.totalCredits} classes completed · valid through ${membership.validUntil}',
            style: const TextStyle(color: Color(0xFFD6E3CE), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PracticeProgressSection extends StatelessWidget {
  const _PracticeProgressSection({required this.completedClassDates});

  final Future<List<DateTime>> completedClassDates;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DateTime>>(
      future: completedClassDates,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: PilatesLoadingIndicator(size: 38)),
          );
        }
        if (snapshot.hasError) return const _ProgressLoadError();
        if (snapshot.data!.isEmpty) return const _NoProgressCard();
        return _ProgressCard(progress: PracticeProgress.from(snapshot.data!));
      },
    );
  }
}

class PracticeProgress {
  PracticeProgress._({
    required this.monthlyAttendance,
    required this.monthKeys,
    required this.currentWeeks,
    required this.bestWeeks,
    required this.completedClasses,
  });

  final List<int> monthlyAttendance;
  final List<String> monthKeys;
  final int currentWeeks;
  final int bestWeeks;
  final int completedClasses;

  factory PracticeProgress.from(List<DateTime> completedClassDates) {
    final now = DateTime.now();
    final monthStarts = List<DateTime>.generate(
      6,
      (index) => DateTime(now.year, now.month - 5 + index),
    );
    final attendance = monthStarts
        .map((month) => completedClassDates
            .where(
                (date) => date.year == month.year && date.month == month.month)
            .length)
        .toList();
    final weeks = completedClassDates.map(_weekStart).toSet().toList()..sort();
    var best = 0;
    var running = 0;
    DateTime? previous;
    for (final week in weeks) {
      running = previous != null && week.difference(previous).inDays == 7
          ? running + 1
          : 1;
      best = best > running ? best : running;
      previous = week;
    }
    var current = 0;
    var cursor = _weekStart(now);
    while (weeks.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 7));
    }
    return PracticeProgress._(
      monthlyAttendance: attendance,
      monthKeys: monthStarts.map((month) => 'month${month.month}').toList(),
      currentWeeks: current,
      bestWeeks: best,
      completedClasses: completedClassDates.length,
    );
  }

  static DateTime _weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day)
          .subtract(Duration(days: date.weekday - DateTime.monday));
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final PracticeProgress progress;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final maximum = progress.monthlyAttendance
        .fold(1, (maximum, value) => value > maximum ? value : maximum);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(strings.text('monthlyAttendance'),
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text(strings.text('monthlyAttendanceSubtitle'),
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          SizedBox(
            height: 116,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var index = 0;
                    index < progress.monthlyAttendance.length;
                    index++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Semantics(
                        label: strings
                            .text('attendanceBarLabel')
                            .replaceAll('{month}',
                                strings.text(progress.monthKeys[index]))
                            .replaceAll('{count}',
                                '${progress.monthlyAttendance[index]}'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('${progress.monthlyAttendance[index]}',
                                style: const TextStyle(
                                    color: AppTheme.sage,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 5),
                            Container(
                              height: 58 *
                                  progress.monthlyAttendance[index] /
                                  maximum,
                              decoration: BoxDecoration(
                                color: AppTheme.sage,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(strings.text(progress.monthKeys[index]),
                                style: const TextStyle(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 32),
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFE3E9DD),
                foregroundColor: AppTheme.sage,
                child: Icon(Icons.local_fire_department_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(strings.text('consistency'),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(
                      strings
                          .text('consistencyDetail')
                          .replaceAll('{current}', '${progress.currentWeeks}')
                          .replaceAll('{best}', '${progress.bestWeeks}'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(strings.text('milestones'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MilestoneChip(
                  titleKey: 'firstClass',
                  reached: progress.completedClasses >= 1),
              _MilestoneChip(
                  titleKey: 'fourClasses',
                  reached: progress.completedClasses >= 4),
              _MilestoneChip(
                  titleKey: 'eightClasses',
                  reached: progress.completedClasses >= 8),
            ],
          ),
        ],
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.titleKey, required this.reached});

  final String titleKey;
  final bool reached;

  @override
  Widget build(BuildContext context) {
    final color = reached ? AppTheme.sage : const Color(0xFF89958A);
    return Semantics(
      label: AppLocalizations.of(context)
          .text(reached ? 'milestoneReached' : 'milestoneAhead')
          .replaceAll(
              '{milestone}', AppLocalizations.of(context).text(titleKey)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: reached ? const Color(0xFFE3E9DD) : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(reached ? Icons.check_circle : Icons.flag_outlined,
                color: color, size: 16),
            const SizedBox(width: 5),
            Text(AppLocalizations.of(context).text(titleKey),
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _NoProgressCard extends StatelessWidget {
  const _NoProgressCard();

  @override
  Widget build(BuildContext context) => _ProgressMessageCard(
        icon: Icons.insights_outlined,
        titleKey: 'noProgressYet',
        detailKey: 'noProgressYetDetail',
      );
}

class _ProgressLoadError extends StatelessWidget {
  const _ProgressLoadError();

  @override
  Widget build(BuildContext context) => _ProgressMessageCard(
        icon: Icons.cloud_off_outlined,
        titleKey: 'progressLoadError',
        detailKey: 'progressLoadErrorDetail',
      );
}

class _ProgressMessageCard extends StatelessWidget {
  const _ProgressMessageCard({
    required this.icon,
    required this.titleKey,
    required this.detailKey,
  });

  final IconData icon;
  final String titleKey;
  final String detailKey;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8DED5)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.sage, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).text(titleKey),
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(AppLocalizations.of(context).text(detailKey)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ExplorePackagesCard extends StatelessWidget {
  const _ExplorePackagesCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E9DD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFCFDBC6),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_circle_outline, color: AppTheme.sage),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'More time for you',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text('Explore a package that fits your pace.'),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Explore packages',
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.activities});

  final List<PracticeActivity> activities;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD8DED5)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < activities.length; index++) ...[
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF0F3EB),
                foregroundColor: AppTheme.sage,
                child: Icon(Icons.check),
              ),
              title: Text(activities[index].title),
              subtitle: Text(activities[index].detail),
              trailing: const Text(
                'Completed',
                style: TextStyle(fontSize: 12, color: AppTheme.sage),
              ),
            ),
            if (index < activities.length - 1)
              const Divider(height: 1, indent: 72, endIndent: 20),
          ],
        ],
      ),
    );
  }
}

class _PackagesPlaceholder extends StatefulWidget {
  const _PackagesPlaceholder({required this.purchases});

  final PurchaseGateway purchases;

  @override
  State<_PackagesPlaceholder> createState() => _PackagesPlaceholderState();
}

class _PackagesPlaceholderState extends State<_PackagesPlaceholder> {
  late final Future<List<PackageOffer>> _offers =
      widget.purchases.loadActiveOffers();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PackageOffer>>(
        future: _offers,
        builder: (context, snapshot) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.style_outlined,
                      color: AppTheme.sage, size: 34),
                  const SizedBox(height: 24),
                  Text(AppLocalizations.of(context).text('packages'),
                      style: Theme.of(context).textTheme.headlineLarge),
                  const SizedBox(height: 10),
                  Text(
                    'Find a rhythm that fits your week.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  if (snapshot.connectionState != ConnectionState.done)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(32),
                            child: PilatesLoadingIndicator()))
                  else if (snapshot.hasError || snapshot.data!.isEmpty)
                    Text(
                        AppLocalizations.of(context)
                            .text('noPackagesAvailable'),
                        textAlign: TextAlign.center)
                  else
                    for (final offer in snapshot.data!) ...[
                      _PackageOptionCard(
                        title: offer.title,
                        detail: AppLocalizations.of(context)
                            .text('packageDetails')
                            .replaceAll('{branch}', offer.branchName)
                            .replaceAll('{classes}', '${offer.totalCredits}')
                            .replaceAll('{weeks}', '${offer.durationWeeks}')
                            .replaceAll(
                                '{price}', '₺${offer.priceMinor ~/ 100}'),
                        icon: Icons.spa_outlined,
                        onTap: () => _showRequest(context, offer),
                      ),
                      const SizedBox(height: 14),
                    ],
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).text('cashPaymentOnly'),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppTheme.sage),
                  ),
                ],
              ),
            ));
  }

  Future<void> _showRequest(BuildContext context, PackageOffer offer) async {
    var cash = true;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(offer.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(offer.branchName),
              Text(
                AppLocalizations.of(context)
                    .text('fixedPackageStarts')
                    .replaceAll(
                      '{date}',
                      '${offer.startsOn.day.toString().padLeft(2, '0')}.'
                          '${offer.startsOn.month.toString().padLeft(2, '0')}.'
                          '${offer.startsOn.year}',
                    ),
              ),
              RadioListTile<bool>(
                  value: true,
                  groupValue: cash,
                  onChanged: (value) => setDialog(() => cash = value!),
                  title: Text(AppLocalizations.of(context).text('cash'))),
              RadioListTile<bool>(
                  value: false,
                  groupValue: cash,
                  onChanged: (value) => setDialog(() => cash = value!),
                  title: Text(AppLocalizations.of(context).text('creditCard'))),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).text('cancel'))),
            FilledButton(
              onPressed: () async {
                if (!cash) {
                  AppNotifications.error(AppLocalizations.of(this.context)
                      .text('cardPaymentsSoon'));
                  return;
                }
                try {
                  await widget.purchases.requestCashPurchase(
                      offerId: offer.id, requestedStartDate: offer.startsOn);
                  if (context.mounted) Navigator.pop(context);
                  if (mounted)
                    AppNotifications.success(AppLocalizations.of(this.context)
                        .text('cashRequestSent'));
                } on PurchaseFailure catch (error) {
                  if (context.mounted) Navigator.of(context).pop();
                  if (mounted) {
                    AppNotifications.error(error.message);
                  }
                }
              },
              child: Text(AppLocalizations.of(context).text('sendRequest')),
            ),
          ],
        ),
      ),
    );
  }
}

class _PackageOptionCard extends StatelessWidget {
  const _PackageOptionCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFE3E9DD),
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
}
