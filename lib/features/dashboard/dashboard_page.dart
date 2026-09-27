import 'package:flutter/material.dart';

import '../auth/data/auth_gateway.dart';
import '../auth/pages/login_page.dart';
import '../../../theme/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, required this.auth, this.dashboard});

  final AuthGateway auth;
  final DashboardData? dashboard;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _signingOut = false;

  DashboardData get _dashboard => widget.dashboard ?? DashboardData.preview;

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
            Text('Packages', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            const Text(
              'This is where you’ll compare packages and purchase the one that suits your practice.',
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const _SectionLabel(title: 'YOUR CURRENT PACKAGE'),
              const SizedBox(height: 10),
              _MembershipCard(membership: dashboard.membership),
              const SizedBox(height: 30),
              const _SectionLabel(title: 'FIND YOUR NEXT RHYTHM'),
              const SizedBox(height: 10),
              _ExplorePackagesCard(onPressed: _showPurchasePreview),
              const SizedBox(height: 30),
              const _SectionLabel(title: 'YOUR RECENT PRACTICE'),
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
    );
  }
}

class DashboardData {
  const DashboardData(
      {required this.membership, required this.recentActivities});

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
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
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
