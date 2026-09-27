import 'package:flutter/material.dart';

import 'features/account/data/account_role_resolver.dart';
import 'features/auth/data/auth_gateway.dart';
import 'features/auth/pages/login_page.dart';
import 'features/purchases/data/purchase_gateway.dart';
import 'theme/app_theme.dart';

class PilatesApp extends StatelessWidget {
  const PilatesApp({
    super.key,
    this.auth = const UnconfiguredAuthGateway(),
    this.roles = const MemberAccountRoleResolver(),
    this.purchases = const UnconfiguredPurchaseGateway(),
    this.adminPurchases = const UnconfiguredAdminPurchaseGateway(),
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final AdminPurchaseGateway adminPurchases;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstreet Pilates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: LoginPage(
        auth: auth,
        roles: roles,
        purchases: purchases,
        adminPurchases: adminPurchases,
      ),
    );
  }
}
