import 'package:flutter/material.dart';

import '../../admin/pages/admin_dashboard_page.dart';
import '../../auth/data/auth_gateway.dart';
import '../../bookings/data/booking_gateway.dart';
import '../../dashboard/dashboard_page.dart';
import '../../purchases/data/purchase_gateway.dart';
import '../data/account_role_resolver.dart';
import '../../../theme/pilates_loading_indicator.dart';
import '../../../notifications/push_notification_service.dart';
import 'pending_approval_page.dart';

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
  late final Future<AccountApprovalStatus> _approvalStatus =
      widget.roles is AccountApprovalResolver
          ? (widget.roles as AccountApprovalResolver).currentApprovalStatus()
          : Future.value(AccountApprovalStatus.approved);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.activateForSignedInUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait<Object>([_role, _approvalStatus]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: PilatesLoadingIndicator()),
          );
        }
        final role = snapshot.data![0] as AccountRole;
        final approvalStatus = snapshot.data![1] as AccountApprovalStatus;
        if (role != AccountRole.admin &&
            approvalStatus != AccountApprovalStatus.approved) {
          return PendingApprovalPage(
            auth: widget.auth,
            roles: widget.roles,
            status: approvalStatus,
          );
        }
        if (role == AccountRole.admin) {
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
