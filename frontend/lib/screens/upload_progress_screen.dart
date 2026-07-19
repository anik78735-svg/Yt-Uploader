import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/config/api_config.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';

class UploadProgressScreen extends StatefulWidget {
  const UploadProgressScreen({
    super.key,
    required this.file,
    required this.title,
    required this.description,
    required this.tags,
    required this.scheduledAt,
  });

  final File file;
  final String title;
  final String description;
  final String tags;
  final DateTime scheduledAt;

  @override
  State<UploadProgressScreen> createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen> {
  final Dio _dio = Dio();
  final CancelToken _cancelToken = CancelToken();
  double _progress = 0.0;
  double _uploadSpeed = 0.0;
  Duration _remainingTime = const Duration();
  int _bytesSent = 0;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _uploadVideo();
  }

  Future<void> _uploadVideo() async {
    final state = context.read<AppState>();
    final headers = await state.getAuthHeadersForRequest();

    try {
      final formData = FormData.fromMap({
        'title': widget.title,
        'description': widget.description,
        'tags': widget.tags,
        'scheduledAt': widget.scheduledAt.toIso8601String(),
        'video': await MultipartFile.fromFile(
          widget.file.path,
          filename: widget.file.uri.pathSegments.isNotEmpty
              ? widget.file.uri.pathSegments.last
              : 'video.mp4',
        ),
      });

      await _dio.post(
        '${ApiConfig.baseUrl}/api/uploads/chunk',
        data: formData,
        options: Options(headers: headers, followRedirects: false),
        cancelToken: _cancelToken,
        onSendProgress: (sent, total) {
          if (!mounted) return;
          if (sent < 0 || total <= 0) return;
          final now = DateTime.now();
          final elapsedMs = now.difference(_lastUpdate).inMilliseconds;
          if (elapsedMs > 0) {
            final delta = sent - _bytesSent;
            final speed = delta / (elapsedMs / 1000);
            _uploadSpeed = speed.clamp(0, double.infinity);
            _bytesSent = sent.toInt();
            _lastUpdate = now;
            final remainingBytes = total - sent;
            final remainingSeconds = remainingBytes / (_uploadSpeed > 0 ? _uploadSpeed : 1);
            _remainingTime = Duration(seconds: remainingSeconds.round());
          }
          setState(() {
            _progress = (sent / total).clamp(0.0, 1.0);
          });
        },
      );

      if (!mounted) return;
      if (_cancelToken.isCancelled) {
        if (!mounted) return;
        Navigator.of(context).pop();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video scheduled successfully')),
      );
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    } on DioException catch (error) {
      if (_cancelToken.isCancelled || error.type == DioExceptionType.cancel) {
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload cancelled')),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.response?.data['error'] ?? 'Upload failed')),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _dio.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_progress * 100).clamp(0, 100).toStringAsFixed(0);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Uploading'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: _progress.isFinite ? _progress : 0.0,
                      strokeWidth: 16,
                      backgroundColor: AppColors.glassBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$percent%', style: AppTextStyles.heading2),
                        const SizedBox(height: AppSpacing.sm),
                        const Text('Uploading...', style: AppTextStyles.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('${(_uploadSpeed / (1024 * 1024)).toStringAsFixed(1)} MB/s', style: AppTextStyles.bodyLarge),
              const SizedBox(height: AppSpacing.sm),
              Text('Remaining: ${_remainingTime.inSeconds > 0 ? '${_remainingTime.inSeconds}s' : '—'}', style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Tooltip(
                    message: 'Coming soon',
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.pause_rounded),
                      label: const Text('Pause'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () {
                      _cancelToken.cancel('cancelled');
                    },
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
