class ClassSchedule {
  final String id;
  final String userId;
  final String className;
  final String instructor;
  final String time;
  final String room;
  final String day;
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassSchedule({
    required this.id,
    required this.userId,
    required this.className,
    required this.instructor,
    required this.time,
    required this.room,
    required this.day,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      className: map['className'] ?? '',
      instructor: map['instructor'] ?? '',
      time: map['time'] ?? '',
      room: map['room'] ?? '',
      day: map['day'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is DateTime
                ? map['createdAt']
                : DateTime.parse(map['createdAt']))
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] is DateTime
                ? map['updatedAt']
                : DateTime.parse(map['updatedAt']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'className': className,
      'instructor': instructor,
      'time': time,
      'room': room,
      'day': day,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ClassSchedule copyWith({
    String? id,
    String? userId,
    String? className,
    String? instructor,
    String? time,
    String? room,
    String? day,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassSchedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      className: className ?? this.className,
      instructor: instructor ?? this.instructor,
      time: time ?? this.time,
      room: room ?? this.room,
      day: day ?? this.day,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ClassSchedule(id: $id, userId: $userId, className: $className, instructor: $instructor, time: $time, room: $room, day: $day)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassSchedule &&
        other.id == id &&
        other.userId == userId &&
        other.className == className &&
        other.instructor == instructor &&
        other.time == time &&
        other.room == room &&
        other.day == day;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        className.hashCode ^
        instructor.hashCode ^
        time.hashCode ^
        room.hashCode ^
        day.hashCode;
  }
}
