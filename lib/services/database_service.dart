import 'package:cloud_firestore/cloud_firestore.dart';
import '../features/auth/models/user_model.dart';
import '../features/student/models/class_model.dart';
import '../features/student/models/material_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- USER OPERATIONS ---

  // Lưu hoặc cập nhật thông tin User
  Future<void> saveUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  // Lấy thông tin User theo UID
  Future<UserModel?> getUser(String uid) async {
    var doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
  }

  // --- CLASS OPERATIONS ---

  // Tạo lớp học mới (Dành cho Teacher)
  Future<void> createClass(ClassModel classData) async {
    await _db.collection('classes').doc(classData.classId).set(classData.toMap());
  }

  // Lấy danh sách lớp học của một Giảng viên
  Stream<List<ClassModel>> getTeacherClasses(String teacherId) {
    return _db
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ClassModel.fromMap(doc.data())).toList());
  }

  // Học viên tham gia lớp học bằng mã code
  Future<bool> joinClassWithCode(String studentId, String inviteCode) async {
    // 1. Tìm lớp có mã code tương ứng
    var classQuery = await _db
        .collection('classes')
        .where('inviteCode', isEqualTo: inviteCode)
        .limit(1)
        .get();

    if (classQuery.docs.isEmpty) return false;

    var classId = classQuery.docs.first.id;

    // 2. Thêm bản ghi vào collection enrollments
    await _db.collection('enrollments').add({
      'studentId': studentId,
      'classId': classId,
      'enrolledAt': FieldValue.serverTimestamp(),
    });

    // 3. Cập nhật số lượng học viên trong lớp (optional)
    await _db.collection('classes').doc(classId).update({
      'studentCount': FieldValue.increment(1),
    });

    return true;
  }

  // Lấy danh sách lớp học mà Học viên đã tham gia
  Stream<List<ClassModel>> getStudentClasses(String studentId) {
    // Luồng này phức tạp hơn: Lấy enrollment trước, sau đó lấy thông tin lớp
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

  // --- MATERIAL OPERATIONS ---

  // Đăng tài liệu mới
  Future<void> uploadMaterial(MaterialModel material) async {
    await _db.collection('materials').doc(material.materialId).set(material.toMap());
  }

  // Lấy tài liệu theo lớp học
  Stream<List<MaterialModel>> getMaterialsByClass(String classId) {
    return _db
        .collection('materials')
        .where('classId', isEqualTo: classId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MaterialModel.fromMap(doc.data())).toList());
  }
}
