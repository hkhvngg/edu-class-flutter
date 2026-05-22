import 'package:cloud_firestore/cloud_firestore.dart';

class QuestionModel {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;

  QuestionModel({
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'explanation': explanation,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionText: map['questionText'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex']?.toInt() ?? 0,
      explanation: map['explanation'] ?? '',
    );
  }
}

class QuizModel {
  final String quizId;
  final String classId;
  final String teacherId;
  final String title;
  final List<QuestionModel> questions;
  final DateTime createdAt;

  QuizModel({
    required this.quizId,
    required this.classId,
    required this.teacherId,
    required this.title,
    required this.questions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'classId': classId,
      'teacherId': teacherId,
      'title': title,
      'questions': questions.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory QuizModel.fromMap(Map<String, dynamic> map) {
    return QuizModel(
      quizId: map['quizId'] ?? '',
      classId: map['classId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      questions: List<QuestionModel>.from((map['questions'] ?? []).map((x) => QuestionModel.fromMap(x))),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
    );
  }
}
