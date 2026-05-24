import 'dart:io';
import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';
import '../../../services/ai_service.dart';
import '../models/material_model.dart';
import '../../../utils/file_utils.dart';

class UploadMaterialScreen extends StatefulWidget {
  const UploadMaterialScreen({super.key});

  @override
  State<UploadMaterialScreen> createState() => _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends State<UploadMaterialScreen> {
  String selectedType = 'summary';
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  
  final DatabaseService _databaseService = DatabaseService();
  final AIService _aiService = AIService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withReadStream: true,
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null) {
      UIUtils.showMessageDialog(context, 'Thông báo', 'Vui lòng chọn file PDF');
      return;
    }

    setState(() => _isUploading = true);

    File? tempFile;
    bool isTemp = false;
    try {
      final file = await FileUtils.getLocalFile(_selectedFile!);
      if (file.path != _selectedFile!.path) {
        tempFile = file;
        isTemp = true;
      }

      // 1. Phân tích với Gemini
      final aiResult = await _aiService.analyzeDocument(file.path, selectedType);

      // 2. Lưu vào Firestore với classId = 'personal'
      final materialId = DateTime.now().millisecondsSinceEpoch.toString();
      final material = MaterialModel(
        materialId: materialId,
        classId: 'personal',
        uploaderId: _uid,
        title: _selectedFile!.name,
        fileUrl: 'local', // Do chưa tích hợp Firebase Storage
        fileType: 'pdf',
        analysisType: selectedType,
        aiResult: aiResult,
        status: 'completed',
        createdAt: DateTime.now(),
      );

      await _databaseService.uploadMaterial(material);

      if (mounted) {
        String resultText = selectedType == 'summary' 
            ? aiResult['summary'] 
            : aiResult['questionsText'];
            
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Kết quả phân tích', style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Text(resultText),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedFile = null;
                  });
                },
                child: const Text('Đóng'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(context, 'Thông báo', 'Có lỗi xảy ra: $e');
      }
    } finally {
      if (isTemp && tempFile != null) {
        try {
          await tempFile.delete();
        } catch (e) {
          print("Lỗi xóa file tạm Material: $e");
        }
      }
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Tải lên tài liệu',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0F172A),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lược bỏ phần chọn lớp học vì sinh viên tải lên là tự ôn tập cá nhân

                // Mặc định luôn là Tóm tắt (selectedType = 'summary')

                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tải lên tài liệu PDF',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tải lên đề cương hoặc tài liệu học tập để nhận tóm tắt tự động bằng AI',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      
                      if (_selectedFile != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFile!.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () => setState(() => _selectedFile = null),
                              ),
                            ],
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _pickFile,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: DottedBorderWidget(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.upload_outlined, size: 48, color: Colors.grey.shade500),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Nhấn để chọn file PDF',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _handleUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('TẢI LÊN & PHÂN TÍCH', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('AI đang đọc và phân tích...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTypeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? const Color(0xFF0F172A) : Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? const Color(0xFF0F172A) : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class DottedBorderWidget extends StatelessWidget {
  final Widget child;
  const DottedBorderWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashPainter(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: child,
      ),
    );
  }
}

class DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    double dashWidth = 5, dashSpace = 3, startX = 0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      canvas.drawLine(Offset(startX, size.height), Offset(startX + dashWidth, size.height), paint);
      startX += dashWidth + dashSpace;
    }

    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashWidth), paint);
      canvas.drawLine(Offset(size.width, startY), Offset(size.width, startY + dashWidth), paint);
      startY += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
