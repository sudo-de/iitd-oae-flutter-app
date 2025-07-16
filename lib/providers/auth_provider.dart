import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.signInWithEmailAndPassword(
        email,
        password,
      );
      _currentUser = user;

      // Subscribe to notifications based on user role
      if (user != null) {
        await _subscribeToNotifications(user);
      }

      _isLoading = false;
      notifyListeners();
      return user != null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      // Log the error for debugging
      if (kDebugMode) {
        debugPrint('AuthProvider login error: $e');
      }

      // Re-throw the user-friendly error message
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Unsubscribe from all notifications before logout
      await _unsubscribeFromAllNotifications();

      await _authService.signOut();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> checkAuthState() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        final user = await _authService.getUserById(firebaseUser.uid);
        _currentUser = user;
      } else {
        _currentUser = null;
      }
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthProvider checkAuthState error: $e');
      }
      _currentUser = null;
      notifyListeners();
    }
  }

  void setCurrentUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  // Refresh current user data
  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      final updatedUser = await _authService.getUserById(_currentUser!.id);
      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
      }
    }
  }

  // Subscribe to notifications based on user role
  Future<void> _subscribeToNotifications(UserModel user) async {
    try {
      // Add a small delay to ensure Firebase is fully initialized
      await Future.delayed(const Duration(milliseconds: 500));

      switch (user.role) {
        case UserRole.driver:
          await NotificationService().subscribeDriverToTopics(user.id);
          break;
        case UserRole.student:
          await NotificationService().subscribeStudentToTopics(user.id);
          break;
        case UserRole.admin:
          await NotificationService().subscribeAdminToTopics();
          break;
      }

      if (kDebugMode) {
        debugPrint(
          'User ${user.name} subscribed to notifications for role: ${user.role}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to subscribe user to notifications: $e');
      }
      // Don't let notification failures affect the login process
    }
  }

  // Unsubscribe from all notifications
  Future<void> _unsubscribeFromAllNotifications() async {
    try {
      if (_currentUser != null) {
        // Unsubscribe from role-specific topics
        switch (_currentUser!.role) {
          case UserRole.driver:
            await NotificationService().unsubscribeFromTopic('drivers');
            await NotificationService().unsubscribeFromTopic(
              'driver_${_currentUser!.id}',
            );
            break;
          case UserRole.student:
            await NotificationService().unsubscribeFromTopic('students');
            await NotificationService().unsubscribeFromTopic(
              'student_${_currentUser!.id}',
            );
            break;
          case UserRole.admin:
            await NotificationService().unsubscribeFromTopic('admins');
            await NotificationService().unsubscribeFromTopic(
              'system_notifications',
            );
            break;
        }

        if (kDebugMode) {
          debugPrint('User unsubscribed from notifications');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to unsubscribe from notifications: $e');
      }
    }
  }
}
