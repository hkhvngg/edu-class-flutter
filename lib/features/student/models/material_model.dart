import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialModel {
  final String materialId;
  final String classId;
  final String uploaderId;
  final String title;
  final String fileUrl;
  final String fileType;
  final String analysisType; // 'summary' or 'questions'
  final Map<String, dynamic>? aiResult;
  final String status; // 'processing', 'completed', 'failed'
  final DateTime createdAt;

  MaterialModel({
    required this.materialId,
    required this.classId,
    required this.uploaderId,
    required this.title,
    required this.fileUrl,
    required this.fileType,
    required this.analysisType,
    this.aiResult,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'classId': classId,
      'uploaderId': uploaderId,
      'title': title,
      'fileUrl': fileUrl,
      'fileType': fileType,
      'analysisType': analysisType,
      'aiResult': aiResult,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory MaterialModel.fromMap(Map<String, dynamic> map) {
    return MaterialModel(
      materialId: map['materialId'] ?? '',
      classId: map['classId'] ?? '',
      uploaderId: map['uploaderId'] ?? '',
      title: map['title'] ?? '',
      fileUrl: map['fileUrl'] ?? '',
      fileType: map['fileType'] ?? '',
      analysisType: map['analysisType'] ?? 'summary',
      aiResult: map['aiResult'],
      status: map['status'] ?? 'processing',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
