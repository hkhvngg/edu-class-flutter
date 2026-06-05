import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../models/announcement_model.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() =>
      _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoLoading = false;
  bool _isPdfDownloading = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final hasVideo =
        widget.announcement.videoUrl != null &&
        widget.announcement.videoUrl!.isNotEmpty;
    if (!hasVideo) return;

    setState(() {
      _isVideoLoading = true;
      _videoError = null;
    });

    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.announcement.videoUrl!),
      );

      await _videoController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blueAccent,
          bufferedColor: Colors.blue.shade100,
          backgroundColor: Colors.grey.shade300,
        ),
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: Icon(
              Icons.play_circle_outline,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 8),
                Text(
                  'Không thể phát video',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) setState(() => _isVideoLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _videoError = 'Không thể tải video: $e';
        });
      }
    }
  }

  @override
  void deactivate() {
    _videoController?.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _openPdf(BuildContext context, String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        UIUtils.showMessageDialog(
          context,
          'Lỗi',
          'Không thể mở file PDF.',
          isError: true,
        );
      }
    }
  }

  Future<void> _downloadPdf(BuildContext context, String url) async {
    if (_isPdfDownloading) return;

    setState(() => _isPdfDownloading = true);
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Không tải được file PDF (${response.statusCode}).');
      }

      final fileName = _pdfFileName();
      final savedPath = await _savePdfFile(
        fileName: fileName,
        bytes: response.bodyBytes,
      );

      if (!context.mounted) return;
      if (savedPath == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã hủy tải file PDF.')));
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã tải PDF: $fileName'),
          action: SnackBarAction(
            label: 'Mở',
            onPressed: () => _openSavedPdf(context, savedPath, url),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        UIUtils.showMessageDialog(
          context,
          'Lỗi',
          'Không thể tải file PDF: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPdfDownloading = false);
      }
    }
  }

  Future<String?> _savePdfFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final pickedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Lưu tài liệu PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );
      if (pickedPath != null && pickedPath.isNotEmpty) {
        return pickedPath;
      }
      return null;
    } catch (_) {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    }
  }

  Future<void> _openSavedPdf(
    BuildContext context,
    String savedPath,
    String originalUrl,
  ) async {
    final uri = savedPath.startsWith('content://')
        ? Uri.parse(savedPath)
        : Uri.file(savedPath);
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (context.mounted) {
      await _openPdf(context, originalUrl);
    }
  }

  String _pdfFileName() {
    final safeTitle = widget.announcement.title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9À-ỹ._ -]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    final baseName = safeTitle.isEmpty
        ? 'tai_lieu_${widget.announcement.id}'
        : safeTitle;
    return baseName.toLowerCase().endsWith('.pdf') ? baseName : '$baseName.pdf';
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf =
        widget.announcement.pdfUrl != null &&
        widget.announcement.pdfUrl!.isNotEmpty;
    final hasVideo =
        widget.announcement.videoUrl != null &&
        widget.announcement.videoUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Giáo trình'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.announcement.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Đăng ngày: ${widget.announcement.createdAt.toLocal().toString().split('.')[0]}',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),

            Text(
              widget.announcement.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            if (hasVideo) ...[
              const Text(
                'Video bài giảng:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 12),

              if (_isVideoLoading) ...[
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          'Đang tải video...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else if (_videoError != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _videoError!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _initVideoPlayer,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              ] else if (_chewieController != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],

            if (hasPdf) ...[
              const Text(
                'Tài liệu đính kèm:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 36,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'File PDF của thông báo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openPdf(
                                context,
                                widget.announcement.pdfUrl!,
                              ),
                              icon: const Icon(Icons.visibility_outlined),
                              label: const Text('Xem PDF'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isPdfDownloading
                                  ? null
                                  : () => _downloadPdf(
                                      context,
                                      widget.announcement.pdfUrl!,
                                    ),
                              icon: _isPdfDownloading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.download_outlined),
                              label: Text(
                                _isPdfDownloading ? 'Đang tải' : 'Tải PDF',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
