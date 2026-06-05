import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/assignment_model.dart';
import '../../../services/database_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/ui_utils.dart';

class SubmitAssignmentScreen extends StatefulWidget {
  final AssignmentModel assignment;

  const SubmitAssignmentScreen({super.key, required this.assignment});

  @override
  State<SubmitAssignmentScreen> createState() => _SubmitAssignmentScreenState();
}

class _SubmitAssignmentScreenState extends State<SubmitAssignmentScreen> {
  final _contentController = TextEditingController();
  final _databaseService = DatabaseService();
  final _storageService = StorageService();
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  AssignmentSubmissionModel? _existingSubmission;
  PlatformFile? _selectedFile;
  bool _isLoading = true;
  bool _isSubmitting = false;

  bool get _isClosed =>
      widget.assignment.isOverdue && !widget.assignment.allowLateSubmissions;

  @override
  void initState() {
    super.initState();
    _loadSubmission();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadSubmission() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final submission = await _databaseService.getAssignmentSubmission(
        widget.assignment.assignmentId,
        user.uid,
      );
      if (!mounted) return;
      setState(() {
        _existingSubmission = submission;
        _contentController.text = submission?.content ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Không thể tải bài nộp: $e',
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'ppt',
        'pptx',
        'jpg',
        'jpeg',
        'png',
        'zip',
        'txt',
      ],
    );

    if (result != null) {
      setState(() => _selectedFile = result.files.first);
    }
  }

  Future<void> _submitAssignment() async {
    if (_isClosed) {
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Bài tập đã quá hạn và không cho phép nộp muộn',
      );
      return;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty &&
        _selectedFile == null &&
        _existingSubmission?.fileUrl == null) {
      UIUtils.showMessageDialog(
        context,
        'Thông báo',
        'Vui lòng nhập nội dung hoặc chọn file bài làm',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);
    try {
      String? fileName = _existingSubmission?.fileName;
      String? fileUrl = _existingSubmission?.fileUrl;

      if (_selectedFile != null) {
        final path = _selectedFile!.path;
        if (path == null) {
          UIUtils.showMessageDialog(
            context,
            'Thông báo',
            'Không thể đọc file đã chọn',
          );
          setState(() => _isSubmitting = false);
          return;
        }

        fileName = _selectedFile!.name;
        fileUrl = await _storageService.uploadAssignmentSubmissionFile(
          uid: user.uid,
          assignmentId: widget.assignment.assignmentId,
          file: File(path),
          originalFileName: _selectedFile!.name,
        );
      }

      String studentName = user.displayName ?? user.email ?? 'Học viên';
      try {
        final userModel = await _databaseService.getUser(user.uid);
        if (userModel != null && userModel.fullName.isNotEmpty) {
          studentName = userModel.fullName;
        }
      } catch (_) {}

      final now = DateTime.now();
      final submission = AssignmentSubmissionModel(
        submissionId: '${widget.assignment.assignmentId}_${user.uid}',
        assignmentId: widget.assignment.assignmentId,
        classId: widget.assignment.classId,
        studentId: user.uid,
        studentName: studentName,
        content: content,
        fileName: fileName,
        fileUrl: fileUrl,
        isLate: now.isAfter(widget.assignment.dueDate),
        submittedAt: now,
      );

      await _databaseService.submitAssignment(submission);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã nộp bài thành công!'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(
          context,
          'Thông báo',
          'Không thể nộp bài: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _openExistingFile() async {
    final fileUrl = _existingSubmission?.fileUrl;
    if (fileUrl == null || fileUrl.isEmpty) return;

    final uri = Uri.parse(fileUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.assignment;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Nộp bài tập',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                              assignment.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  assignment.isOverdue
                                      ? Icons.warning_amber_rounded
                                      : Icons.event_outlined,
                                  color: assignment.isOverdue
                                      ? Colors.orange
                                      : Colors.blue,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Hạn nộp: ${_dateFormat.format(assignment.dueDate)}',
                                    style: TextStyle(
                                      color: assignment.isOverdue
                                          ? Colors.orange.shade800
                                          : Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              assignment.description,
                              style: const TextStyle(height: 1.5),
                            ),
                            if (_isClosed)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFFECACA),
                                  ),
                                ),
                                child: const Text(
                                  'Bài tập đã đóng. Giảng viên không cho phép nộp muộn.',
                                  style: TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_existingSubmission != null)
                        _buildSection(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF22C55E),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Bài đã nộp',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_existingSubmission!.isLate) ...[
                                    const SizedBox(width: 8),
                                    _buildLateChip(),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lần nộp gần nhất: ${_dateFormat.format(_existingSubmission!.submittedAt)}',
                              ),
                              if (_existingSubmission!.fileName != null) ...[
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: _openExistingFile,
                                  icon: const Icon(Icons.attach_file),
                                  label: Text(_existingSubmission!.fileName!),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildSection(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Nội dung bài làm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _contentController,
                              minLines: 5,
                              maxLines: 8,
                              enabled: !_isClosed,
                              decoration: InputDecoration(
                                hintText:
                                    'Nhập câu trả lời, ghi chú hoặc đường dẫn bài làm...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_selectedFile != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.blue.shade100,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file_outlined,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFile!.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _formatFileSize(
                                              _selectedFile!.size,
                                            ),
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          setState(() => _selectedFile = null),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: _isClosed ? null : _pickFile,
                                icon: const Icon(Icons.attach_file_rounded),
                                label: const Text('Chọn file bài làm'),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _isSubmitting || _isClosed
                              ? null
                              : _submitAssignment,
                          icon: const Icon(Icons.upload_rounded),
                          label: Text(
                            _existingSubmission == null
                                ? 'NỘP BÀI'
                                : 'CẬP NHẬT BÀI NỘP',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                if (_isSubmitting)
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

  Widget _buildLateChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Muộn',
        style: TextStyle(
          color: Color(0xFF92400E),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    final mb = bytes / 1024 / 1024;
    if (mb >= 1) return '${mb.toStringAsFixed(2)} MB';
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
}
