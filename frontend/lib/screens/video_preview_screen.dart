import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../services/rating_service.dart';
import '../widgets/rating_dialog.dart';

class VideoPreviewScreen extends StatefulWidget {
  final String videoUrl;
  final String caption;
  final String category;

  const VideoPreviewScreen({
    super.key,
    required this.videoUrl,
    required this.caption,
    this.category = "Video",
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _controller!.initialize();
      _controller!.setLooping(true);
      _controller!.play();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _afterCopy(BuildContext context) async {
    final shouldPrompt = await RatingService.registerCopyAndCheckShouldPrompt();
    if (shouldPrompt && context.mounted) {
      showDialog(context: context, builder: (_) => const RatingDialog());
    }
  }

  Future<void> _copyAndOpenGemini(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.caption));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Prompt copied! Opening Gemini...")),
      );
    }
    final uri = Uri.parse("https://gemini.google.com/app");
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    await _afterCopy(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category), backgroundColor: Colors.transparent, elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: _isInitialized ? _controller!.value.aspectRatio : 9 / 16,
                  child: _hasError
                      ? Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, size: 50)),
                        )
                      : _isInitialized
                          ? GestureDetector(
                              onTap: () {
                                setState(() {
                                  _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                                });
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  VideoPlayer(_controller!),
                                  if (!_controller!.value.isPlaying)
                                    const Icon(Icons.play_circle_fill, color: Colors.white70, size: 56),
                                ],
                              ),
                            )
                          : Container(
                              color: Colors.black12,
                              child: const Center(child: CircularProgressIndicator(color: Colors.green)),
                            ),
                ),
              ),
              const SizedBox(height: 18),
              if (widget.caption.trim().isNotEmpty) ...[
                const Text("Prompt:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                Text(widget.caption, style: const TextStyle(fontSize: 14, height: 1.4)),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.copy_rounded, color: Colors.green),
                        label: const Text("Copy", style: TextStyle(color: Colors.green)),
                        onPressed: () async {
                          Clipboard.setData(ClipboardData(text: widget.caption));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Prompt Copied!")),
                          );
                          await _afterCopy(context);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Only Gemini here — no GPT button for video prompts
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple.shade50,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.auto_awesome, color: Colors.purple),
                    label: const Text("Open Gemini", style: TextStyle(color: Colors.purple)),
                    onPressed: () => _copyAndOpenGemini(context),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}