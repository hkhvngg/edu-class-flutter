import 'package:cloud_firestore/cloud_firestore.dart';

class AssignmentModel {
  final String assignmentId;
  final String classId;
  final String teacherId;
  final String title;
  final String description;
  final DateTime dueDate;
  final bool allowLateSubmissions;
  final DateTime createdAt;

  AssignmentModel({
    required this.assignmentId,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.allowLateSubmissions,
    required this.createdAt,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate);

  Map<String, dynamic> toMap() {
    return {
      'assignmentId': assignmentId,
      'classId': classId,
      'teacherId': teacherId,
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'allowLateSubmissions': allowLateSubmissions,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AssignmentModel.fromMap(Map<String, dynamic> map) {
    return AssignmentModel(
      assignmentId: map['assignmentId'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] is Timestamp
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now(),
      allowLateSubmissions: map['allowLateSubmissions'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}

class AssignmentSubmissionModel {
  final String submissionId;
  final String assignmentId;
  final String classId;
  final String studentId;
  final String studentName;
  final String content;
  final String? fileName;
  final String? fileUrl;
  final bool isLate;
  final DateTime submittedAt;

  AssignmentSubmissionModel({
    required this.submissionId,
    required this.assignmentId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.content,
    this.fileName,
    this.fileUrl,
    required this.isLate,
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'submissionId': submissionId,
      'assignmentId': assignmentId,
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
      'content': content,
      'fileName': fileName,
      'fileUrl': fileUrl,
      'isLate': isLate,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  factory AssignmentSubmissionModel.fromMap(Map<String, dynamic> map) {
    return AssignmentSubmissionModel(
      submissionId: map['submissionId'] ?? '',
      assignmentId: map['assignmentId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      content: map['content'] ?? '',
      fileName: map['fileName'],
      fileUrl: map['fileUrl'],
      isLate: map['isLate'] ?? false,
      submittedAt: map['submittedAt'] is Timestamp
          ? (map['submittedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
