import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Chọn ảnh từ thư viện và upload lên Firebase Storage
  /// Trả về download URL hoặc null nếu người dùng hủy
  Future<String?> pickAndUploadAvatar(String uid) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image == null) return null;

      final File file = File(image.path);
      final String fileName = 'profile_images/$uid.jpg';
      final Reference ref = _storage.ref().child(fileName);

      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> uploadAssignmentSubmissionFile({
    required String uid,
    required String assignmentId,
    required File file,
    required String originalFileName,
  }) async {
    try {
      final safeName = originalFileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final fileName =
          'assignment_submissions/$assignmentId/$uid-${DateTime.now().millisecondsSinceEpoch}-$safeName';
      final ref = _storage.ref().child(fileName);
      final metadata = SettableMetadata(contentType: _contentTypeFor(safeName));

      final uploadTask = ref.putFile(file, metadata);
      final snapshot = await uploadTask;
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> captureAndUploadAttendancePhoto({
    required String uid,
    required String sessionId,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 85,
      );

      if (image == null) return null;

      final file = File(image.path);
      final fileName =
          'attendance_photos/$sessionId/$uid-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      final uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final snapshot = await uploadTask;
      return snapshot.ref.getDownloadURL();
    } catch (e) {
      rethrow;
    }
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.ppt')) return 'application/vnd.ms-powerpoint';
    if (lower.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }
}
