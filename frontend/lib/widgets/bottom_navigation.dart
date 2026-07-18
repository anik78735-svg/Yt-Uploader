import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';

enum NavigationItem {
  home,
  upload,
  schedule,
  analytics,
  profile,
}

class CustomBottomNavigation extends StatelessWidget {
  final NavigationItem currentItem;
  final Function(NavigationItem) onItemSelected;

  const CustomBottomNavigation({
    super.key,
    required this.currentItem,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(
          top: BorderSide(
            color: AppColors.glassBorder,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavigationButton(
                icon: Icons.home_rounded,
                label: 'Home',
                isSelected: currentItem == NavigationItem.home,
                onTap: () => onItemSelected(NavigationItem.home),
              ),
              _NavigationButton(
                icon: Icons.cloud_upload_rounded,
                label: 'Upload',
                isSelected: currentItem == NavigationItem.upload,
                onTap: () => onItemSelected(NavigationItem.upload),
              ),
              _NavigationButton(
                icon: Icons.calendar_today_rounded,
                label: 'Schedule',
                isSelected: currentItem == NavigationItem.schedule,
                onTap: () => onItemSelected(NavigationItem.schedule),
              ),
              _NavigationButton(
                icon: Icons.analytics_rounded,
                label: 'Analytics',
                isSelected: currentItem == NavigationItem.analytics,
                onTap: () => onItemSelected(NavigationItem.analytics),
              ),
              _NavigationButton(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: currentItem == NavigationItem.profile,
                onTap: () => onItemSelected(NavigationItem.profile),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavigationButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
