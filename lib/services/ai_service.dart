import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class AIService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  GenerativeModel _createModel() {
    if (_apiKey.isEmpty) {
      throw Exception(
        'Thiếu GEMINI_API_KEY. Vui lòng chạy app với --dart-define=GEMINI_API_KEY=your_key.',
      );
    }

    return GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
  }

  Future<String> extractTextFromPdf(String filePath) async {
    try {
      final File file = File(filePath);
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      String text = PdfTextExtractor(document).extractText();
      document.dispose();
      return text;
    } catch (e) {
      print("Lỗi trích xuất PDF: $e");
      return "";
    }
  }

  Future<Map<String, dynamic>> analyzeDocument(
    String filePath,
    String analysisType,
  ) async {
    try {
      final text = await extractTextFromPdf(filePath);
      if (text.isEmpty) {
        throw Exception("Không thể đọc nội dung từ file PDF.");
      }

      final model = _createModel();

      String prompt = "";
      if (analysisType == 'summary') {
        prompt =
            "Bạn là một trợ lý AI học tập. Hãy tóm tắt nội dung tài liệu sau đây bằng tiếng Việt một cách súc tích, làm nổi bật các ý chính và ý nghĩa của chúng. Dưới đây là nội dung tài liệu:\n\n$text";
      } else if (analysisType == 'questions') {
        prompt =
            "Bạn là một trợ lý AI học tập. Hãy đọc nội dung tài liệu sau đây và tạo ra 5 câu hỏi trắc nghiệm tiếng Việt (có 4 đáp án A, B, C, D và chỉ ra đáp án đúng) dựa trên những kiến thức quan trọng nhất. Dưới đây là nội dung tài liệu:\n\n$text";
      }

      final response = await model.generateContent([Content.text(prompt)]);
      final resultText = response.text ?? "Không nhận được phản hồi từ AI.";

      if (analysisType == 'summary') {
        return {'summary': resultText};
      } else {
        return {'questionsText': resultText};
      }
    } catch (e) {
      print("Lỗi AI Analysis: $e");
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> generateQuizFromPdf(
    String filePath,
  ) async {
    try {
      final text = await extractTextFromPdf(filePath);
      if (text.isEmpty) {
        throw Exception("Không thể đọc nội dung từ file PDF.");
      }

      final model = _createModel();

      String prompt =
          """
Bạn là một giáo viên chuyên nghiệp. Dựa vào nội dung tài liệu dưới đây, hãy tạo ra 5 câu hỏi trắc nghiệm tiếng Việt.
YÊU CẦU BẮT BUỘC: Chỉ trả về mảng JSON, không được có bất kỳ chữ nào khác ngoài JSON.
Mảng JSON phải có cấu trúc như sau:
[
  {
    "questionText": "Câu hỏi 1",
    "options": ["A", "B", "C", "D"],
    "correctAnswerIndex": 0,
    "explanation": "Giải thích vì sao chọn A"
  }
]

Nội dung tài liệu:
$text
""";

      final response = await model.generateContent([Content.text(prompt)]);
      final resultText = response.text ?? "";

      String cleanJson = resultText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      List<dynamic> parsed = jsonDecode(cleanJson);

      List<Map<String, dynamic>> questions = parsed
          .map((e) => e as Map<String, dynamic>)
          .toList();
      return questions;
    } catch (e) {
      print("Lỗi tạo Quiz AI: $e");
      rethrow;
    }
  }
}
