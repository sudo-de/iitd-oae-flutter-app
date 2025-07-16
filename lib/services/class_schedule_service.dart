import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/class_schedule.dart';

class ClassScheduleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'classSchedules';

  // Get all class schedules for a user
  static Future<List<ClassSchedule>> getClassSchedulesByUserId(
    String userId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final schedules = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            final id = doc.id;
            if (id.isEmpty) {
              if (kDebugMode) {
                debugPrint('Warning: Found document with empty ID');
              }
              return null;
            }
            return ClassSchedule.fromMap({'id': id, ...data});
          })
          .where((schedule) => schedule != null)
          .cast<ClassSchedule>()
          .toList();

      // Sort in memory instead of using Firestore ordering
      schedules.sort((a, b) {
        final dayOrder = {
          'Monday': 1,
          'Tuesday': 2,
          'Wednesday': 3,
          'Thursday': 4,
          'Friday': 5,
          'Saturday': 6,
          'Sunday': 7,
        };

        final dayComparison = (dayOrder[a.day] ?? 0).compareTo(
          dayOrder[b.day] ?? 0,
        );
        if (dayComparison != 0) return dayComparison;

        return a.time.compareTo(b.time);
      });

      return schedules;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting class schedules: $e');
      }
      rethrow;
    }
  }

  // Get a single class schedule by ID
  static Future<ClassSchedule?> getClassScheduleById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return ClassSchedule.fromMap({'id': doc.id, ...doc.data()!});
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting class schedule: $e');
      }
      rethrow;
    }
  }

  // Create a new class schedule
  static Future<ClassSchedule> createClassSchedule(
    ClassSchedule classSchedule,
  ) async {
    try {
      final docRef = await _firestore
          .collection(_collection)
          .add(classSchedule.toMap());
      return classSchedule.copyWith(id: docRef.id);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error creating class schedule: $e');
      }
      rethrow;
    }
  }

  // Update an existing class schedule
  static Future<void> updateClassSchedule(ClassSchedule classSchedule) async {
    try {
      // Validate that the ID is not empty
      if (classSchedule.id.isEmpty) {
        throw ArgumentError('Document ID cannot be empty');
      }

      await _firestore
          .collection(_collection)
          .doc(classSchedule.id)
          .update(classSchedule.copyWith(updatedAt: DateTime.now()).toMap());
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error updating class schedule: $e');
      }
      rethrow;
    }
  }

  // Delete a class schedule
  static Future<void> deleteClassSchedule(String id) async {
    try {
      // Validate that the ID is not empty
      if (id.isEmpty) {
        throw ArgumentError('Document ID cannot be empty');
      }

      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting class schedule: $e');
      }
      rethrow;
    }
  }

  // Get class schedules by day
  static Future<List<ClassSchedule>> getClassSchedulesByDay(
    String userId,
    String day,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('day', isEqualTo: day)
          .get();

      final schedules = querySnapshot.docs
          .map((doc) {
            final data = doc.data();
            final id = doc.id;
            if (id.isEmpty) {
              if (kDebugMode) {
                debugPrint('Warning: Found document with empty ID');
              }
              return null;
            }
            return ClassSchedule.fromMap({'id': id, ...data});
          })
          .where((schedule) => schedule != null)
          .cast<ClassSchedule>()
          .toList();

      // Sort by time in memory
      schedules.sort((a, b) => a.time.compareTo(b.time));

      return schedules;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting class schedules by day: $e');
      }
      rethrow;
    }
  }

  // Check if a time slot is available for a user on a specific day
  static Future<bool> isTimeSlotAvailable(
    String userId,
    String day,
    String time, {
    String? excludeId,
  }) async {
    try {
      // Get all schedules for the user and day, then filter in memory
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('day', isEqualTo: day)
          .get();

      final conflictingSchedules = querySnapshot.docs.where((doc) {
        final scheduleData = doc.data();
        final scheduleTime = scheduleData['time'] as String? ?? '';
        final docId = doc.id;

        // Check if time matches and it's not the excluded document
        return scheduleTime == time &&
            (excludeId == null || docId != excludeId);
      }).toList();

      return conflictingSchedules.isEmpty;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking time slot availability: $e');
      }
      rethrow;
    }
  }
}
