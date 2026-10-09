import 'package:flutter/material.dart';

import 'app_theme.dart';

enum AppStatusTone { success, pending, neutral, error }

class AppStatusChip extends StatelessWidget {
  const AppStatusChip({super.key, required this.label, required this.tone});

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppStatusTone.success => (
          background: const Color(0xFFE3E9DD),
          foreground: AppTheme.sage,
          icon: Icons.check_circle_outline,
        ),
      AppStatusTone.pending => (
          background: const Color(0xFFF7E9C9),
          foreground: const Color(0xFF805B16),
          icon: Icons.schedule_outlined,
        ),
      AppStatusTone.neutral => (
          background: const Color(0xFFECEEEA),
          foreground: const Color(0xFF526057),
          icon: Icons.info_outline,
        ),
      AppStatusTone.error => (
          background: const Color(0xFFF6DEDB),
          foreground: AppTheme.terracotta,
          icon: Icons.error_outline,
        ),
    };
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(colors.icon, size: 15, color: colors.foreground),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: colors.foreground,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                )),
          ],
        ),
      ),
    );
  }
}
