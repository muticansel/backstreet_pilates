import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'features/account/data/account_role_resolver.dart';
import 'features/account/pages/account_home_page.dart';
import 'features/auth/data/auth_gateway.dart';
import 'features/auth/pages/login_page.dart';
import 'features/bookings/data/booking_gateway.dart';
import 'features/purchases/data/purchase_gateway.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'theme/app_snack_bars.dart';
import 'theme/pilates_loading_indicator.dart';

class PilatesApp extends StatefulWidget {
  const PilatesApp({
    super.key,
    this.auth = const UnconfiguredAuthGateway(),
    this.roles = const MemberAccountRoleResolver(),
    this.purchases = const UnconfiguredPurchaseGateway(),
    this.adminPurchases = const UnconfiguredAdminPurchaseGateway(),
    this.bookings = const UnconfiguredBookingGateway(),
    this.adminBookings = const UnconfiguredAdminBookingGateway(),
  });

  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final AdminPurchaseGateway adminPurchases;
  final BookingGateway bookings;
  final AdminBookingGateway adminBookings;

  @override
  State<PilatesApp> createState() => _PilatesAppState();
}

class _PilatesAppState extends State<PilatesApp> {
  final _language = AppLanguage();
  late final Future<bool> _hasActiveSession = widget.auth.hasActiveSession();

  @override
  void dispose() {
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLanguageScope(
      language: _language,
      child: AnimatedBuilder(
        animation: _language,
        builder: (context, _) => MaterialApp(
          navigatorKey: AppNotifications.navigatorKey,
          title: 'Backstreet Pilates',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          locale: _language.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: _AppLaunchGate(
            hasActiveSession: _hasActiveSession,
            auth: widget.auth,
            roles: widget.roles,
            purchases: widget.purchases,
            adminPurchases: widget.adminPurchases,
            bookings: widget.bookings,
            adminBookings: widget.adminBookings,
          ),
        ),
      ),
    );
  }
}

class _AppLaunchGate extends StatelessWidget {
  const _AppLaunchGate({
    required this.hasActiveSession,
    required this.auth,
    required this.roles,
    required this.purchases,
    required this.adminPurchases,
    required this.bookings,
    required this.adminBookings,
  });

  final Future<bool> hasActiveSession;
  final AuthGateway auth;
  final AccountRoleResolver roles;
  final PurchaseGateway purchases;
  final AdminPurchaseGateway adminPurchases;
  final BookingGateway bookings;
  final AdminBookingGateway adminBookings;

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
        future: hasActiveSession,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: PilatesLoadingIndicator()),
            );
          }
          if (snapshot.data == true) {
            return AccountHomePage(
              auth: auth,
              roles: roles,
              purchases: purchases,
              adminPurchases: adminPurchases,
              bookings: bookings,
              adminBookings: adminBookings,
            );
          }
          return LoginPage(
            auth: auth,
            roles: roles,
            purchases: purchases,
            adminPurchases: adminPurchases,
            bookings: bookings,
            adminBookings: adminBookings,
          );
        },
      );
}
