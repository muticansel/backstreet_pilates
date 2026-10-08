import 'package:flutter/material.dart';

import '../account/data/account_role_resolver.dart';
import '../auth/data/auth_gateway.dart';
import '../auth/pages/login_page.dart';
import '../bookings/data/booking_gateway.dart';
import '../bookings/pages/class_feedback_page.dart';
import '../bookings/pages/upcoming_classes_page.dart';
import '../purchases/data/purchase_gateway.dart';
import '../purchases/pages/approved_packages_page.dart';
import '../profile/pages/profile_page.dart';
import '../../../theme/app_theme.dart';
import '../../../theme/app_snack_bars.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../../l10n/app_localizations.dart';
import '../../../notifications/push_notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({
    super.key,
    required this.auth,
    required this.roles,
    required this.purchases,
    required this.bookings,
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final BookingGateway bookings;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _signingOut = false;
  int _selectedIndex = 0;
  late Future<List<DateTime>> _completedClassDates;
  late Future<List<ApprovedPackage>> _approvedPackages;
  late Future<List<FeedbackClass>> _recentPractice;

  @override
  void initState() {
    super.initState();
    _completedClassDates = widget.bookings.loadCompletedClassDates();
    _approvedPackages = widget.purchases.loadApprovedPackages();
    _recentPractice = widget.bookings.loadFeedbackClasses();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _completedClassDates = widget.bookings.loadCompletedClassDates();
      _approvedPackages = widget.purchases.loadApprovedPackages();
      _recentPractice = widget.bookings.loadFeedbackClasses();
    });
    await Future.wait([
      _completedClassDates,
      _approvedPackages,
      _recentPractice,
    ]);
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await PushNotificationService.instance.unregisterCurrentDevice();
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
    setState(() => _selectedIndex = 1);
  }

  void _handleHeaderMenu(_DashboardMenuAction action) {
    switch (action) {
      case _DashboardMenuAction.profile:
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ProfilePage()),
        );
      case _DashboardMenuAction.feedback:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClassFeedbackPage(bookings: widget.bookings),
          ),
        );
      case _DashboardMenuAction.english:
        AppLanguageScope.of(context).change(const Locale('en'));
      case _DashboardMenuAction.turkish:
        AppLanguageScope.of(context).change(const Locale('tr'));
      case _DashboardMenuAction.signOut:
        if (!_signingOut) _signOut();
    }
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
          label: strings.text('navExplore'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month),
          label: strings.text('classes'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.verified_outlined),
          selectedIcon: const Icon(Icons.verified),
          label: strings.text('navMyPlan'),
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

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                    _DashboardProfileMenu(
                      signingOut: _signingOut,
                      onSelected: _handleHeaderMenu,
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Text(
                  AppLocalizations.of(context).text('welcomeBack'),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 10),
                Text(
                  AppLocalizations.of(context).text('dashboardIntro'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                const _StudioMomentCard(),
                const SizedBox(height: 30),
                const _SectionLabel(titleKey: 'currentPackage'),
                const SizedBox(height: 10),
                _CurrentPackageSection(packages: _approvedPackages),
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
                _RecentPracticeSection(classes: _recentPractice),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _navigationBar(),
    );
  }
}

enum _DashboardMenuAction { profile, feedback, english, turkish, signOut }

class _DashboardProfileMenu extends StatelessWidget {
  const _DashboardProfileMenu({
    required this.signingOut,
    required this.onSelected,
  });

  final bool signingOut;
  final ValueChanged<_DashboardMenuAction> onSelected;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final language = AppLanguageScope.of(context);
    return PopupMenuButton<_DashboardMenuAction>(
      tooltip: strings.text('profile'),
      enabled: !signingOut,
      onSelected: onSelected,
      offset: const Offset(0, 46),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const CircleAvatar(
        radius: 20,
        backgroundColor: AppTheme.sage,
        foregroundColor: Colors.white,
        child: Icon(Icons.person, size: 22),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _DashboardMenuAction.profile,
          child: _HeaderMenuItem(
            icon: Icons.person_outline,
            label: strings.text('editProfile'),
          ),
        ),
        PopupMenuItem(
          value: _DashboardMenuAction.feedback,
          child: _HeaderMenuItem(
            icon: Icons.rate_review_outlined,
            label: strings.text('classFeedback'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: language.locale.languageCode == 'en'
              ? _DashboardMenuAction.turkish
              : _DashboardMenuAction.english,
          child: _HeaderMenuItem(
            icon: Icons.language_outlined,
            label: language.locale.languageCode == 'en'
                ? strings.text('turkish')
                : strings.text('english'),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: _DashboardMenuAction.signOut,
          child: _HeaderMenuItem(
            icon: Icons.logout_outlined,
            label: strings.text('signOut'),
          ),
        ),
      ],
    );
  }
}

class _HeaderMenuItem extends StatelessWidget {
  const _HeaderMenuItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.sage),
          const SizedBox(width: 12),
          Text(label),
        ],
      );
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

class _StudioMomentCard extends StatelessWidget {
  const _StudioMomentCard();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: AppLocalizations.of(context).text('studioMomentA11y'),
      child: Container(
        height: 218,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xFFDCE5D5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/studio-instructor.png',
              fit: BoxFit.cover,
              alignment: const Alignment(0.45, 0.15),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.sage.withValues(alpha: .82),
                    AppTheme.sage.withValues(alpha: .12),
                  ],
                  stops: const [0, .7],
                ),
              ),
            ),
            Positioned(
              left: -32,
              bottom: -38,
              child: Container(
                height: 128,
                width: 178,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4CFA9).withValues(alpha: .38),
                  borderRadius: BorderRadius.circular(90),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 18,
              right: 126,
              child: Text(
                AppLocalizations.of(context).text('studioMoment'),
                style: const TextStyle(
                  fontFamily: 'Georgia',
                  color: Colors.white,
                  fontSize: 24,
                  height: 1.08,
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 18,
              child: Text(
                AppLocalizations.of(context).text('studioMomentLabel'),
                style: const TextStyle(
                  color: Color(0xFFF8F4EB),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentPackageSection extends StatelessWidget {
  const _CurrentPackageSection({required this.packages});

  final Future<List<ApprovedPackage>> packages;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ApprovedPackage>>(
        future: packages,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 180,
              child: Center(child: PilatesLoadingIndicator(size: 38)),
            );
          }
          if (snapshot.hasError) {
            return const _PackageMessageCard(
              icon: Icons.cloud_off_outlined,
              titleKey: 'currentPackageLoadError',
              detailKey: 'currentPackageLoadErrorDetail',
            );
          }
          final today = DateUtils.dateOnly(DateTime.now());
          final active = snapshot.data!
              .where((package) =>
                  package.status == 'active' &&
                  package.endDateExclusive.isAfter(today))
              .toList()
            ..sort((a, b) => a.endDateExclusive.compareTo(b.endDateExclusive));
          if (active.isEmpty) {
            return const _PackageMessageCard(
              icon: Icons.style_outlined,
              titleKey: 'noCurrentPackage',
              detailKey: 'noCurrentPackageDetail',
            );
          }
          return _MembershipCard(package: active.first);
        },
      );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.package});

  final ApprovedPackage package;

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
            package.branchName.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFFD6E3CE),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            package.title,
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
                '${package.remainingCredits}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).text('classesRemainingCompact'),
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
              value: ((package.totalCredits - package.remainingCredits) /
                      package.totalCredits)
                  .clamp(0.0, 1.0),
              minHeight: 7,
              color: const Color(0xFFE0C89B),
              backgroundColor: const Color(0xFF668273),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)
                .text('membershipProgressDetail')
                .replaceAll('{completed}',
                    '${package.totalCredits - package.remainingCredits}')
                .replaceAll('{total}', '${package.totalCredits}')
                .replaceAll(
                    '{date}',
                    MaterialLocalizations.of(context).formatMediumDate(
                      package.endDateExclusive
                          .subtract(const Duration(days: 1)),
                    )),
            style: const TextStyle(color: Color(0xFFD6E3CE), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PackageMessageCard extends StatelessWidget {
  const _PackageMessageCard({
    required this.icon,
    required this.titleKey,
    required this.detailKey,
  });

  final IconData icon;
  final String titleKey;
  final String detailKey;

  @override
  Widget build(BuildContext context) => _ProgressMessageCard(
        icon: icon,
        titleKey: titleKey,
        detailKey: detailKey,
      );
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
          color: const Color(0xFFEEF1E8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD4DDCD)),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFD5E0CF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.sage, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).text(titleKey),
                      style: const TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      )),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).text('explorePackagesTitle'),
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context).text('explorePackagesDetail')),
              ],
            ),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).text('explorePackages'),
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class _RecentPracticeSection extends StatelessWidget {
  const _RecentPracticeSection({required this.classes});

  final Future<List<FeedbackClass>> classes;

  @override
  Widget build(BuildContext context) => FutureBuilder<List<FeedbackClass>>(
        future: classes,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 140,
              child: Center(child: PilatesLoadingIndicator(size: 38)),
            );
          }
          if (snapshot.hasError) {
            return const _ProgressMessageCard(
              icon: Icons.cloud_off_outlined,
              titleKey: 'recentPracticeLoadError',
              detailKey: 'recentPracticeLoadErrorDetail',
            );
          }
          if (snapshot.data!.isEmpty) {
            return const _ProgressMessageCard(
              icon: Icons.self_improvement_outlined,
              titleKey: 'noRecentPractice',
              detailKey: 'noRecentPracticeDetail',
            );
          }
          return _HistoryCard(classes: snapshot.data!.take(3).toList());
        },
      );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.classes});

  final List<FeedbackClass> classes;

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
          for (var index = 0; index < classes.length; index++) ...[
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF0F3EB),
                foregroundColor: AppTheme.sage,
                child: Icon(Icons.check),
              ),
              title: Text(classes[index].title),
              subtitle: Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(classes[index].startsAt),
              ),
              trailing: Text(
                AppLocalizations.of(context).text('completed'),
                style: TextStyle(fontSize: 12, color: AppTheme.sage),
              ),
            ),
            if (index < classes.length - 1)
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
                    AppLocalizations.of(context).text('packagesIntro'),
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
              RadioGroup<bool>(
                groupValue: cash,
                onChanged: (value) => setDialog(() => cash = value!),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      value: true,
                      title: Text(AppLocalizations.of(context).text('cash')),
                    ),
                    RadioListTile<bool>(
                      value: false,
                      title:
                          Text(AppLocalizations.of(context).text('creditCard')),
                    ),
                  ],
                ),
              ),
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
