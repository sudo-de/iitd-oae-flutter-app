import 'package:cloud_firestore/cloud_firestore.dart';

enum RideStatus { confirmed, completed, cancelled }

extension RideStatusExtension on RideStatus {
  String get displayName {
    switch (this) {
      case RideStatus.confirmed:
        return 'Confirmed';
      case RideStatus.completed:
        return 'Completed';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Ride {
  final String id;
  final String userId;
  final String fromLocation;
  final String toLocation;
  final RideStatus status;
  final DateTime createdAt;
  final DateTime? scheduledTime;
  final String? driverId;
  final double? actualFare;

  Ride({
    required this.id,
    required this.userId,
    required this.fromLocation,
    required this.toLocation,
    required this.status,
    required this.createdAt,
    this.scheduledTime,
    this.driverId,
    this.actualFare,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'scheduledTime': scheduledTime != null
          ? Timestamp.fromDate(scheduledTime!)
          : null,
      'driverId': driverId,
      'actualFare': actualFare,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map, String id) {
    return Ride(
      id: id,
      userId: map['userId'] ?? '',
      fromLocation: map['fromLocation'] ?? '',
      toLocation: map['toLocation'] ?? '',
      status: RideStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => RideStatus.confirmed,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      scheduledTime: map['scheduledTime'] != null
          ? (map['scheduledTime'] as Timestamp).toDate()
          : null,
      driverId: map['driverId'],
      actualFare: map['actualFare']?.toDouble(),
    );
  }

  Ride copyWith({
    String? id,
    String? userId,
    String? fromLocation,
    String? toLocation,
    RideStatus? status,
    DateTime? createdAt,
    DateTime? scheduledTime,
    String? driverId,
    double? actualFare,
  }) {
    return Ride(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      driverId: driverId ?? this.driverId,
      actualFare: actualFare ?? this.actualFare,
    );
  }
}
