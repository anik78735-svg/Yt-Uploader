import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String supportEmail = "anik78735@gmail.com"; // 👈 Apna email yahan daalo

  Future<void> _sendEmail(BuildContext context, String subject) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );
    if (!await launchUrl(emailUri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email app")),
        );
      }
    }
  }

  void _showFaqDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Frequently Asked Questions"),
        content: const SingleChildScrollView(
          child: Text(
            "Q: How do I use a prompt?\nTap any prompt to copy it instantly.\n\n"
            "Q: Is PromptVerse free?\nYes, all prompts are free to use.\n\n"
            "Q: How do I report an issue?\nUse the 'Report a Bug' option below.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Text(
              "Help & Support",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          _HelpTile(
            icon: Icons.bug_report_outlined,
            iconColor: Colors.red,
            title: "Report a Bug",
            subtitle: "Facing an issue? Let us know",
            onTap: () => _sendEmail(context, "Bug Report - PromptVerse"),
          ),
          _HelpTile(
            icon: Icons.support_agent,
            iconColor: Colors.blue,
            title: "Contact Support",
            subtitle: "Get help from our team",
            onTap: () => _sendEmail(context, "Support Request - PromptVerse"),
          ),
          _HelpTile(
            icon: Icons.lightbulb_outline,
            iconColor: Colors.orange,
            title: "Suggest a Feature",
            subtitle: "Share your ideas with us",
            onTap: () => _sendEmail(context, "Feature Suggestion - PromptVerse"),
          ),
          _HelpTile(
            icon: Icons.help_outline,
            iconColor: Colors.green,
            title: "FAQs",
            subtitle: "Quick answers to common questions",
            onTap: () => _showFaqDialog(context),
          ),
        ],
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HelpTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
