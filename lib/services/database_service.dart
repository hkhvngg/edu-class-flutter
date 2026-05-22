import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/models/user_model.dart';
import '../features/student/models/class_model.dart';
import '../features/student/models/material_model.dart';
import 'dart:async';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER OPERATIONS ---
  Future<void> saveUser(UserModel user) async {
    try {
      await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      var doc = await _db.collection('users').doc(uid).get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật thông tin profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db.collection('users').doc(uid).update(data)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  // Cập nhật ảnh đại diện
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _db.collection('users').doc(uid).update({
        'profileImageUrl': imageUrl,
      }).timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  // --- CLASS OPERATIONS ---
  Future<void> createClass(ClassModel classData) async {
    await _db.collection('classes').doc(classData.classId).set(classData.toMap());
  }

  Stream<List<ClassModel>> getTeacherClasses(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ClassModel.fromMap(doc.data())).toList());
  }

  Future<bool> joinClassWithCode(String studentId, String inviteCode) async {
    var classQuery = await _db
        .collection('classes')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (classQuery.docs.isEmpty) return false;
    var classId = classQuery.docs.first.id;

    // Kiểm tra xem đã tham gia chưa để tránh trùng lặp
    var existing = await _db.collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .get();
    
    if (existing.docs.isNotEmpty) return true;

    await _db.collection('enrollments').add({
      'studentId': studentId,
      'classId': classId,
      'enrolledAt': FieldValue.serverTimestamp(),
    });

    await _db.collection('classes').doc(classId).update({
      'studentCount': FieldValue.increment(1),
    });

    return true;
  }

  Stream<List<ClassModel>> getStudentClasses(String studentId) {
    return _db
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ClassModel> classes = [];
      for (var doc in snapshot.docs) {
        var classId = doc.data()['classId'];
        var classDoc = await _db.collection('classes').doc(classId).get();
        if (classDoc.exists) {
          classes.add(ClassModel.fromMap(classDoc.data()!));
        }
      }
      return classes;
    });
  }

  // Lấy danh sách học viên của một lớp
  Stream<List<UserModel>> getClassMembers(String classId) {
    return _db
        .collection('enrollments')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .asyncMap((snapshot) async {
      List<UserModel> members = [];
      for (var doc in snapshot.docs) {
        var studentId = doc.data()['studentId'];
        var userDoc = await _db.collection('users').doc(studentId).get();
        if (userDoc.exists) {
          members.add(UserModel.fromMap(userDoc.data()!));
        }
      }
      return members;
    });
  }

  // Lấy danh sách FCM Token của học viên trong lớp
  Future<List<String>> getClassMemberTokens(String classId) async {
    List<String> tokens = [];
    var enrollments = await _db.collection('enrollments').where('classId', isEqualTo: classId).get();
    
    for (var doc in enrollments.docs) {
      var studentId = doc.data()['studentId'];
      var userDoc = await _db.collection('users').doc(studentId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('fcmToken')) {
        tokens.add(userDoc.data()!['fcmToken']);
      }
    }
    return tokens;
  }

  // --- MATERIAL OPERATIONS ---
  Future<void> uploadMaterial(MaterialModel material) async {
    await _db.collection('materials').doc(material.materialId).set(material.toMap());
  }

  Stream<List<MaterialModel>> getMaterialsByClass(String classId) {
    return _db
        .collection('materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MaterialModel.fromMap(doc.data())).toList());
  }

  // --- QUIZ OPERATIONS ---
  Future<void> createQuiz(dynamic quiz) async {
    // using dynamic to avoid import issues if not explicitly imported at the top yet
    await _db.collection('quizzes').doc(quiz.quizId).set(quiz.toMap());
  }

  Stream<List<dynamic>> getQuizzesByClass(String classId) {
    return _db
        .collection('quizzes')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- QUIZ RESULTS ---
  Future<void> saveQuizResult(String quizId, String quizTitle, String studentId, String studentName, int score, int total) async {
    await _db.collection('quiz_results').add({
      'quizId': quizId,
      'quizTitle': quizTitle,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'total': total,
      'submittedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> hasCompletedQuiz(String quizId, String studentId) async {
    var query = await _db.collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return query.docs.isNotEmpty;
  }

  Stream<List<dynamic>> getQuizResults(String quizId) {
    return _db.collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .snapshots()
        .map((snapshot) {
           final docs = snapshot.docs.map((doc) => doc.data()).toList();
           docs.sort((a, b) => (b['score'] as int? ?? 0).compareTo(a['score'] as int? ?? 0));
           return docs;
        });
  }

  Stream<List<dynamic>> getStudentQuizResults(String studentId) {
    return _db.collection('quiz_results')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
           return snapshot.docs.map((doc) {
             var data = doc.data();
             data['id'] = doc.id;
             return data;
           }).toList();
        });
  }

  Future<void> deleteQuizResult(String docId) async {
    await _db.collection('quiz_results').doc(docId).delete();
  }

  Future<void> deleteAllQuizResults(String studentId) async {
    var query = await _db.collection('quiz_results')
        .where('studentId', isEqualTo: studentId)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
  }

  // --- ANNOUNCEMENT OPERATIONS ---
  Stream<List<dynamic>> getAnnouncementsByClass(String classId) {
    return _db
        .collection('announcements')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) {
              var data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }
}
