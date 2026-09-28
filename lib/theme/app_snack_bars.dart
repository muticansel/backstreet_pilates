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
