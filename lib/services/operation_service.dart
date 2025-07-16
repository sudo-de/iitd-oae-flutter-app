import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/async_utils.dart';
import '../utils/network_utils.dart';

/// Service class to handle complex operations and reduce code duplication
class OperationService {
  static final OperationService _instance = OperationService._internal();
  factory OperationService() => _instance;
  OperationService._internal();

  /// Handle complaint operations with proper error handling
  Future<bool> handleComplaintOperation({
    required BuildContext context,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            await operation();
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle user operations with proper error handling
  Future<bool> handleUserOperation({
    required BuildContext context,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            await operation();
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle ride operations with proper error handling
  Future<bool> handleRideOperation({
    required BuildContext context,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            await operation();
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle authentication operations with proper error handling
  Future<bool> handleAuthOperation({
    required BuildContext context,
    required Future<bool> Function() operation,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: operation,
          onSuccess: (result) {
            if (result) {
              AsyncUtils.showSuccessSnackBar(context, successMessage);
            }
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle data loading operations with proper error handling
  Future<T?> handleDataLoading<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    required void Function(T data) onSuccess,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<T>(
      operation: operation,
      onSuccess: onSuccess,
      errorMessage: errorMessage,
      showLoading: showLoading,
    );
  }

  /// Handle file operations with proper error handling
  Future<bool> handleFileOperation({
    required BuildContext context,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            await operation();
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle notification operations with proper error handling
  Future<bool> handleNotificationOperation({
    required BuildContext context,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            await operation();
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle network operations with retry logic
  Future<T?> handleNetworkOperation<T>({
    required BuildContext context,
    required Future<T> Function() operation,
    required void Function(T data) onSuccess,
    String? errorMessage,
    int maxRetries = 3,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<T>(
      operation: () => NetworkUtils.retryWithBackoff(
        operation: operation,
        maxRetries: maxRetries,
      ),
      onSuccess: onSuccess,
      errorMessage: errorMessage,
      showLoading: showLoading,
    );
  }

  /// Handle batch operations with progress tracking
  Future<bool> handleBatchOperation({
    required BuildContext context,
    required List<Future<void> Function()> operations,
    required String successMessage,
    String? errorMessage,
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            for (int i = 0; i < operations.length; i++) {
              await operations[i]();

              // Update progress if needed
              if (kDebugMode) {
                debugPrint(
                  'Batch operation progress: ${i + 1}/${operations.length}',
                );
              }
            }
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle conditional operations
  Future<bool> handleConditionalOperation({
    required BuildContext context,
    required bool Function() condition,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    String? conditionFailedMessage,
    bool showLoading = true,
  }) async {
    if (!condition()) {
      if (conditionFailedMessage != null) {
        AsyncUtils.showErrorSnackBar(context, conditionFailedMessage);
      }
      return false;
    }

    return await context.safeAsync<bool>(
          operation: () async {
            await operation();
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }

  /// Handle time-sensitive operations
  Future<bool> handleTimedOperation({
    required BuildContext context,
    required Future<void> Function() operation,
    required String successMessage,
    String? errorMessage,
    Duration timeout = const Duration(seconds: 30),
    bool showLoading = true,
  }) async {
    return await context.safeAsync<bool>(
          operation: () async {
            await operation().timeout(
              timeout,
              onTimeout: () {
                throw Exception(
                  'Operation timed out after ${timeout.inSeconds} seconds',
                );
              },
            );
            return true;
          },
          onSuccess: (result) {
            AsyncUtils.showSuccessSnackBar(context, successMessage);
          },
          errorMessage: errorMessage,
          showLoading: showLoading,
        ) ??
        false;
  }
}
