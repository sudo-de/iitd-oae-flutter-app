import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class ComplaintService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit a new complaint
  static Future<bool> submitComplaint({
    required UserModel user,
    required String category,
    required String subject,
    required String message,
  }) async {
    try {
      final complaintData = {
        'userId': user.id,
        'userName': user.name,
        'userEmail': user.email,
        'category': category,
        'subject': subject,
        'message': message,
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      };

      await _firestore.collection('complaints').add(complaintData);
      return true;
    } catch (e) {
      throw Exception('Failed to submit complaint: $e');
    }
  }

  // Get complaints by user ID
  static Future<List<Map<String, dynamic>>> getComplaintsByUserId(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('complaints')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort the results in memory to avoid Firestore index requirements
      final complaints = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in descending order (newest first)
      complaints.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );

      return complaints;
    } catch (e) {
      throw Exception('Failed to get complaints: $e');
    }
  }

  // Get all complaints (for admin)
  static Stream<List<Map<String, dynamic>>> getAllComplaints() {
    try {
      return _firestore
          .collection('complaints')
          .snapshots()
          .map((snapshot) {
            final complaints = snapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();

            // Sort by createdAt in descending order (newest first)
            complaints.sort(
              (a, b) => (b['createdAt'] as Timestamp).compareTo(
                a['createdAt'] as Timestamp,
              ),
            );

            return complaints;
          })
          .handleError((error) {
            if (kDebugMode) {
              debugPrint('Error in getAllComplaints stream: $error');
            }
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error setting up getAllComplaints stream: $e');
      }
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  // Get all complaints as Future (fallback method)
  static Future<List<Map<String, dynamic>>> getAllComplaintsFuture() async {
    try {
      final querySnapshot = await _firestore.collection('complaints').get();

      final complaints = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in descending order (newest first)
      complaints.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );

      return complaints;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error in getAllComplaintsFuture: $e');
      }
      throw Exception('Failed to get complaints: $e');
    }
  }

  // Update complaint status
  static Future<bool> updateComplaintStatus(
    String complaintId,
    String status,
  ) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'status': status,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update complaint status: $e');
    }
  }

  // Add response to complaint
  static Future<bool> addComplaintResponse(
    String complaintId,
    String response,
  ) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'response': response,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to add complaint response: $e');
    }
  }

  // Get complaints by status
  static Future<List<Map<String, dynamic>>> getComplaintsByStatus(
    String status,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('complaints')
          .where('status', isEqualTo: status)
          .get();

      // Sort the results in memory to avoid Firestore index requirements
      final complaints = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in descending order (newest first)
      complaints.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );

      return complaints;
    } catch (e) {
      throw Exception('Failed to get complaints by status: $e');
    }
  }

  // Get complaints by category
  static Future<List<Map<String, dynamic>>> getComplaintsByCategory(
    String category,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('complaints')
          .where('category', isEqualTo: category)
          .get();

      // Sort the results in memory to avoid Firestore index requirements
      final complaints = querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();

      // Sort by createdAt in descending order (newest first)
      complaints.sort(
        (a, b) => (b['createdAt'] as Timestamp).compareTo(
          a['createdAt'] as Timestamp,
        ),
      );

      return complaints;
    } catch (e) {
      throw Exception('Failed to get complaints by category: $e');
    }
  }

  // Assign complaint to admin team
  static Future<bool> assignComplaint(
    String complaintId,
    String assignedTo,
  ) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).update({
        'assignedTo': assignedTo,
        'status': 'in progress',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      return true;
    } catch (e) {
      throw Exception('Failed to assign complaint: $e');
    }
  }

  // Delete complaint
  static Future<bool> deleteComplaint(String complaintId) async {
    try {
      await _firestore.collection('complaints').doc(complaintId).delete();
      return true;
    } catch (e) {
      throw Exception('Failed to delete complaint: $e');
    }
  }

  // Check if user has admin privileges
  static Future<bool> checkAdminPrivileges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          if (kDebugMode) {
            debugPrint('User data in DB: $userData');
            debugPrint('User role in DB: ${userData['role']}');
          }
          // Check for different possible role formats
          final role = userData['role'];
          return role == 'admin' || role == 'UserRole.admin';
        }
      }
      if (kDebugMode) {
        debugPrint('User document does not exist for ID: $userId');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking admin privileges: $e');
      }
      return false;
    }
  }

  // Create admin user if doesn't exist
  static Future<bool> createAdminUserIfNeeded(
    String userId,
    String email,
    String name,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        final userData = {
          'email': email,
          'name': name,
          'role': 'admin', // This matches UserModel.toMap() format
          'createdAt': Timestamp.fromDate(DateTime.now()),
        };

        await _firestore.collection('users').doc(userId).set(userData);
        if (kDebugMode) {
          debugPrint('Created admin user for ID: $userId');
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating admin user: $e');
      }
      return false;
    }
  }
}
