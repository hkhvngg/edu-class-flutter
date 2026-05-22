import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementModel {
  final String id;
  final String classId;
  final String title;
  final String description;
  final String? pdfUrl;
  final String? videoUrl;
  final String teacherId;
  final DateTime createdAt;

  AnnouncementModel({
    required this.id,
    required this.classId,
    required this.title,
    required this.description,
    this.pdfUrl,
    this.videoUrl,
    required this.teacherId,
    required this.createdAt,
  });

  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String id) {
    return AnnouncementModel(
      id: id,
      classId: map['classId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      pdfUrl: map['pdfUrl'],
      videoUrl: map['videoUrl'],
      teacherId: map['teacherId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'title': title,
      'description': description,
      'pdfUrl': pdfUrl,
      'videoUrl': videoUrl,
      'teacherId': teacherId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
