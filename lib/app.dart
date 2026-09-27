import 'package:flutter/material.dart';

import 'features/auth/data/auth_gateway.dart';
import 'features/auth/pages/login_page.dart';
import 'theme/app_theme.dart';

class PilatesApp extends StatelessWidget {
  const PilatesApp({super.key, this.auth = const UnconfiguredAuthGateway()});

  final AuthGateway auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Backstreet Pilates',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: LoginPage(auth: auth),
    );
  }
}
