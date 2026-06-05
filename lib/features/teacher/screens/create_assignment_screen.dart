import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/assignment_model.dart';
import '../../../services/database_service.dart';
import '../../../services/notification_service.dart';
import '../../../utils/ui_utils.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;
  final String className;

  const CreateAssignmentScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _databaseService = DatabaseService();
  final _notificationService = NotificationService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _allowLateSubmissions = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dueDate),
    );
    if (time == null) return;

    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _saveAssignment() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Vui lòng nhập tiêu đề bài tập',
      );
      return;
    }
    if (description.isEmpty) {
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Vui lòng nhập nội dung/yêu cầu bài tập',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final assignmentId = DateTime.now().millisecondsSinceEpoch.toString();
      final assignment = AssignmentModel(
        assignmentId: assignmentId,
        classId: widget.classId,
        teacherId: user.uid,
        title: title,
        description: description,
        dueDate: _dueDate,
        allowLateSubmissions: _allowLateSubmissions,
        createdAt: DateTime.now(),
      );

      await _databaseService.createAssignment(assignment);
      String resultMessage = 'Đã tạo bài tập thành công!';
      final tokens = await _databaseService.getClassMemberTokens(
        widget.classId,
      );

      if (tokens.isEmpty) {
        resultMessage =
            'Đã tạo bài tập, nhưng chưa có thiết bị học viên nào nhận thông báo đẩy. Học viên cần đăng nhập lại và cho phép thông báo.';
      } else {
        try {
          final sentCount = await _notificationService.sendNotificationToMultiple(
            title: 'Bài tập mới: $title',
            body:
                '${widget.className} - Hạn nộp: ${_dateFormat.format(_dueDate)}',
            fcmTokens: tokens,
            data: {
              'type': 'assignment',
              'classId': widget.classId,
              'assignmentId': assignmentId,
            },
          );
          resultMessage =
              'Đã tạo bài tập và gửi thông báo đẩy tới $sentCount/${tokens.length} thiết bị học viên.';
        } catch (e) {
          resultMessage =
              'Đã tạo bài tập, nhưng gửi thông báo đẩy thất bại: $e';
        }
      }

      if (!mounted) return;

      await UIUtils.showMessageDialog(
        context,
        'Thông báo',
        resultMessage,
        isError: resultMessage.contains('thất bại'),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(
          context,
          'Không thể tạo bài tập',
          _friendlyAssignmentError(e),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Tạo bài tập',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.className,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bài tập sẽ được giao cho lớp này',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Thông tin bài tập',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Tiêu đề',
                          prefixIcon: const Icon(Icons.assignment_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        minLines: 5,
                        maxLines: 8,
                        decoration: InputDecoration(
                          labelText: 'Nội dung/yêu cầu',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Deadline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFEFF6FF),
                          child: Icon(Icons.event_outlined, color: Colors.blue),
                        ),
                        title: Text(_dateFormat.format(_dueDate)),
                        subtitle: const Text('Hạn nộp bài'),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickDueDate,
                      ),
                      const Divider(),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cho phép nộp muộn'),
                        subtitle: const Text(
                          'Học viên vẫn có thể nộp sau deadline và bài sẽ được đánh dấu muộn',
                        ),
                        value: _allowLateSubmissions,
                        activeThumbColor: const Color(0xFF0F172A),
                        onChanged: (value) =>
                            setState(() => _allowLateSubmissions = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveAssignment,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text(
                      'GIAO BÀI TẬP',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  String _friendlyAssignmentError(Object error) {
    final message = error.toString();
    if (message.contains('permission-denied')) {
      return 'Bạn không có quyền giao bài tập cho lớp này. Vui lòng kiểm tra tài khoản giảng viên hoặc quyền Firebase.';
    }
    if (message.contains('network') || message.contains('SocketException')) {
      return 'Không thể kết nối mạng. Vui lòng kiểm tra internet rồi thử lại.';
    }
    return 'Không thể tạo bài tập lúc này. Chi tiết: $message';
  }
}
