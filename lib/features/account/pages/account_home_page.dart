import 'package:flutter/material.dart';

import '../../admin/pages/admin_dashboard_page.dart';
import '../../auth/data/auth_gateway.dart';
import '../../dashboard/dashboard_page.dart';
import '../data/account_role_resolver.dart';

class AccountHomePage extends StatefulWidget {
  const AccountHomePage({super.key, required this.auth, required this.roles});

  final AuthGateway auth;
  final AccountRoleResolver roles;

  @override
  State<AccountHomePage> createState() => _AccountHomePageState();
}

class _AccountHomePageState extends State<AccountHomePage> {
  late final Future<AccountRole> _role = widget.roles.currentRole();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccountRole>(
      future: _role,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == AccountRole.admin) {
          return AdminDashboardPage(auth: widget.auth, roles: widget.roles);
        }
        return DashboardPage(auth: widget.auth, roles: widget.roles);
      },
    );
  }
}
