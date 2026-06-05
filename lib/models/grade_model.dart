import 'package:cloud_firestore/cloud_firestore.dart';

class ManualGradeModel {
  final String gradeId;
  final String classId;
  final String studentId;
  final String studentName;
  final String title;
  final double score;
  final double total;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  ManualGradeModel({
    required this.gradeId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.score,
    required this.total,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  double get percent => total <= 0 ? 0 : (score / total) * 100;

  Map<String, dynamic> toMap() {
    return {
      'gradeId': gradeId,
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'score': score,
      'total': total,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ManualGradeModel.fromMap(Map<String, dynamic> map) {
    return ManualGradeModel(
      gradeId: map['gradeId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      title: map['title'] ?? '',
      score: (map['score'] as num?)?.toDouble() ?? 0,
      total: (map['total'] as num?)?.toDouble() ?? 10,
      note: map['note'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }
}
