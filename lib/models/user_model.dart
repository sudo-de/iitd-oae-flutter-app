import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserRole { admin, student, driver }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final String? studentId; // For students
  final String? driverLicense; // For drivers
  final DateTime createdAt;

  final DateTime? startDate; // For students
  final DateTime? endDate; // For students
  final DateTime? joinedDate; // For drivers
  final String? bankName; // For drivers
  final String? bankAccount; // For drivers
  final String? ifscCode; // For drivers
  final String? profilePhoto; // Profile photo URL

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.studentId,
    this.driverLicense,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.joinedDate,
    this.bankName,
    this.bankAccount,
    this.ifscCode,
    this.profilePhoto,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final profilePhoto = map['profilePhoto'];
    if (kDebugMode) {
      debugPrint('Parsing user data for ID: $id');
      debugPrint('Profile photo from map: $profilePhoto');
      debugPrint('Full map: $map');
    }

    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.student,
      ),
      phoneNumber: map['phoneNumber'],
      studentId: map['studentId'],
      driverLicense: map['driverLicense'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      startDate: map['startDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['startDate'])
          : null,
      endDate: map['endDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['endDate'])
          : null,
      joinedDate: map['joinedDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['joinedDate'])
          : null,
      bankName: map['bankName'],
      bankAccount: map['bankAccount'],
      ifscCode: map['ifscCode'],
      profilePhoto: profilePhoto,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'studentId': studentId,
      'driverLicense': driverLicense,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate?.millisecondsSinceEpoch,
      'endDate': endDate?.millisecondsSinceEpoch,
      'joinedDate': joinedDate?.millisecondsSinceEpoch,
      'bankName': bankName,
      'bankAccount': bankAccount,
      'ifscCode': ifscCode,
      'profilePhoto': profilePhoto,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? phoneNumber,
    String? studentId,
    String? driverLicense,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? joinedDate,
    String? bankName,
    String? bankAccount,
    String? ifscCode,
    String? profilePhoto,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      studentId: studentId ?? this.studentId,
      driverLicense: driverLicense ?? this.driverLicense,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      joinedDate: joinedDate ?? this.joinedDate,
      bankName: bankName ?? this.bankName,
      bankAccount: bankAccount ?? this.bankAccount,
      ifscCode: ifscCode ?? this.ifscCode,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}
