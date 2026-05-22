import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';
import '../../../services/ai_service.dart';
import '../../student/models/class_model.dart';
import '../../../models/quiz_model.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key});

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  PlatformFile? _selectedFile;
  String? _selectedClassId;
  bool _isGenerating = false;
  List<QuestionModel>? _generatedQuestions;
  
  final DatabaseService _databaseService = DatabaseService();
  final AIService _aiService = AIService();
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = result.files.first;
        _generatedQuestions = null; // reset preview
      });
    }
  }

  Future<void> _handleGenerateQuiz() async {
    if (_selectedClassId == null) {
      UIUtils.showMessageDialog(context, 'Thông báo', 'Vui lòng chọn lớp học');
      return;
    }
    if (_selectedFile == null || _selectedFile!.path == null) {
      UIUtils.showMessageDialog(context, 'Thông báo', 'Vui lòng chọn file PDF hợp lệ');
      return;
    }

    setState(() {
      _isGenerating = true;
      _generatedQuestions = null;
    });

    try {
      final questionsList = await _aiService.generateQuizFromPdf(_selectedFile!.path!);
      List<QuestionModel> parsedQuestions = questionsList.map((q) => QuestionModel.fromMap(q)).toList();

      if (mounted) {
        setState(() {
          _generatedQuestions = parsedQuestions;
        });
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showMessageDialog(context, 'Thông báo', 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _handleSaveQuiz() async {
    if (_generatedQuestions == null || _selectedClassId == null) return;
    
    setState(() => _isGenerating = true);
    
    try {
      final quizId = DateTime.now().millisecondsSinceEpoch.toString();
      final quiz = QuizModel(
        quizId: quizId,
        classId: _selectedClassId!,
        teacherId: _uid,
        title: _selectedFile!.name.replaceAll('.pdf', '') + ' (AI Quiz)',
        questions: _generatedQuestions!,
        createdAt: DateTime.now(),
      );

      await _databaseService.createQuiz(quiz);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Thành công'),
            content: Text('Đã tạo thành công bài tập với ${_generatedQuestions!.length} câu hỏi và giao cho lớp!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  setState(() {
                    _selectedFile = null;
                    _generatedQuestions = null;
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
        UIUtils.showMessageDialog(context, 'Thông báo', 'Lỗi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tạo bài tập AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn lớp học để giao bài', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      StreamBuilder<List<ClassModel>>(
                        stream: _databaseService.getTeacherClasses(_uid),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                          final classes = snapshot.data!;
                          if (classes.isEmpty) return const Text('Bạn chưa tạo lớp học nào.');
                          
                          return DropdownButtonFormField<String>(
                            value: _selectedClassId,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            hint: const Text('Chọn lớp học'),
                            items: classes.map((c) => DropdownMenuItem(value: c.classId, child: Text(c.className))).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedClassId = val;
                                _generatedQuestions = null;
                              });
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tải lên tài liệu PDF', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('Tải lên tài liệu để AI tự động trích xuất nội dung và tạo câu hỏi trắc nghiệm', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      const SizedBox(height: 20),
                      if (_selectedFile != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.shade200)),
                          child: Row(
                            children: [
                              const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_selectedFile!.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey), 
                                onPressed: () => setState(() {
                                  _selectedFile = null;
                                  _generatedQuestions = null;
                                })
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
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, style: BorderStyle.none), borderRadius: BorderRadius.circular(12)),
                            child: Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300, width: 1), borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.upload_outlined, size: 48, color: Colors.grey.shade500),
                                    const SizedBox(height: 12),
                                    const Text('Nhấn để chọn file PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                if (_generatedQuestions != null) ...[
                  const SizedBox(height: 16),
                  _buildSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Bản xem trước', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                            Text('${_generatedQuestions!.length} câu hỏi', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _generatedQuestions!.length,
                          itemBuilder: (context, index) {
                            final q = _generatedQuestions![index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Câu ${index + 1}: ${q.questionText}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('A. ${q.options[0]}\nB. ${q.options[1]}\nC. ${q.options[2]}\nD. ${q.options[3]}', style: TextStyle(color: Colors.grey.shade700)),
                                  const SizedBox(height: 4),
                                  Text('Đáp án đúng: ${String.fromCharCode(65 + q.correctAnswerIndex)}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                if (_generatedQuestions == null)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _handleGenerateQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('TẠO TRẮC NGHIỆM AI', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isGenerating ? null : _handleSaveQuiz,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('XÁC NHẬN GIAO BÀI TẬP', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Đang xử lý...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 2))]),
      child: child,
    );
  }
}
