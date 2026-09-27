import 'package:flutter/material.dart';

import '../data/admin_dashboard_data.dart';
import '../../../theme/app_theme.dart';

class ActiveMembersPage extends StatelessWidget {
  const ActiveMembersPage({super.key, required this.members});

  final List<ActiveMember> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active member packages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          const Text(
            'Preview list — it will show every active membership after the membership model is connected.',
            style: TextStyle(color: AppTheme.sage),
          ),
          const SizedBox(height: 20),
          for (final member in members) ...[
            _MemberCard(member: member),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final ActiveMember member;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8DED5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(member.name,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
            const SizedBox(height: 7),
            Text('${member.packageName} · ${member.branchName}'),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('${member.remainingCredits} classes remaining',
                    style: const TextStyle(color: AppTheme.sage)),
                const Spacer(),
                Text('Until ${member.validUntil}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}
