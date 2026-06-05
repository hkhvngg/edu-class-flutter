import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionModel {
  final String sessionId;
  final String classId;
  final String title;
  final String code;
  final bool isOpen;
  final DateTime sessionDate;
  final DateTime createdAt;

  AttendanceSessionModel({
    required this.sessionId,
    required this.classId,
    required this.title,
    required this.code,
    required this.isOpen,
    required this.sessionDate,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'classId': classId,
      'title': title,
      'code': code,
      'isOpen': isOpen,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AttendanceSessionModel.fromMap(Map<String, dynamic> map) {
    return AttendanceSessionModel(
      sessionId: map['sessionId'] ?? '',
      classId: map['classId'] ?? '',
      title: map['title'] ?? '',
      code: map['code'] ?? '',
      isOpen: map['isOpen'] ?? true,
      sessionDate: map['sessionDate'] is Timestamp
          ? (map['sessionDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class AttendanceRecordModel {
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  final String recordId;
  final String sessionId;
  final String classId;
  final String studentId;
  final String studentName;
  final DateTime checkedAt;
  final String? photoUrl;
  final String approvalStatus;
  final String? reviewedBy;
  final DateTime? reviewedAt;

  AttendanceRecordModel({
    required this.recordId,
    required this.sessionId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.checkedAt,
    this.photoUrl,
    this.approvalStatus = statusApproved,
    this.reviewedBy,
    this.reviewedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'recordId': recordId,
      'sessionId': sessionId,
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
      'checkedAt': Timestamp.fromDate(checkedAt),
      'photoUrl': photoUrl,
      'approvalStatus': approvalStatus,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt == null ? null : Timestamp.fromDate(reviewedAt!),
    };
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map) {
    final photoUrl = map['photoUrl'] as String?;
    return AttendanceRecordModel(
      recordId: map['recordId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      checkedAt: map['checkedAt'] is Timestamp
          ? (map['checkedAt'] as Timestamp).toDate()
          : DateTime.now(),
      photoUrl: photoUrl,
      approvalStatus:
          map['approvalStatus'] ??
          ((photoUrl != null && photoUrl.isNotEmpty)
              ? statusPending
              : statusApproved),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] is Timestamp
          ? (map['reviewedAt'] as Timestamp).toDate()
          : null,
    );
  }

  bool get isPending => approvalStatus == statusPending;
  bool get isApproved => approvalStatus == statusApproved;
  bool get isRejected => approvalStatus == statusRejected;
}
