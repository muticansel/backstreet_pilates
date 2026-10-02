import 'package:flutter/material.dart';

import '../data/admin_dashboard_data.dart';
import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class ActiveMembersPage extends StatelessWidget {
  const ActiveMembersPage({super.key, required this.members});

  final List<ActiveMember> members;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(AppLocalizations.of(context).text('activePackages'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            AppLocalizations.of(context).text('activePackagesPreview'),
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
                Text(
                    AppLocalizations.of(context)
                        .text('classesRemaining')
                        .replaceAll('{count}', '${member.remainingCredits}'),
                    style: const TextStyle(color: AppTheme.sage)),
                const Spacer(),
                Text(
                    AppLocalizations.of(context)
                        .text('until')
                        .replaceAll('{date}', member.validUntil),
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      );
}
