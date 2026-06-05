import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/database_service.dart';

class TakeQuizScreen extends StatefulWidget {
  final Map<String, dynamic> quizData;

  const TakeQuizScreen({super.key, required this.quizData});

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  int _currentIndex = 0;
  Map<int, int> _selectedAnswers = {};
  bool _isSubmitted = false;

  void _submitQuiz() async {
    final questions = widget.quizData['questions'] ?? [];
    int correctCount = 0;
    for (int i = 0; i < questions.length; i++) {
      if (_selectedAnswers[i] == questions[i]['correctAnswerIndex']) {
        correctCount++;
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final db = DatabaseService();
      final quizId = widget.quizData['quizId'] ?? widget.quizData['id'] ?? '';
      final quizTitle = widget.quizData['title'] ?? 'Bài tập';
      if (quizId.isNotEmpty) {
        await db.saveQuizResult(
          quizId,
          quizTitle,
          user.uid,
          user.displayName ?? 'Học viên',
          correctCount,
          questions.length,
          classId: widget.quizData['classId'],
        );
      }
    }

    setState(() {
      _isSubmitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.quizData['title'] ?? 'Bài tập';
    final List<dynamic> questions = widget.quizData['questions'] ?? [];

    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: const Center(child: Text('Bài tập không có câu hỏi nào.')),
      );
    }

    final currentQ = questions[_currentIndex];
    final options = List<String>.from(currentQ['options'] ?? []);
    final int correctIndex = currentQ['correctAnswerIndex'] ?? 0;
    final String explanation = currentQ['explanation'] ?? '';

    int correctCount = 0;
    if (_isSubmitted) {
      for (int i = 0; i < questions.length; i++) {
        if (_selectedAnswers[i] == questions[i]['correctAnswerIndex']) {
          correctCount++;
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
      ),
      body: Column(
        children: [
          if (_isSubmitted)
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF0F172A),
              width: double.infinity,
              child: Column(
                children: [
                  const Text(
                    'KẾT QUẢ BÀI LÀM',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$correctCount / ${questions.length}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Câu ${_currentIndex + 1}/${questions.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Đã làm: ${_selectedAnswers.length}/${questions.length}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentQ['questionText'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ...List.generate(options.length, (idx) {
                    bool isSelected = _selectedAnswers[_currentIndex] == idx;
                    bool isCorrectOption = idx == correctIndex;

                    Color boxColor = Colors.white;
                    Color borderColor = Colors.grey.shade300;
                    Color textColor = Colors.black87;

                    if (_isSubmitted) {
                      if (isCorrectOption) {
                        boxColor = Colors.green.shade50;
                        borderColor = Colors.green;
                        textColor = Colors.green.shade800;
                      } else if (isSelected && !isCorrectOption) {
                        boxColor = Colors.red.shade50;
                        borderColor = Colors.red;
                        textColor = Colors.red.shade800;
                      }
                    } else if (isSelected) {
                      boxColor = const Color(0xFFEFF6FF);
                      borderColor = Colors.blue;
                      textColor = Colors.blue.shade800;
                    }

                    return GestureDetector(
                      onTap: () {
                        if (!_isSubmitted) {
                          setState(() {
                            _selectedAnswers[_currentIndex] = idx;
                          });
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: boxColor,
                          border: Border.all(
                            color: borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isSelected ||
                                        (_isSubmitted && isCorrectOption)
                                    ? borderColor
                                    : Colors.transparent,
                                border: Border.all(
                                  color:
                                      isSelected ||
                                          (_isSubmitted && isCorrectOption)
                                      ? borderColor
                                      : Colors.grey.shade400,
                                ),
                              ),
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isSelected ||
                                          (_isSubmitted && isCorrectOption)
                                      ? Colors.white
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                options[idx],
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (_isSubmitted && isCorrectOption)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                            if (_isSubmitted && isSelected && !isCorrectOption)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (_isSubmitted && explanation.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Giải thích từ AI:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            explanation,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentIndex > 0
                      ? () => setState(() => _currentIndex--)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black87,
                  ),
                  child: const Text('Câu trước'),
                ),
                if (_currentIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: () => setState(() => _currentIndex++),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Câu sau'),
                  )
                else if (!_isSubmitted)
                  ElevatedButton(
                    onPressed: _selectedAnswers.length == questions.length
                        ? _submitQuiz
                        : () {
                            UIUtils.showMessageDialog(
                              context,
                              'Thông báo',
                              'Vui lòng hoàn thành tất cả các câu hỏi',
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Nộp bài',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Hoàn tất'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
