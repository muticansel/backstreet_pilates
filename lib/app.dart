import 'package:flutter/material.dart';

import 'features/account/data/account_role_resolver.dart';
import 'features/auth/data/auth_gateway.dart';
import 'features/auth/pages/login_page.dart';
import 'theme/app_theme.dart';

class PilatesApp extends StatelessWidget {
  const PilatesApp({
    super.key,
    this.auth = const UnconfiguredAuthGateway(),
    this.roles = const MemberAccountRoleResolver(),
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstreet Pilates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: LoginPage(auth: auth, roles: roles),
    );
  }
}
