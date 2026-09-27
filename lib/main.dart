import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'config/supabase_config.dart';
import 'features/auth/data/supabase_auth_gateway.dart';

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
  runApp(PilatesApp(auth: SupabaseAuthGateway(Supabase.instance.client.auth)));
}
