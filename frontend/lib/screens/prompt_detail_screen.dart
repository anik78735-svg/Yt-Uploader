import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rating_service.dart';
import '../widgets/rating_dialog.dart';

class PromptDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String promptText;
  final String category;

  const PromptDetailScreen({
    super.key,
    required this.imageUrl,
    required this.promptText,
    required this.category,
  });

  Future<void> _afterCopy(BuildContext context) async {
    final shouldPrompt = await RatingService.registerCopyAndCheckShouldPrompt();
    if (shouldPrompt && context.mounted) {
      showDialog(context: context, builder: (_) => const RatingDialog());
    }
  }

  Future<void> _copyAndOpen(BuildContext context, String url, String appName) async {
    await Clipboard.setData(ClipboardData(text: promptText));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Prompt copied! Opening $appName...")),
      );
    }
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    await _afterCopy(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Full-bleed hero image with gradient + category chip overlay
            Stack(
              children: [
                Hero(
                  tag: imageUrl,
                  child: AspectRatio(
                    aspectRatio: 3 / 4,
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image, size: 50)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.auto_awesome_outlined, size: 18, color: Colors.green),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Prompt",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Prompt text in a soft card for readability + visual separation
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: SelectableText(
                      promptText,
                      style: const TextStyle(fontSize: 14.5, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Copy button — full width, primary action
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "Copy Prompt",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      onPressed: () async {
                        Clipboard.setData(ClipboardData(text: promptText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Prompt Copied!")),
                        );
                        await _afterCopy(context);
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.purple,
                            side: BorderSide(color: Colors.purple.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.auto_awesome, size: 18),
                          label: const Text("Gemini", style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () => _copyAndOpen(context, "https://gemini.google.com/app", "Gemini"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal,
                            side: BorderSide(color: Colors.teal.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text("ChatGPT", style: TextStyle(fontWeight: FontWeight.w600)),
                          onPressed: () => _copyAndOpen(context, "https://chat.openai.com", "ChatGPT"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}