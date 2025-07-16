import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import '../models/user_model.dart';
import '../utils/network_utils.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserModel?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      if (kDebugMode) {
        debugPrint('AuthService: Starting sign in process...');
        debugPrint('AuthService: Email: $email');
        debugPrint('AuthService: Firebase Auth instance: ${_auth.toString()}');
      }

      // Check network connectivity with enhanced error handling
      final hasConnection = await NetworkUtils.isConnected();
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }

      final UserCredential result = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Sign in timeout. Please check your connection.');
            },
          );

      if (kDebugMode) {
        debugPrint(
          'AuthService: Sign in successful, user: ${result.user?.email}',
        );
      }

      if (result.user != null) {
        if (kDebugMode) {
          debugPrint('AuthService: Fetching user data from Firestore...');
        }

        // Get user data from Firestore with enhanced retry mechanism
        UserModel? userModel = await NetworkUtils.retryWithBackoff(
          operation: () async {
            final userData = await _firestore
                .collection('users')
                .doc(result.user!.uid)
                .get()
                .timeout(
                  const Duration(seconds: 15),
                  onTimeout: () {
                    throw Exception('Firestore timeout');
                  },
                );

            if (userData.exists) {
              if (kDebugMode) {
                debugPrint('AuthService: User data found in Firestore');
              }
              return UserModel.fromMap(userData.data()!, result.user!.uid);
            } else {
              if (kDebugMode) {
                debugPrint(
                  'AuthService: User data not found in Firestore, creating admin user...',
                );
              }
              // Create admin user document automatically
              final adminUser = UserModel(
                id: result.user!.uid,
                email: email,
                name: 'Admin User',
                role: UserRole.admin,
                phoneNumber: '',
                studentId: '',
                driverLicense: '',
                createdAt: DateTime.now(),
              );

              await _firestore
                  .collection('users')
                  .doc(result.user!.uid)
                  .set(adminUser.toMap())
                  .timeout(
                    const Duration(seconds: 15),
                    onTimeout: () {
                      throw Exception('Firestore write timeout');
                    },
                  );

              if (kDebugMode) {
                debugPrint('AuthService: Admin user created in Firestore');
              }
              return adminUser;
            }
          },
        );

        return userModel;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AuthService: Sign in error: $e');
        debugPrint('AuthService: Error type: ${e.runtimeType}');
      }

      // Provide user-friendly error messages
      throw Exception(NetworkUtils.getErrorMessage(e));
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create new user (Admin only)
  Future<UserModel?> createUser({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
    String? studentId,
    String? driverLicense,
    String? profilePhotoPath,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        String? profilePhotoUrl;

        // Upload profile photo if provided
        if (profilePhotoPath != null) {
          if (kDebugMode) {
            debugPrint('Profile photo path provided: $profilePhotoPath');
          }
          final imageFile = File(profilePhotoPath);
          if (await imageFile.exists()) {
            if (kDebugMode) {
              debugPrint('Image file exists, starting upload...');
            }
            profilePhotoUrl = await convertImageToBase64(imageFile);
            if (kDebugMode) {
              debugPrint('Upload result: $profilePhotoUrl');
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                'Image file does not exist at path: $profilePhotoPath',
              );
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('No profile photo path provided');
          }
        }

        // Create user document in Firestore
        final userModel = UserModel(
          id: result.user!.uid,
          email: email,
          name: name,
          role: role,
          phoneNumber: phoneNumber,
          studentId: studentId,
          driverLicense: driverLicense,
          profilePhoto: profilePhotoUrl,
          createdAt: DateTime.now(),
        );

        final userData = userModel.toMap();
        if (kDebugMode) {
          debugPrint('Saving user data: $userData');
          debugPrint('Profile photo URL: $profilePhotoUrl');
        }

        await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .set(userData);

        return userModel;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Create user error: $e');
      }
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Check network connectivity first
      final hasConnection = await NetworkUtils.isConnected();
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }

      return await NetworkUtils.retryWithBackoff(
        operation: () async {
          final doc = await _firestore
              .collection('users')
              .doc(userId)
              .get()
              .timeout(
                const Duration(seconds: 15),
                onTimeout: () {
                  throw Exception('Firestore timeout');
                },
              );

          if (doc.exists) {
            return UserModel.fromMap(doc.data()!, userId);
          }
          return null;
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get user error: $e');
      }
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(
    String userId,
    Map<String, dynamic> data, {
    String? profilePhotoPath,
  }) async {
    try {
      // Handle profile photo upload if provided
      if (profilePhotoPath != null) {
        if (kDebugMode) {
          debugPrint(
            'Updating user with profile photo path: $profilePhotoPath',
          );
        }
        final imageFile = File(profilePhotoPath);
        if (await imageFile.exists()) {
          if (kDebugMode) {
            debugPrint('Image file exists, uploading...');
          }
          final profilePhotoUrl = await convertImageToBase64(imageFile);
          if (profilePhotoUrl != null) {
            data['profilePhoto'] = profilePhotoUrl;
            if (kDebugMode) {
              debugPrint(
                'Profile photo uploaded and added to data: $profilePhotoUrl',
              );
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('Image file does not exist at path: $profilePhotoPath');
          }
        }
      }

      await _firestore.collection('users').doc(userId).update(data);

      if (kDebugMode) {
        debugPrint('User updated successfully with data: $data');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Update user error: $e');
      }
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Delete the user document from Firestore
      await _firestore.collection('users').doc(userId).delete();

      if (kDebugMode) {
        debugPrint('User document deleted from Firestore successfully.');
        debugPrint(
          'Note: User still exists in Firebase Authentication and needs manual deletion.',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Delete user error: $e');
      }
      rethrow;
    }
  }

  // Get user email by ID (for admin instructions)
  Future<String?> getUserEmailById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data()?['email'] as String?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Get user email error: $e');
      }
      return null;
    }
  }

  // Convert image to base64 for storage in Firestore
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      if (kDebugMode) {
        debugPrint('Converting image to base64: ${imageFile.path}');
        debugPrint('Image file exists: ${await imageFile.exists()}');
        debugPrint('Image file size: ${await imageFile.length()} bytes');
      }

      // Read the image file as bytes
      final bytes = await imageFile.readAsBytes();

      // Convert to base64
      final base64String = base64Encode(bytes);

      if (kDebugMode) {
        debugPrint('Image converted to base64 successfully');
        debugPrint('Base64 length: ${base64String.length}');
      }

      return base64String;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Convert image to base64 error: $e');
      }
      return null;
    }
  }

  // Get all users (Admin only)
  Stream<List<UserModel>> getAllUsers() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get users by role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: role.toString().split('.').last)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      // Check network connectivity
      final hasConnection = await NetworkUtils.isConnected();
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      if (user.email == null) {
        throw Exception('User email is not available');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      if (kDebugMode) {
        debugPrint('Password changed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Change password error: $e');
      }

      // Provide user-friendly error messages
      if (e.toString().contains('wrong-password')) {
        throw Exception('Current password is incorrect');
      } else if (e.toString().contains('weak-password')) {
        throw Exception(
          'New password is too weak. Please use at least 6 characters',
        );
      } else if (e.toString().contains('requires-recent-login')) {
        throw Exception(
          'Please log out and log in again before changing your password',
        );
      } else {
        throw Exception(NetworkUtils.getErrorMessage(e));
      }
    }
  }

  // Reset password via email
  Future<void> resetPassword(String email) async {
    try {
      // Check network connectivity
      final hasConnection = await NetworkUtils.isConnected();
      if (!hasConnection) {
        throw Exception('No internet connection available');
      }

      // Send password reset email
      await _auth.sendPasswordResetEmail(email: email);

      if (kDebugMode) {
        debugPrint('Password reset email sent successfully to: $email');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Reset password error: $e');
      }

      // Provide user-friendly error messages
      if (e.toString().contains('user-not-found')) {
        throw Exception('No account found with this email address');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Invalid email address format');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception('Too many requests. Please try again later');
      } else {
        throw Exception(NetworkUtils.getErrorMessage(e));
      }
    }
  }
}
