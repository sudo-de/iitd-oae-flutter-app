import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/ride.dart';

class RideService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new ride
  static Future<Ride> createRide({
    required String userId,
    required String fromLocation,
    required String toLocation,
    DateTime? scheduledTime,
  }) async {
    try {
      final rideData = {
        'userId': userId,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'status': RideStatus.confirmed.toString().split('.').last,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'scheduledTime': scheduledTime != null
            ? Timestamp.fromDate(scheduledTime)
            : null,
      };

      final docRef = await _firestore.collection('rides').add(rideData);
      final doc = await docRef.get();

      return Ride.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Failed to create ride: $e');
    }
  }

  // Get rides by user ID
  static Future<List<Ride>> getRidesByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('rides')
          .where('userId', isEqualTo: userId)
          .get();

      // Sort the results in memory to avoid Firestore index requirements
      final rides = querySnapshot.docs
          .map((doc) => Ride.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt in descending order (newest first)
      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return rides;
    } catch (e) {
      throw Exception('Failed to get rides: $e');
    }
  }

  // Get rides by driver ID
  static Future<List<Ride>> getRidesByDriverId(String driverId) async {
    try {
      final querySnapshot = await _firestore
          .collection('rides')
          .where('driverId', isEqualTo: driverId)
          .get();

      // Sort the results in memory to avoid Firestore index requirements
      final rides = querySnapshot.docs
          .map((doc) => Ride.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt in descending order (newest first)
      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return rides;
    } catch (e) {
      throw Exception('Failed to get rides by driver: $e');
    }
  }

  // Update ride status
  static Future<bool> updateRideStatus(String rideId, RideStatus status) async {
    try {
      if (kDebugMode) {
        debugPrint(
          'Updating ride $rideId status to ${status.toString().split('.').last}',
        );
      }
      await _firestore.collection('rides').doc(rideId).update({
        'status': status.toString().split('.').last,
      });
      if (kDebugMode) {
        debugPrint('Successfully updated ride status');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating ride status: $e');
      }
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception(
          'Permission denied. Please check if you have driver privileges.',
        );
      }
      throw Exception('Failed to update ride status: $e');
    }
  }

  // Get ride by ID
  static Future<Ride?> getRideById(String rideId) async {
    try {
      final doc = await _firestore.collection('rides').doc(rideId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          return Ride.fromMap(data, doc.id);
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get ride: $e');
    }
  }

  // Get all rides (for admin)
  static Stream<List<Ride>> getAllRides() {
    return _firestore
        .collection('rides')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Ride.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Get all rides as a one-time fetch (fallback for admin)
  static Future<List<Ride>> getAllRidesOnce() async {
    try {
      if (kDebugMode) {
        debugPrint('Fetching all rides from Firestore...');
      }

      final querySnapshot = await _firestore
          .collection('rides')
          .orderBy('createdAt', descending: true)
          .get();

      final rides = querySnapshot.docs
          .map((doc) => Ride.fromMap(doc.data(), doc.id))
          .toList();

      if (kDebugMode) {
        debugPrint('Successfully fetched ${rides.length} rides');
      }

      return rides;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching rides: $e');
      }
      throw Exception('Failed to get all rides: $e');
    }
  }

  // Get rides by status
  static Future<List<Ride>> getRidesByStatus(RideStatus status) async {
    try {
      final querySnapshot = await _firestore
          .collection('rides')
          .where('status', isEqualTo: status.toString().split('.').last)
          .get();

      // Sort the results in memory to avoid Firestore index requirements
      final rides = querySnapshot.docs
          .map((doc) => Ride.fromMap(doc.data(), doc.id))
          .toList();

      // Sort by createdAt in descending order (newest first)
      rides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return rides;
    } catch (e) {
      throw Exception('Failed to get rides by status: $e');
    }
  }

  // Calculate estimated fare based on distance
  static double calculateEstimatedFare(String fromLocation, String toLocation) {
    // Simple fare calculation based on location distance
    // In a real app, this would use actual distance calculation
    const baseFare = 20.0;
    const perKmRate = 5.0;

    // Mock distance calculation (in real app, use actual coordinates)
    final locations = [fromLocation, toLocation];
    double estimatedDistance = 2.0; // Default 2km

    // Adjust distance based on location types
    if (locations.any((loc) => loc.contains('Gate'))) {
      estimatedDistance = 3.0; // Gate to campus locations
    } else if (locations.any((loc) => loc.contains('Hospital'))) {
      estimatedDistance = 1.5; // Hospital is closer
    } else if (locations.any((loc) => loc.contains('LHC'))) {
      estimatedDistance = 1.0; // LHC is central
    }

    return baseFare + (estimatedDistance * perKmRate);
  }

  // Assign driver to ride
  static Future<bool> assignDriver(String rideId, String driverId) async {
    try {
      if (kDebugMode) {
        debugPrint('Assigning driver $driverId to ride $rideId');
      }

      // First, verify the driver has driver role in the database
      final hasDriverRole = await checkDriverPrivileges(driverId);
      if (!hasDriverRole) {
        if (kDebugMode) {
          debugPrint(
            'Driver does not have driver role in database, attempting to create/update driver user...',
          );
        }
        try {
          // Get user info from auth service
          final userDoc = await _firestore
              .collection('users')
              .doc(driverId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null) {
              await createDriverUserIfNeeded(
                driverId,
                userData['email'],
                userData['name'],
              );
            }
          } else {
            if (kDebugMode) {
              debugPrint(
                'Driver user document does not exist, skipping driver assignment',
              );
            }
            // Continue without driver assignment
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Error creating driver user: $e');
          }
          // Continue without driver assignment
        }
      }

      // Update the ride with driver assignment
      await _firestore.collection('rides').doc(rideId).update({
        'driverId': driverId,
        'status': RideStatus.confirmed.toString().split('.').last,
      });
      if (kDebugMode) {
        debugPrint('Successfully assigned driver to ride');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error assigning driver: $e');
      }
      if (e.toString().contains('PERMISSION_DENIED')) {
        throw Exception(
          'Permission denied. Please check if you have driver privileges. Make sure you are logged in as a driver.',
        );
      }
      throw Exception('Failed to assign driver: $e');
    }
  }

  // Update ride fare
  static Future<bool> updateRideFare(String rideId, double fare) async {
    try {
      await _firestore.collection('rides').doc(rideId).update({
        'actualFare': fare,
      });
      return true;
    } catch (e) {
      throw Exception('Failed to update ride fare: $e');
    }
  }

  // Check if user has driver privileges
  static Future<bool> checkDriverPrivileges(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          if (kDebugMode) {
            debugPrint('User data in DB: $userData');
            debugPrint('User role in DB: ${userData['role']}');
          }
          return userData['role'] == 'driver';
        }
      }
      if (kDebugMode) {
        debugPrint('User document does not exist for ID: $userId');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking driver privileges: $e');
      }
      // If there's a permission error, try to create the driver user
      if (e.toString().contains('PERMISSION_DENIED')) {
        if (kDebugMode) {
          debugPrint('Permission denied, attempting to create driver user...');
        }
        return false; // Return false so the calling code will try to create the user
      }
      return false;
    }
  }

  // Create driver user if doesn't exist
  static Future<bool> createDriverUserIfNeeded(
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
          'role': 'driver',
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'isActive': true,
        };

        await _firestore.collection('users').doc(userId).set(userData);
        if (kDebugMode) {
          debugPrint('Created driver user for ID: $userId');
        }
        return true;
      } else {
        // User exists but might not have driver role, update it
        final userData = userDoc.data();
        if (userData != null && userData['role'] != 'driver') {
          await _firestore.collection('users').doc(userId).update({
            'role': 'driver',
          });
          if (kDebugMode) {
            debugPrint('Updated user role to driver for ID: $userId');
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating/updating driver user: $e');
      }
      if (e.toString().contains('PERMISSION_DENIED')) {
        if (kDebugMode) {
          debugPrint(
            'Permission denied while creating driver user. User may not have proper permissions.',
          );
        }
        throw Exception(
          'Permission denied. Please ensure you are logged in with proper credentials.',
        );
      }
      return false;
    }
  }
}
