import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/rating_service.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selected = 0;

  Future<void> _submit() async {
    if (_selected == 0) return;
    await RatingService.saveRating(_selected);
    if (!mounted) return;
    Navigator.pop(context);

    if (_selected >= 4) {
      final uri = Uri.parse("https://play.google.com/store/apps/details?id=com.anik.promptverse");
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thanks for your feedback! We'll keep improving.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enjoying PromptVerse?"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Tap a star to rate your experience"),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final starIndex = i + 1;
              return IconButton(
                icon: Icon(
                  starIndex <= _selected ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () => setState(() => _selected = starIndex),
              );
            }),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Maybe Later")),
        ElevatedButton(onPressed: _submit, child: const Text("Submit")),
      ],
    );
  }
}
