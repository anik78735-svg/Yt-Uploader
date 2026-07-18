import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule Videos', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xl),
              _buildCalendar(),
              const SizedBox(height: AppSpacing.xl),
              _buildScheduledVideos(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('May 2025', style: AppTextStyles.bodyLarge),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.chevron_left), onPressed: () {}),
                  IconButton(
                      icon: const Icon(Icons.chevron_right), onPressed: () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(35, (index) {
              final day = (index % 35) + 1;
              final isToday = day == 15;
              return Container(
                decoration: BoxDecoration(
                  color: isToday ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Center(
                  child: Text(
                    day.toString(),
                    style: TextStyle(
                      color: isToday ? Colors.white : AppColors.textSecondary,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledVideos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Upcoming Uploads', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.lg),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return GlassCard(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Video Title ${index + 1}',
                      style: AppTextStyles.bodyLarge),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'May ${15 + index}, 2025 • 10:00 PM',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: const Text('Scheduled',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.primary)),
                      ),
                      GestureDetector(
                        onTap: () {},
                        child: const Icon(Icons.more_vert_rounded,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
