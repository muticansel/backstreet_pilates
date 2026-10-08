import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../l10n/app_localizations.dart';
import '../../../theme/app_snack_bars.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});
  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late Future<List<dynamic>> _users = _load();
  Future<List<dynamic>> _load() async =>
      ((await Supabase.instance.client.functions
              .invoke('admin-user-management', body: {'action': 'list'}))
          .data['users'] as List<dynamic>);
  Future<void> _action(Map<String, dynamic> user, String action) async {
    try {
      await Supabase.instance.client.functions.invoke('admin-user-management',
          body: {'action': action, 'userId': user['id']});
    } catch (_) {
      if (!mounted) return;
      final strings = AppLocalizations.of(context);
      AppNotifications.error(strings.text('userActionFailed'));
      return;
    }
    if (!mounted) return;
    final strings = AppLocalizations.of(context);
    AppNotifications.success(action == 'send_password_reset'
        ? strings.text('passwordResetSent')
        : strings.text('userStatusUpdated'));
    setState(() => _users = _load());
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(title: Text(strings.text('users'))),
        body: FutureBuilder<List<dynamic>>(
            future: _users,
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final user = snapshot.data![index] as Map<String, dynamic>;
                    final active = user['isActive'] as bool;
                    final approvalStatus = user['approvalStatus'] as String;
                    final isPendingApproval =
                        approvalStatus == 'pending_admin_approval';
                    return ListTile(
                        title: Text((user['displayName'] as String).isEmpty
                            ? user['email'] as String
                            : user['displayName'] as String),
                        subtitle: Text(
                            '${user['email']} · ${strings.text(active ? 'active' : 'inactive')} · ${strings.text(_approvalStatusKey(approvalStatus))}'),
                        trailing: PopupMenuButton<String>(
                            onSelected: (action) => _action(user, action),
                            itemBuilder: (_) => [
                                  if (isPendingApproval)
                                    PopupMenuItem(
                                      value: 'approve',
                                      child: Text(strings.text('approve')),
                                    ),
                                  PopupMenuItem(
                                      value: active ? 'deactivate' : 'activate',
                                      child: Text(strings.text(
                                          active ? 'deactivate' : 'activate'))),
                                  PopupMenuItem(
                                      value: 'send_password_reset',
                                      child: Text(
                                          strings.text('sendPasswordReset')))
                                ]));
                  });
            }));
  }

  String _approvalStatusKey(String status) => switch (status) {
        'approved' => 'approved',
        'pending_admin_approval' => 'pendingAdminApproval',
        _ => 'awaitingEmailConfirmation',
      };
}
