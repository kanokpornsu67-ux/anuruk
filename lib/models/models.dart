import 'package:flutter/material.dart';

enum Department { welfare, medical, venue, publication, recreation, houseLeader, media, committee }

extension DepartmentX on Department {
  String get label => switch (this) {
        Department.welfare => 'ฝ่ายสวัสดิการ',
        Department.medical => 'ฝ่ายพยาบาล',
        Department.venue => 'ฝ่ายสถานที่',
        Department.publication => 'ฝ่ายสาราณียกร',
        Department.recreation => 'ฝ่ายสันทนาการ',
        Department.houseLeader => 'ฝ่ายพี่บ้าน',
        Department.media => 'ฝ่ายโสตฯ',
        Department.committee => 'กรรมการ',
      };

  IconData get icon => switch (this) {
        Department.welfare => Icons.restaurant_menu,
        Department.medical => Icons.medical_services,
        Department.venue => Icons.place,
        Department.publication => Icons.campaign,
        Department.recreation => Icons.sports_esports,
        Department.houseLeader => Icons.home_work,
        Department.media => Icons.photo_camera,
        Department.committee => Icons.verified_user,
      };

  Color get color => switch (this) {
        Department.welfare => const Color(0xFFE8833A),
        Department.medical => const Color(0xFFD64545),
        Department.venue => const Color(0xFF2E7D4F),
        Department.publication => const Color(0xFF2B7FB8),
        Department.recreation => const Color(0xFFE0A526),
        Department.houseLeader => const Color(0xFF3F6FD8),
        Department.media => const Color(0xFF8B5CF6),
        Department.committee => const Color(0xFF14746F),
      };
}

enum CampStatus { draft, preparing, ongoing, finished }

extension CampStatusX on CampStatus {
  String get label => switch (this) {
        CampStatus.draft => 'รออนุมัติ',
        CampStatus.preparing => 'เตรียมการ',
        CampStatus.ongoing => 'กำลังดำเนินการ',
        CampStatus.finished => 'เสร็จสิ้น',
      };

  Color get color => switch (this) {
        CampStatus.draft => const Color(0xFFE0A526),
        CampStatus.preparing => const Color(0xFF2B7FB8),
        CampStatus.ongoing => const Color(0xFF2E7D4F),
        CampStatus.finished => const Color(0xFF6B7280),
      };
}

enum TaskStatus { notStarted, inProgress, done }

extension TaskStatusX on TaskStatus {
  String get label => switch (this) {
        TaskStatus.notStarted => 'ยังไม่เริ่ม',
        TaskStatus.inProgress => 'กำลังทำ',
        TaskStatus.done => 'เสร็จแล้ว',
      };

  Color get color => switch (this) {
        TaskStatus.notStarted => const Color(0xFF9CA3AF),
        TaskStatus.inProgress => const Color(0xFF2B7FB8),
        TaskStatus.done => const Color(0xFF2E7D4F),
      };
}

class Member {
  final String id;
  String name, username, phone;
  Department dept;
  int year;
  bool isCommittee;

  Member({
    required this.id,
    required this.name,
    required this.username,
    required this.dept,
    this.phone = '-',
    this.year = 1,
    this.isCommittee = false,
  });
}

class Place {
  final String id;
  String name, province, contact;
  int capacity;

  Place({
    required this.id,
    required this.name,
    required this.province,
    this.capacity = 0,
    this.contact = '-',
  });
}

class Equipment {
  final String id;
  String name, category, unit;
  int total;

  Equipment({
    required this.id,
    required this.name,
    required this.category,
    this.total = 0,
    this.unit = 'ชิ้น',
  });
}

class Camp {
  final String id;
  String name, description;
  DateTime start, end;
  String? placeId;
  int participantTarget;
  CampStatus status;
  CampSummary? summary;
  List<String> images;

  Camp({
    required this.id,
    required this.name,
    required this.start,
    required this.end,
    this.placeId,
    this.participantTarget = 0,
    this.description = '',
    this.status = CampStatus.preparing,
    this.summary,
    List<String>? images,
  }): images = images ?? [];
  Camp copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? start,
    DateTime? end,
    String? placeId,
    int? participantTarget,
    CampStatus? status,
    CampSummary? summary,
  }) {
    return Camp(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      start: start ?? this.start,
      end: end ?? this.end,
      placeId: placeId ?? this.placeId,
      participantTarget: participantTarget ?? this.participantTarget,
      status: status ?? this.status,
      summary: summary ?? this.summary,
    );
  }
}

class CampStaff {
  final String campId, memberId;
  Department dept;
  String role;

  CampStaff({required this.campId, required this.memberId, required this.dept, this.role = 'สตาฟ'});
}

class CampEquipmentUse {
  final String campId, equipmentId;
  int qty;
  int? actualQty;

  CampEquipmentUse({required this.campId, required this.equipmentId, this.qty = 1, this.actualQty});
}

class DeptTask {
  final String id, campId;
  Department dept;
  String title, note;
  TaskStatus status;
  DateTime updatedAt;

  DeptTask({
    required this.id,
    required this.campId,
    required this.dept,
    required this.title,
    this.note = '',
    this.status = TaskStatus.notStarted,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

class CampSummary {
  String text, lessons;
  int actualParticipants;
  List<String> photos;
  DateTime archivedAt;

  CampSummary({
    this.text = '',
    this.lessons = '',
    this.actualParticipants = 0,
    List<String>? photos,
    DateTime? archivedAt,
  })  : photos = photos ?? [],
        archivedAt = archivedAt ?? DateTime.now();
        CampSummary copyWith({
    String? text,
    String? lessons,
    int? actualParticipants,
    List<String>? photos,
    DateTime? archivedAt,
  }) {
    return CampSummary(
      text: text ?? this.text,
      lessons: lessons ?? this.lessons,
      actualParticipants: actualParticipants ?? this.actualParticipants,
      photos: photos ?? List.from(this.photos),
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }
}
class CalendarEvent {
  final String id;
  String title;
  String description;
  DateTime date;
  Department? targetDept;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.targetDept,
  });
}