import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  /// Đảm bảo lấy được File cục bộ hợp lệ từ PlatformFile.
  /// Nếu file không tồn tại ở path gốc (do cơ chế Scoped Storage của Android 10+ hoặc là Content URI),
  /// hàm này sẽ tự động stream nội dung file và copy ra một file tạm trong thư mục cache của app.
  static Future<File> getLocalFile(PlatformFile platformFile) async {
    final path = platformFile.path;
    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return file;
      }
    }

    try {
      final tempDir = await getTemporaryDirectory();
      if (!tempDir.existsSync()) {
        await tempDir.create(recursive: true);
      }
      final tempFile = File(
        '${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}',
      );
      final IOSink sink = tempFile.openWrite();

      if (platformFile.readStream != null) {
        await sink.addStream(platformFile.readStream!);
      } else if (platformFile.bytes != null) {
        sink.add(platformFile.bytes!);
      } else {
        await sink.addStream(platformFile.xFile.openRead());
      }

      await sink.close();
      return tempFile;
    } catch (e) {
      // ignore: avoid_print
      print("Lỗi tạo file tạm: $e");
      throw Exception("Không thể sao chép tệp tạm. Chi tiết lỗi: $e");
    }
  }
}
