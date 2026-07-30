import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = "1.0.0";

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade100;

    return Scaffold(
      appBar: AppBar(
        title: const Text("About App"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Company Logo
              Image.asset(
                "assets/company_logo.png",
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 20),

              Text(
                "PromptVerse",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "Ready-to-Use AI Prompts",
                style: TextStyle(
                  fontSize: 13,
                  color: subTextColor,
                ),
              ),

              const SizedBox(height: 30),

              // About Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "About PromptVerse",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _InfoPoint(
                      text:
                          "PromptVerse gives you ready-to-use, high-quality AI prompts for image generation across Gemini, ChatGPT, and other AI tools.",
                      textColor: textColor,
                    ),

                    _InfoPoint(
                      text:
                          "Browse trending, viral, and category-wise prompts — from portraits to cinematic art — all copy-paste ready.",
                      textColor: textColor,
                    ),

                    _InfoPoint(
                      text:
                          "Unlock exclusive premium prompts through our gift & referral rewards system.",
                      textColor: textColor,
                    ),

                    _InfoPoint(
                      text:
                          "New prompts are added regularly, with instant notifications so you never miss a trending idea.",
                      textColor: textColor,
                    ),

                    const SizedBox(height: 10),

                    Divider(
                      color: isDark
                          ? Colors.white12
                          : Colors.grey.shade300,
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "App Version: $appVersion",
                          style: TextStyle(
                            fontSize: 13,
                            color: subTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Developer Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Developed & Powered by",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      "Bharat Cloud Technologies",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "CEO",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Mr. Anik Kesharwani",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Image.asset(
                      "assets/signature.png",
                      height: 100,
                      width: 240,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPoint extends StatelessWidget {
  final String text;
  final Color textColor;

  const _InfoPoint({
    required this.text,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Icon(
              Icons.check_circle,
              size: 14,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}