import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String classId;
  final String className;
  final String subName;
  final String description;
  final String teacherId;
  final String inviteCode;
  final int color;
  final int studentCount;
  final DateTime createdAt;

  ClassModel({
    required this.classId,
    required this.className,
    required this.subName,
    required this.description,
    required this.teacherId,
    required this.inviteCode,
    required this.color,
    required this.studentCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'className': className,
      'subName': subName,
      'description': description,
      'teacherId': teacherId,
      'inviteCode': inviteCode,
      'color': color,
      'studentCount': studentCount,
      'createdAt': createdAt,
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      classId: map['classId'] ?? '',
      className: map['className'] ?? '',
      subName: map['subName'] ?? '',
      description: map['description'] ?? '',
      teacherId: map['teacherId'] ?? '',
      inviteCode: map['inviteCode'] ?? '',
      color: map['color'] ?? 0xFF0F172A,
      studentCount: map['studentCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
