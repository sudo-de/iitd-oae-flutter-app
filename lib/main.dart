import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'utils/network_utils.dart';
import 'screens/admin_dashboard.dart';
import 'screens/student_dashboard.dart';
import 'screens/driver_dashboard.dart';
import 'screens/login_screen.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'widgets/network_status_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize notification service
    await NotificationService().initialize();

    if (kDebugMode) {
      debugPrint('Firebase and notification service initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Failed to initialize Firebase: $e');
    }
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => app_auth.AuthProvider(),
      child: MaterialApp(
        title: 'IIT Delhi OAE',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.light(
            // Primary colors - Deep corporate blue
            primary: Color(0xFF1E3A8A),
            onPrimary: Color(0xFFFFFFFF),
            primaryContainer: Color(0xFFE0F2FE),
            onPrimaryContainer: Color(0xFF0F172A),

            // Secondary colors - Professional slate
            secondary: Color(0xFF475569),
            onSecondary: Color(0xFFFFFFFF),
            secondaryContainer: Color(0xFFF1F5F9),
            onSecondaryContainer: Color(0xFF1E293B),

            // Tertiary colors - Sophisticated amber
            tertiary: Color(0xFFD97706),
            onTertiary: Color(0xFFFFFFFF),
            tertiaryContainer: Color(0xFFFEF3C7),
            onTertiaryContainer: Color(0xFF92400E),

            // Surface colors - Premium whites and grays
            surface: Color(0xFFFAFAFA),
            onSurface: Color(0xFF0F172A),
            surfaceContainerHighest: Color(0xFFF8FAFC),
            onSurfaceVariant: Color(0xFF64748B),

            // Error colors - Professional red
            error: Color(0xFFDC2626),
            onError: Color(0xFFFFFFFF),
            errorContainer: Color(0xFFFEE2E2),
            onErrorContainer: Color(0xFF991B1B),

            // Outline colors - Refined borders
            outline: Color(0xFFCBD5E1),
            outlineVariant: Color(0xFFE2E8F0),

            // Shadow colors - Subtle shadows
            shadow: Color(0x0F000000),
            scrim: Color(0x40000000),

            // Inverse colors
            inverseSurface: Color(0xFF0F172A),
            onInverseSurface: Color(0xFFF8FAFC),
            inversePrimary: Color(0xFF3B82F6),
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',

          // App bar theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E3A8A),
            foregroundColor: Color(0xFFFFFFFF),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
            ),
          ),

          // Elevated button theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: const Color(0xFFFFFFFF),
              elevation: 1,
              shadowColor: const Color(0x0F000000),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Text button theme
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E3A8A),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Input decoration theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 16),
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
          ),

          // Card theme
          cardTheme: const CardThemeData(
            color: Color(0xFFFFFFFF),
            elevation: 1,
            shadowColor: Color(0x0F000000),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            margin: EdgeInsets.all(8),
          ),

          // Divider theme
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE2E8F0),
            thickness: 1,
            space: 1,
          ),

          // Icon theme
          iconTheme: const IconThemeData(color: Color(0xFF1E3A8A), size: 24),

          // Text theme
          textTheme: const TextTheme(
            displayLarge: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            displayMedium: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            displaySmall: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            headlineLarge: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            headlineMedium: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            headlineSmall: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            titleLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
            titleMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            titleSmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
            bodyLarge: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Color(0xFF0F172A),
            ),
            bodyMedium: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Color(0xFF64748B),
            ),
            bodySmall: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: Color(0xFF94A3B8),
            ),
          ),
        ),
        home: NetworkStatusWidget(
          showDetailedErrors: kDebugMode,
          onRetry: () {
            // Trigger a rebuild of the auth wrapper
            if (kDebugMode) {
              debugPrint('Network retry triggered');
            }
          },
          child: const AuthWrapper(),
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Checking authentication...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: _getUserWithRetry(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading user data...'),
                      ],
                    ),
                  ),
                );
              }

              if (userSnapshot.hasError) {
                if (kDebugMode) {
                  debugPrint('Error loading user data: ${userSnapshot.error}');
                }
                return const LoginScreen();
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                final user = userSnapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  // Check if the widget is still mounted before accessing Provider
                  if (context.mounted) {
                    Provider.of<app_auth.AuthProvider>(
                      context,
                      listen: false,
                    ).setCurrentUser(user);
                  }
                });
                if (kDebugMode) {
                  debugPrint('User role: ${user.role}');
                  debugPrint('User name: ${user.name}');
                  debugPrint('User email: ${user.email}');
                }

                switch (user.role) {
                  case UserRole.admin:
                    if (kDebugMode) {
                      debugPrint('Navigating to AdminDashboard');
                    }
                    return const AdminDashboard();
                  case UserRole.student:
                    if (kDebugMode) {
                      debugPrint('Navigating to StudentDashboard');
                    }
                    return const StudentDashboard();
                  case UserRole.driver:
                    if (kDebugMode) {
                      debugPrint('Navigating to DriverDashboard');
                    }
                    return const DriverDashboard();
                }
              } else {
                if (kDebugMode) {
                  debugPrint('User data is null, returning to login');
                }
              }

              return const LoginScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }

  Future<UserModel?> _getUserWithRetry(String userId) async {
    final authService = AuthService();
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        // Check network connectivity first
        final hasConnection = await NetworkUtils.isConnected();
        if (!hasConnection) {
          throw Exception('No internet connection available');
        }

        final user = await authService.getUserById(userId);
        return user;
      } catch (e) {
        retryCount++;
        if (kDebugMode) {
          debugPrint('AuthWrapper: Attempt $retryCount failed: $e');
        }

        if (retryCount >= maxRetries) {
          if (kDebugMode) {
            debugPrint('AuthWrapper: All retry attempts failed');
          }
          return null;
        }

        // Wait before retrying (exponential backoff)
        await Future.delayed(Duration(seconds: retryCount));
      }
    }
    return null;
  }
}
