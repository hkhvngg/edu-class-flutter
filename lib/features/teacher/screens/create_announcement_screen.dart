import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/announcement_model.dart';
import '../../../services/notification_service.dart';
import '../../../services/database_service.dart';
import '../../../utils/file_utils.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateAnnouncementScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  PlatformFile? _selectedPdf;
  PlatformFile? _selectedVideo;
  bool _isLoading = false;
  double _uploadProgress = 0;
  String _uploadLabel = '';
  final NotificationService _notificationService = NotificationService();

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withReadStream: true,
    );
    if (result != null) {
      setState(() => _selectedPdf = result.files.first);
    }
  }

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withReadStream: true,
    );
    if (result != null) {
      final file = result.files.first;
      // Giới hạn 100MB
      if (file.size > 100 * 1024 * 1024) {
        if (mounted) {
          UIUtils.showMessageDialog(
            context,
            'Lỗi',
            'Video quá lớn. Vui lòng chọn video dưới 100MB.',
            isError: true,
          );
        }
        return;
      }
      setState(() => _selectedVideo = file);
    }
  }

  void _removeVideo() {
    setState(() => _selectedVideo = null);
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Vui lòng nhập tiêu đề và nội dung',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0;
      _uploadLabel = '';
    });

    try {
      String? pdfUrl;
      String? videoUrl;

      if (_selectedPdf != null) {
        setState(() => _uploadLabel = 'Đang tải PDF...');
        final storageRef = FirebaseStorage.instance.ref().child(
          'announcements_pdfs/${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        final File pdfFile = await FileUtils.getLocalFile(_selectedPdf!);
        final uploadTask = await storageRef.putFile(
          pdfFile,
          SettableMetadata(contentType: 'application/pdf'),
        );
        pdfUrl = await uploadTask.ref.getDownloadURL();

        // Xóa file tạm nếu tạo file mới
        if (pdfFile.path != _selectedPdf!.path) {
          try {
            await pdfFile.delete();
          } catch (e) {
            print("Lỗi xóa file tạm PDF: $e");
          }
        }
      }

      if (_selectedVideo != null) {
        setState(() {
          _uploadLabel = 'Đang tải video...';
          _uploadProgress = 0;
        });

        final ext = _selectedVideo!.extension ?? 'mp4';
        final storageRef = FirebaseStorage.instance.ref().child(
          'announcements_videos/${DateTime.now().millisecondsSinceEpoch}.$ext',
        );

        final File videoFile = await FileUtils.getLocalFile(_selectedVideo!);
        final uploadTask = storageRef.putFile(
          videoFile,
          SettableMetadata(contentType: 'video/$ext'),
        );

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (mounted) {
            setState(() {
              _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
            });
          }
        });

        final snapshot = await uploadTask;
        videoUrl = await snapshot.ref.getDownloadURL();

        // Xóa file tạm nếu tạo file mới
        if (videoFile.path != _selectedVideo!.path) {
          try {
            await videoFile.delete();
          } catch (e) {
            print("Lỗi xóa file tạm video: $e");
          }
        }
      }

      setState(() => _uploadLabel = 'Đang lưu...');
      final String uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = FirebaseFirestore.instance
          .collection('announcements')
          .doc();

      final announcement = AnnouncementModel(
        id: docRef.id,
        classId: widget.classId,
        title: _titleController.text,
        description: _descriptionController.text,
        pdfUrl: pdfUrl,
        videoUrl: videoUrl,
        teacherId: uid,
        createdAt: DateTime.now(),
      );

      await docRef.set(announcement.toMap());

      String resultMessage = 'Đã đăng thông báo thành công!';
      final DatabaseService db = DatabaseService();
      List<String> tokens = await db.getClassMemberTokens(widget.classId);

      if (tokens.isEmpty) {
        resultMessage =
            'Đã đăng thông báo, nhưng chưa có thiết bị học viên nào nhận thông báo đẩy. Học viên cần đăng nhập lại và cho phép thông báo.';
      } else {
        setState(() => _uploadLabel = 'Đang gửi thông báo đẩy...');
        try {
          final sentCount = await _notificationService
              .sendNotificationToMultiple(
                title: _titleController.text,
                body: _descriptionController.text,
                fcmTokens: tokens,
                data: {
                  'type': 'class_announcement',
                  'classId': widget.classId,
                  'announcementId': docRef.id,
                },
              );
          resultMessage =
              'Đã đăng thông báo và gửi thông báo đẩy tới học viên.';
        } catch (e) {
          resultMessage =
              'Đã đăng thông báo, nhưng gửi thông báo đẩy thất bại: $e';
        }
      }

      if (mounted) {
        await UIUtils.showMessageDialog(
          context,
          'Thông báo',
          resultMessage,
          isError: resultMessage.contains('thất bại'),
        );
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(
          context,
          'Không thể đăng thông báo',
          _friendlyAnnouncementError(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _uploadProgress = 0;
          _uploadLabel = '';
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _friendlyAnnouncementError(Object error) {
    final message = error.toString();
    if (message.contains('permission-denied')) {
      return 'Bạn không có quyền đăng thông báo cho lớp này. Vui lòng kiểm tra tài khoản giảng viên hoặc quyền Firebase.';
    }
    if (message.contains('network') || message.contains('SocketException')) {
      return 'Không thể kết nối mạng. Vui lòng kiểm tra internet rồi thử lại.';
    }
    if (message.contains('storage') || message.contains('object-not-found')) {
      return 'Không thể tải tệp đính kèm lên Firebase Storage. Vui lòng thử lại hoặc chọn tệp khác.';
    }
    return 'Không thể đăng thông báo lúc này. Chi tiết: $message';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng Thông báo - ${widget.className}')),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_uploadProgress > 0) ...[
                      CircularProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 16),
                      Text(
                        '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ] else
                      const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    if (_uploadLabel.isNotEmpty)
                      Text(
                        _uploadLabel,
                        style: const TextStyle(color: Colors.grey),
                      ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tiêu đề thông báo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Nội dung',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text('Đính kèm PDF'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _selectedPdf != null
                              ? _selectedPdf!.name
                              : 'Chưa chọn file',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Video bài giảng (Tùy chọn)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedVideo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.videocam,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedVideo!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFileSize(_selectedVideo!.size),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removeVideo,
                            icon: const Icon(Icons.close, color: Colors.red),
                            tooltip: 'Xóa video',
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.video_call, size: 28),
                      label: const Text('Chọn video từ máy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.blue.shade300),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Hỗ trợ: MP4, MOV, AVI... (tối đa 100MB)',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('GỬI & THÔNG BÁO'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
