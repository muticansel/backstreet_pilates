import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

/// A scrollable single-column form on phones, with a brand panel on wide screens.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(builder: (context, constraints) {
          final form = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(children: [
                      const Icon(Icons.spa_outlined,
                          color: AppTheme.sage, size: 30),
                      const SizedBox(width: 10),
                      const Flexible(
                        child: Text('Backstreet Pilates',
                            style: TextStyle(
                              letterSpacing: 3,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                      const Spacer(),
                      const LanguageMenuButton(),
                    ]),
                    const SizedBox(height: 48),
                    Text(title,
                        style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 12),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 32),
                    child,
                    const SizedBox(height: 24),
                    const Text(
                      'Your account details are handled securely.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.sage),
                    ),
                  ],
                ),
              ),
            ),
          );
          if (constraints.maxWidth < 900) return form;
          return Row(children: [
            const Expanded(child: _BrandPanel()),
            Expanded(child: form),
          ]);
        }),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE4E9DD),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A LITTLE SPACE FOR YOU',
                  style: TextStyle(
                    letterSpacing: 3,
                    color: AppTheme.sage,
                    fontSize: 12,
                  )),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(48),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1DCC7),
                  borderRadius: BorderRadius.vertical(
                      top: Radius.circular(160), bottom: Radius.circular(32)),
                ),
                child: const Icon(Icons.self_improvement,
                    size: 120, color: AppTheme.sage),
              ),
              const SizedBox(height: 40),
              Text('Find your balance.\nMove at your pace.',
                  style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 20),
              const Text(
                  'Mindful movement. Everyday strength.\nYour Pilates practice starts here.',
                  style: TextStyle(
                      fontSize: 17, height: 1.6, color: AppTheme.sage)),
            ],
          ),
        ),
      ),
    );
  }
}
