import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/assignment_model.dart';
import '../models/attendance_model.dart';
import '../models/grade_model.dart';
import '../features/auth/models/user_model.dart';
import '../features/student/models/class_model.dart';
import '../features/student/models/material_model.dart';
import 'dart:async';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Map<String, dynamic> get defaultSystemSettings => {
    'appName': 'EduClass',
    'supportEmail': 'admin@educlass.com',
    'maintenanceMode': false,
    'allowStudentRegistration': true,
    'allowTeacherRegistration': true,
    'requireEmailVerification': true,
  };

  // --- USER OPERATIONS ---
  Future<void> saveUser(UserModel user) async {
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      var doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .update(data)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, bool>> getNotificationSettings(String uid) async {
    const defaults = {
      'pushEnabled': true,
      'emailEnabled': true,
      'classAnnouncementsEnabled': true,
      'quizRemindersEnabled': true,
    };

    try {
      final doc = await _db
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 10));
      final settings = doc.data()?['notificationSettings'];

      if (settings is Map) {
        return {
          for (final entry in defaults.entries)
            entry.key: settings[entry.key] is bool
                ? settings[entry.key] as bool
                : entry.value,
        };
      }

      return defaults;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateNotificationSettings(
    String uid,
    Map<String, bool> settings,
  ) async {
    try {
      final data = <String, dynamic>{
        'notificationSettings': settings,
        'notificationSettingsUpdatedAt': FieldValue.serverTimestamp(),
      };

      if (settings['pushEnabled'] == false) {
        data['fcmToken'] = FieldValue.delete();
      }

      await _db
          .collection('users')
          .doc(uid)
          .set(data, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final doc = await _db
          .collection('system_settings')
          .doc('app')
          .get()
          .timeout(const Duration(seconds: 10));

      return {
        ...defaultSystemSettings,
        if (doc.exists && doc.data() != null) ...doc.data()!,
      };
    } catch (e) {
      rethrow;
    }
  }

  Stream<Map<String, dynamic>> watchSystemSettings() {
    return _db.collection('system_settings').doc('app').snapshots().map((doc) {
      return {
        ...defaultSystemSettings,
        if (doc.exists && doc.data() != null) ...doc.data()!,
      };
    });
  }

  Future<void> updateSystemSettings(Map<String, dynamic> settings) async {
    try {
      await _db
          .collection('system_settings')
          .doc('app')
          .set({
            ...settings,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfileImage(String uid, String imageUrl) async {
    try {
      await _db
          .collection('users')
          .doc(uid)
          .update({'profileImageUrl': imageUrl})
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      rethrow;
    }
  }

  // --- CLASS OPERATIONS ---
  Future<void> createClass(ClassModel classData) async {
    await _db
        .collection('classes')
        .doc(classData.classId)
        .set(classData.toMap());
  }

  Stream<List<ClassModel>> getTeacherClasses(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<bool> joinClassWithCode(String studentId, String inviteCode) async {
    var classQuery = await _db
        .collection('classes')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (classQuery.docs.isEmpty) return false;
    var classId = classQuery.docs.first.id;

    var existing = await _db
        .collection('enrollments')
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

  Future<List<String>> getClassMemberTokens(String classId) async {
    List<String> tokens = [];
    var enrollments = await _db
        .collection('enrollments')
        .where('classId', isEqualTo: classId)
        .get();

    for (var doc in enrollments.docs) {
      var studentId = doc.data()['studentId'];
      var userDoc = await _db.collection('users').doc(studentId).get();
      final userData = userDoc.data();
      final token = userData?['fcmToken'];
      final settings = userData?['notificationSettings'];
      final classAnnouncementsEnabled =
          settings is! Map || settings['classAnnouncementsEnabled'] != false;
      if (token is String && token.isNotEmpty && classAnnouncementsEnabled) {
        tokens.add(token);
      }
    }
    return tokens;
  }

  // --- MATERIAL OPERATIONS ---
  Future<void> uploadMaterial(MaterialModel material) async {
    await _db
        .collection('materials')
        .doc(material.materialId)
        .set(material.toMap());
  }

  Stream<List<MaterialModel>> getMaterialsByClass(String classId) {
    return _db
        .collection('materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => MaterialModel.fromMap(doc.data()))
              .toList(),
        );
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
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- ASSIGNMENT OPERATIONS ---
  Future<void> createAssignment(AssignmentModel assignment) async {
    await _db
        .collection('assignments')
        .doc(assignment.assignmentId)
        .set(assignment.toMap());
  }

  Stream<List<AssignmentModel>> getAssignmentsByClass(String classId) {
    return _db
        .collection('assignments')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final assignments = snapshot.docs
              .map((doc) => AssignmentModel.fromMap(doc.data()))
              .toList();
          assignments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return assignments;
        });
  }

  Future<AssignmentSubmissionModel?> getAssignmentSubmission(
    String assignmentId,
    String studentId,
  ) async {
    final doc = await _db
        .collection('assignment_submissions')
        .doc('${assignmentId}_$studentId')
        .get();
    if (!doc.exists) return null;
    return AssignmentSubmissionModel.fromMap(doc.data()!);
  }

  Future<void> submitAssignment(AssignmentSubmissionModel submission) async {
    await _db
        .collection('assignment_submissions')
        .doc(submission.submissionId)
        .set(submission.toMap(), SetOptions(merge: true));
  }

  Stream<List<AssignmentSubmissionModel>> getAssignmentSubmissions(
    String assignmentId,
  ) {
    return _db
        .collection('assignment_submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots()
        .map((snapshot) {
          final submissions = snapshot.docs
              .map((doc) => AssignmentSubmissionModel.fromMap(doc.data()))
              .toList();
          submissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
          return submissions;
        });
  }

  // --- QUIZ RESULTS ---
  Future<void> saveQuizResult(
    String quizId,
    String quizTitle,
    String studentId,
    String studentName,
    int score,
    int total, {
    String? classId,
  }) async {
    final data = {
      'quizId': quizId,
      'quizTitle': quizTitle,
      'studentId': studentId,
      'studentName': studentName,
      'score': score,
      'total': total,
      'submittedAt': FieldValue.serverTimestamp(),
    };
    if (classId != null && classId.isNotEmpty) {
      data['classId'] = classId;
    }
    await _db.collection('quiz_results').add(data);
  }

  Future<bool> hasCompletedQuiz(String quizId, String studentId) async {
    var query = await _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .where('studentId', isEqualTo: studentId)
        .get();
    return query.docs.isNotEmpty;
  }

  Stream<List<dynamic>> getQuizResults(String quizId) {
    return _db
        .collection('quiz_results')
        .where('quizId', isEqualTo: quizId)
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.map((doc) => doc.data()).toList();
          docs.sort(
            (a, b) =>
                (b['score'] as int? ?? 0).compareTo(a['score'] as int? ?? 0),
          );
          return docs;
        });
  }

  Stream<List<dynamic>> getStudentQuizResults(String studentId) {
    return _db
        .collection('quiz_results')
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

  Stream<List<dynamic>> getQuizResultsByClass(String classId) {
    return _db
        .collection('quiz_results')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .asyncMap((snapshot) async {
          final docsById = <String, Map<String, dynamic>>{};

          void addResults(QuerySnapshot<Map<String, dynamic>> results) {
            for (final doc in results.docs) {
              final data = doc.data();
              data['id'] = doc.id;
              docsById[doc.id] = data;
            }
          }

          addResults(snapshot);

          final quizSnapshot = await _db
              .collection('quizzes')
              .where('classId', isEqualTo: classId)
              .get();
          final quizIds = quizSnapshot.docs
              .map((doc) => (doc.data()['quizId'] ?? doc.id).toString())
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

          for (var i = 0; i < quizIds.length; i += 10) {
            final end = i + 10 > quizIds.length ? quizIds.length : i + 10;
            final chunk = quizIds.sublist(i, end);
            if (chunk.isEmpty) continue;
            final oldResults = await _db
                .collection('quiz_results')
                .where('quizId', whereIn: chunk)
                .get();
            addResults(oldResults);
          }

          final docs = docsById.values.toList();
          docs.sort((a, b) {
            final aTime =
                (a['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            final bTime =
                (b['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          return docs;
        });
  }

  Future<void> saveManualGrade(ManualGradeModel grade) async {
    await _db
        .collection('manual_grades')
        .doc(grade.gradeId)
        .set(grade.toMap(), SetOptions(merge: true));
  }

  Stream<List<ManualGradeModel>> getManualGradesByClass(String classId) {
    return _db
        .collection('manual_grades')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final grades = snapshot.docs
              .map((doc) => ManualGradeModel.fromMap(doc.data()))
              .toList();
          grades.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return grades;
        });
  }

  Stream<List<ManualGradeModel>> getManualGradesForStudent(
    String classId,
    String studentId,
  ) {
    return _db
        .collection('manual_grades')
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final grades = snapshot.docs
              .map((doc) => ManualGradeModel.fromMap(doc.data()))
              .toList();
          grades.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return grades;
        });
  }

  // --- ATTENDANCE OPERATIONS ---
  Future<void> createAttendanceSession(AttendanceSessionModel session) async {
    await _db
        .collection('attendance_sessions')
        .doc(session.sessionId)
        .set(session.toMap());
  }

  Future<void> updateAttendanceSessionStatus(
    String sessionId,
    bool isOpen,
  ) async {
    await _db.collection('attendance_sessions').doc(sessionId).update({
      'isOpen': isOpen,
    });
  }

  Stream<List<AttendanceSessionModel>> getAttendanceSessionsByClass(
    String classId,
  ) {
    return _db
        .collection('attendance_sessions')
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final sessions = snapshot.docs
              .map((doc) => AttendanceSessionModel.fromMap(doc.data()))
              .toList();
          sessions.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
          return sessions;
        });
  }

  Future<void> markAttendance(AttendanceRecordModel record) async {
    await _db
        .collection('attendance_records')
        .doc(record.recordId)
        .set(record.toMap(), SetOptions(merge: true));
  }

  Future<void> updateAttendanceRecordApproval({
    required String recordId,
    required String approvalStatus,
    required String reviewedBy,
  }) async {
    await _db.collection('attendance_records').doc(recordId).update({
      'approvalStatus': approvalStatus,
      'reviewedBy': reviewedBy,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<AttendanceRecordModel?> getAttendanceRecord(
    String sessionId,
    String studentId,
  ) async {
    final doc = await _db
        .collection('attendance_records')
        .doc('${sessionId}_$studentId')
        .get();
    if (!doc.exists) return null;
    return AttendanceRecordModel.fromMap(doc.data()!);
  }

  Stream<List<AttendanceRecordModel>> getAttendanceRecords(String sessionId) {
    return _db
        .collection('attendance_records')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => AttendanceRecordModel.fromMap(doc.data()))
              .toList();
          records.sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
          return records;
        });
  }

  Stream<List<AttendanceRecordModel>> getStudentAttendanceRecords(
    String classId,
    String studentId,
  ) {
    return _db
        .collection('attendance_records')
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final records = snapshot.docs
              .map((doc) => AttendanceRecordModel.fromMap(doc.data()))
              .toList();
          records.sort((a, b) => b.checkedAt.compareTo(a.checkedAt));
          return records;
        });
  }

  Future<void> deleteQuizResult(String docId) async {
    await _db.collection('quiz_results').doc(docId).delete();
  }

  Future<void> deleteAllQuizResults(String studentId) async {
    var query = await _db
        .collection('quiz_results')
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
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            var data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList(),
        );
  }
}
