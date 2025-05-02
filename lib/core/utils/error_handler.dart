import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:optional/optional.dart';

class ErrorHandler {
  static Future<Optional<T>> handleMethodCall<T>(
    String methodName,
    Future<T?> Function() operation,
    BuildContext? context,
  ) async {
    try {
      return Optional.ofNullable(await operation());
    } on PlatformException catch (e) {
      log("PlatformException: ${e.code}, ${e.message}");
      _showErrorMessage(context, _getPlatformErrorMessage(e));
      return Optional.empty();
    } on MissingPluginException {
      log("Method $methodName is not implemented!");
      _showErrorMessage(context, 'Method $methodName is not implemented!');
      return Optional.empty();
    } catch (e) {
      log("Unexpected error: $e");
      _showErrorMessage(context, 'Unexpected error: $e');
      return Optional.empty();
    }
  }

  static String _getPlatformErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'ALREADY_CONNECTING':
        return 'Already attempting to connect to a device. Please wait.';
      case 'INVALID_MAC':
        return 'Invalid MAC address format.';
      default:
        return e.message ?? 'Unknown error';
    }
  }

  static void _showErrorMessage(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $message'), backgroundColor: Colors.red),
      );
    }
  }

  static void showSuccessMessage(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.blue),
      );
    }
  }
}
