import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NetworkUtils {
  static Future<bool> isConnected() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('Network connectivity check failed: $e');
      }
      return false;
    }
  }

  static Future<bool> isFirebaseReachable() async {
    try {
      final result = await InternetAddress.lookup('firebase.google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase connectivity check failed: $e');
      }
      return false;
    }
  }

  static Future<String> getConnectionStatus() async {
    try {
      final connected = await isConnected();
      if (connected) {
        final firebaseReachable = await isFirebaseReachable();
        if (firebaseReachable) {
          return 'Connected';
        } else {
          return 'Connected (Firebase unreachable)';
        }
      } else {
        return 'No internet connection';
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Error checking connection status: $error');
      }
      return 'Connection check failed';
    }
  }

  // Enhanced network check with Firestore connectivity test
  static Future<bool> hasFirestoreConnection() async {
    try {
      // First check basic internet connectivity
      final hasInternet = await isConnected();
      if (!hasInternet) {
        return false;
      }

      // Test Firestore connection with a simple ping-like operation
      // Use a timeout to avoid hanging
      await FirebaseFirestore.instance
          .collection('_health') // Use a non-existent collection for testing
          .limit(1)
          .get()
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              throw Exception('Firestore connection timeout');
            },
          );

      return true;
    } catch (e) {
      // If we get a permission denied error, it means Firestore is reachable
      // but we don't have access to that collection (which is expected)
      if (e.toString().contains('permission-denied')) {
        return true; // Firestore is reachable
      }

      if (kDebugMode) {
        debugPrint('Firestore connectivity check failed: $e');
      }
      return false;
    }
  }

  // Check for specific SSL/connection errors
  static bool isSSLConnectionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('ssl') ||
        errorString.contains('certificate') ||
        errorString.contains('handshake') ||
        errorString.contains('broken pipe') ||
        errorString.contains('connection abort') ||
        errorString.contains('i/o error');
  }

  // Check for Firestore specific errors
  static bool isFirestoreError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('firestore') ||
        errorString.contains('unavailable') ||
        errorString.contains('end of stream') ||
        errorString.contains('managedchannelimpl') ||
        errorString.contains('watchstream');
  }

  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    // SSL/Connection specific errors
    if (isSSLConnectionError(error)) {
      return 'SSL connection error. Please check your network and try again.';
    }

    // Firestore specific errors
    if (isFirestoreError(error)) {
      return 'Database connection error. Please check your internet connection and try again.';
    }

    // General network errors
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable')) {
      return 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('user-not-found')) {
      return 'User not found. Please check your email and password.';
    } else if (errorString.contains('wrong-password')) {
      return 'Incorrect password. Please try again.';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email format.';
    } else if (errorString.contains('too-many-requests')) {
      return 'Too many failed attempts. Please try again later.';
    } else if (errorString.contains('permission-denied')) {
      return 'Access denied. Please contact support.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  // Get detailed error information for debugging
  static Map<String, dynamic> getErrorDetails(dynamic error) {
    return {
      'error': error.toString(),
      'type': error.runtimeType.toString(),
      'isSSL': isSSLConnectionError(error),
      'isFirestore': isFirestoreError(error),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Retry mechanism with exponential backoff
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (attempt < maxRetries) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        if (kDebugMode) {
          debugPrint('Retry attempt $attempt failed: $e');
        }

        if (attempt >= maxRetries) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(delay);
        delay = Duration(seconds: delay.inSeconds * 2);
      }
    }

    throw Exception('All retry attempts failed');
  }
}
