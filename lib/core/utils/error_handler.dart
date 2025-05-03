import 'package:flutter/material.dart';
import 'package:optional/optional.dart';

import 'logger.dart';

class ErrorHandler {
  ErrorHandler._();

  static Future<Optional<T>> handleMethodCall<T>(
    String methodName,
    Future<T> Function() callback,
    BuildContext? context, {
    bool showErrorMessages = true,
  }) async {
    try {
      final result = await callback();
      return Optional.of(result);
    } catch (e) {
      Logger.e('Error in $methodName', error: e);

      if (context != null && context.mounted && showErrorMessages) {
        _showSnackbar(context, _extractErrorMessage(e), Colors.red);
      }

      return Optional.empty();
    }
  }

  static String _extractErrorMessage(Object error) {
    final msg = error.toString();
    final parts = msg.split('Exception:');
    return parts.length > 1 ? parts.last.trim() : msg;
  }

  static void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  static void showSuccessMessage(BuildContext? context, String message) {
    if (context == null || !context.mounted) return;
    _showSnackbar(context, message, Colors.green);
  }
}
