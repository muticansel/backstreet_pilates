import 'package:flutter/material.dart';

import 'app_theme.dart';

class AppSnackBars {
  const AppSnackBars._();

  static SnackBar success(String message) => SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.sage,
        showCloseIcon: true,
        closeIconColor: Colors.white,
        content: Text(message, style: const TextStyle(color: Colors.white)),
      );
}

/// App-wide feedback that is inserted above the root navigator's overlay.
/// Unlike a Scaffold SnackBar, it remains visible when a modal dialog is open.
class AppNotifications {
  AppNotifications._();

  static final navigatorKey = GlobalKey<NavigatorState>();
  static OverlayEntry? _current;

  static void success(String message) => _show(message, AppTheme.sage);

  static void error(String message) => _show(message, AppTheme.terracotta);

  static void _show(String message, Color color) {
    _dismiss(_current);
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        left: 16,
        right: 16,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () => _dismiss(entry),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(message,
                      style: const TextStyle(color: Colors.white)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    _current = entry;
    overlay.insert(entry);
    Future<void>.delayed(const Duration(seconds: 4), () {
      _dismiss(entry);
    });
  }

  static void _dismiss(OverlayEntry? entry) {
    if (entry == null || _current != entry) return;
    entry.remove();
    _current = null;
  }
}
