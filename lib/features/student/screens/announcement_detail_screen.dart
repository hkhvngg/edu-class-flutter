import 'package:flutter/material.dart';
import '../../../utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../models/announcement_model.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final AnnouncementModel announcement;

  const AnnouncementDetailScreen({super.key, required this.announcement});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isVideoLoading = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    final hasVideo = widget.announcement.videoUrl != null &&
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
            child: Icon(Icons.play_circle_outline, color: Colors.white54, size: 64),
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
        UIUtils.showMessageDialog(context, 'Lỗi', 'Không thể mở file PDF.', isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPdf = widget.announcement.pdfUrl != null && widget.announcement.pdfUrl!.isNotEmpty;
    final hasVideo = widget.announcement.videoUrl != null &&
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
            // Title
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

            // Description
            Text(
              widget.announcement.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Video Player Section
            if (hasVideo) ...[
              const Text('Video bài giảng:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),

              if (_isVideoLoading) ...[
                // Loading state
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
                        Text('Đang tải video...', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ] else if (_videoError != null) ...[
                // Error state
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
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
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
                // Player ready
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

            // PDF Section
            if (hasPdf) ...[
              const Text('Tài liệu đính kèm:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 36),
                  title: const Text('Tải / Xem file PDF'),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _openPdf(context, widget.announcement.pdfUrl!),
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
