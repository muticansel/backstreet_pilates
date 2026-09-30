import 'package:flutter/material.dart';

import '../../admin/pages/admin_dashboard_page.dart';
import '../../auth/data/auth_gateway.dart';
import '../../bookings/data/booking_gateway.dart';
import '../../dashboard/dashboard_page.dart';
import '../../purchases/data/purchase_gateway.dart';
import '../data/account_role_resolver.dart';
import '../../../theme/pilates_loading_indicator.dart';

class AccountHomePage extends StatefulWidget {
  const AccountHomePage({
    super.key,
    required this.auth,
    required this.roles,
    required this.purchases,
    required this.adminPurchases,
    required this.bookings,
    required this.adminBookings,
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final AdminPurchaseGateway adminPurchases;
  final BookingGateway bookings;
  final AdminBookingGateway adminBookings;

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
            body: Center(child: PilatesLoadingIndicator()),
          );
        }
        if (snapshot.data == AccountRole.admin) {
          return AdminDashboardPage(
            auth: widget.auth,
            roles: widget.roles,
            purchases: widget.purchases,
            adminPurchases: widget.adminPurchases,
            adminBookings: widget.adminBookings,
          );
        }
        return DashboardPage(
            auth: widget.auth,
            roles: widget.roles,
            purchases: widget.purchases,
            bookings: widget.bookings);
      },
    );
  }
}
