import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'features/account/data/supabase_account_role_resolver.dart';
import 'features/auth/data/supabase_auth_gateway.dart';
import 'features/bookings/data/supabase_booking_gateway.dart';
import 'features/purchases/data/supabase_purchase_gateway.dart';
import 'notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = SupabaseConfig.fromEnvironment;
  if (!config.isConfigured) {
    runApp(const PilatesApp());
    return;
  }

  await Supabase.initialize(
    url: config.url,
    publishableKey: config.publishableKey,
    authOptions:
        const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
  );
  await Firebase.initializeApp();
  await PushNotificationService.instance.initialize(Supabase.instance.client);
  runApp(PilatesApp(
    auth: SupabaseAuthGateway(Supabase.instance.client.auth),
    roles: SupabaseAccountRoleResolver(Supabase.instance.client),
    purchases: SupabasePurchaseGateway(Supabase.instance.client),
    adminPurchases: SupabasePurchaseGateway(Supabase.instance.client),
    bookings: SupabaseBookingGateway(Supabase.instance.client),
    adminBookings: SupabaseBookingGateway(Supabase.instance.client),
  ));
}
