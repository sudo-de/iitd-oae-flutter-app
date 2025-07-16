import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

/// Utility class to handle async operations safely with BuildContext
class AsyncUtils {
  /// Safely execute an async operation and handle BuildContext usage
  static Future<T?> safeAsyncOperation<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    required void Function(T result) onSuccess,
    void Function(dynamic error)? onError,
    String? errorMessage,
    bool showLoading = true,
    bool showErrorSnackBar = true,
  }) async {
    if (showLoading) {
      _showLoadingSnackBar(context);
    }

    try {
      final result = await operation();

      if (context.mounted) {
        onSuccess(result);
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Async operation failed: $e');
      }

      if (context.mounted) {
        if (showErrorSnackBar) {
          AsyncUtils.showErrorSnackBar(
            context,
            errorMessage ?? 'Operation failed: ${e.toString()}',
          );
        }

        onError?.call(e);
      }

      return null;
    }
  }

  /// Safely navigate after async operation
  static Future<void> safeNavigate({
    required BuildContext context,
    required Future<void> Function() operation,
    required Widget Function() destinationBuilder,
    String? errorMessage,
  }) async {
    try {
      await operation();

      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => destinationBuilder()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          errorMessage ?? 'Navigation failed: ${e.toString()}',
        );
      }
    }
  }

  /// Safely show dialog after async operation
  static Future<void> safeShowDialog({
    required BuildContext context,
    required Future<void> Function() operation,
    required Widget Function() dialogBuilder,
    String? errorMessage,
  }) async {
    try {
      await operation();

      if (context.mounted) {
        showDialog(context: context, builder: (context) => dialogBuilder());
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          errorMessage ?? 'Dialog failed: ${e.toString()}',
        );
      }
    }
  }

  /// Safely update state after async operation
  static Future<void> safeStateUpdate({
    required BuildContext context,
    required Future<void> Function() operation,
    required VoidCallback onSuccess,
    String? errorMessage,
  }) async {
    try {
      await operation();

      if (context.mounted) {
        onSuccess();
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(
          context,
          errorMessage ?? 'Update failed: ${e.toString()}',
        );
      }
    }
  }

  /// Show loading snackbar
  static void _showLoadingSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Processing...'),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottleCall;
  static bool throttle(
    VoidCallback callback, {
    Duration duration = const Duration(milliseconds: 300),
  }) {
    final now = DateTime.now();
    if (_lastThrottleCall == null ||
        now.difference(_lastThrottleCall!) > duration) {
      _lastThrottleCall = now;
      callback();
      return true;
    }
    return false;
  }
}

/// Extension to add safe async methods to BuildContext
extension BuildContextAsyncExtension on BuildContext {
  /// Safely execute async operation with this context
  Future<T?> safeAsync<T>({
    required Future<T> Function() operation,
    required void Function(T result) onSuccess,
    void Function(dynamic error)? onError,
    String? errorMessage,
    bool showLoading = true,
    bool showErrorSnackBar = true,
  }) {
    return AsyncUtils.safeAsyncOperation(
      context: this,
      operation: operation,
      onSuccess: onSuccess,
      onError: onError,
      errorMessage: errorMessage,
      showLoading: showLoading,
      showErrorSnackBar: showErrorSnackBar,
    );
  }

  /// Safely navigate after async operation
  Future<void> safeNavigate({
    required Future<void> Function() operation,
    required Widget Function() destinationBuilder,
    String? errorMessage,
  }) {
    return AsyncUtils.safeNavigate(
      context: this,
      operation: operation,
      destinationBuilder: destinationBuilder,
      errorMessage: errorMessage,
    );
  }

  /// Safely show dialog after async operation
  Future<void> safeShowDialog({
    required Future<void> Function() operation,
    required Widget Function() dialogBuilder,
    String? errorMessage,
  }) {
    return AsyncUtils.safeShowDialog(
      context: this,
      operation: operation,
      dialogBuilder: dialogBuilder,
      errorMessage: errorMessage,
    );
  }

  /// Safely update state after async operation
  Future<void> safeStateUpdate({
    required Future<void> Function() operation,
    required VoidCallback onSuccess,
    String? errorMessage,
  }) {
    return AsyncUtils.safeStateUpdate(
      context: this,
      operation: operation,
      onSuccess: onSuccess,
      errorMessage: errorMessage,
    );
  }
}
