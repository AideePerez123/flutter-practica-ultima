import 'package:flutter/material.dart';

import '../error/domain_exception.dart';

/// Feedback helpers for consistent snackbars across the app.
class AppFeedback {
  AppFeedback._();

  static void success(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.primary,
        Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.error,
        Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, Theme.of(context).colorScheme.tertiary,
        Icons.info_outline);
  }

  /// Shows a readable message for [cause], unwrapping [DomainException].
  static void fromError(BuildContext context, Object cause) {
    final message =
        cause is DomainException ? cause.message : 'Ocurrió un error: $cause';
    error(context, message);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
  }
}
