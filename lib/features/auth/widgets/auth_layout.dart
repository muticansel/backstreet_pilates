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
          final isCompact = constraints.maxWidth < 900;
          final foreground = isCompact ? Colors.white : AppTheme.ink;
          final form = Align(
            alignment: Alignment.topCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
                  decoration: isCompact
                      ? null
                      : BoxDecoration(
                          color: AppTheme.cream.withValues(alpha: .93),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .65)),
                        ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(children: [
                        Icon(Icons.spa_outlined, color: foreground, size: 30),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text('Backstreet Pilates',
                              style: TextStyle(
                                letterSpacing: 3,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: foreground,
                              )),
                        ),
                        const Spacer(),
                        IconTheme(
                          data: IconThemeData(color: foreground),
                          child: const LanguageMenuButton(),
                        ),
                      ]),
                      const SizedBox(height: 42),
                      Text(title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(color: foreground)),
                      const SizedBox(height: 12),
                      Text(subtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: foreground)),
                      const SizedBox(height: 32),
                      Theme(
                        data: Theme.of(context).copyWith(
                          filledButtonTheme: FilledButtonThemeData(
                            style: FilledButton.styleFrom(
                              backgroundColor: isCompact
                                  ? AppTheme.terracotta
                                  : AppTheme.sage,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                              foregroundColor: isCompact
                                  ? const Color(0xFFE4CFA9)
                                  : AppTheme.sage,
                            ),
                          ),
                        ),
                        child: DefaultTextStyle(
                          style: TextStyle(color: foreground),
                          child: child,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        AppLocalizations.of(context)
                            .text('secureAccountDetail'),
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: foreground),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          if (isCompact) {
            return Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/images/auth-studio-background.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(.35, 0),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xD926382E),
                        Color(0xA626382E),
                        Color(0xBC26382E),
                      ],
                    ),
                  ),
                ),
                form,
              ],
            );
          }
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
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/auth-studio-background.png',
          fit: BoxFit.cover,
          alignment: const Alignment(.35, 0),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xE626382E), Color(0xC026382E), Color(0x9926382E)],
            ),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).text('authBrandEyebrow'),
                      style: const TextStyle(
                        letterSpacing: 3,
                        color: Color(0xFFE4CFA9),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 28),
                  Container(
                    height: 76,
                    width: 76,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(38),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .28)),
                    ),
                    child: const Icon(Icons.self_improvement,
                        size: 38, color: Colors.white),
                  ),
                  const SizedBox(height: 34),
                  Text(AppLocalizations.of(context).text('authBrandTitle'),
                      style:
                          Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                fontSize: 46,
                              )),
                  const SizedBox(height: 18),
                  Text(AppLocalizations.of(context).text('authBrandDetail'),
                      style: const TextStyle(
                          fontSize: 17, height: 1.6, color: Color(0xFFF7F5EF))),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
