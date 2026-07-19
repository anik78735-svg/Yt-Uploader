import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:yt_uploader_frontend/state/app_state.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class UpcomingVideosScreen extends StatefulWidget {
  const UpcomingVideosScreen({super.key});

  @override
  State<UpcomingVideosScreen> createState() => _UpcomingVideosScreenState();
}

class _UpcomingVideosScreenState extends State<UpcomingVideosScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  List<dynamic> _schedules = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final schedules = await context.read<AppState>().fetchSchedules();
    if (!mounted) return;
    setState(() {
      _schedules = schedules;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upcoming Videos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildScheduleList(_filterUpcoming),
                _buildScheduleList(_filterCompleted),
              ],
            ),
    );
  }

  List<dynamic> get _filterUpcoming => _schedules.where((item) {
        final status = (item['status'] ?? '').toString().toUpperCase();
        return status == 'PENDING' || status == 'UPLOADING';
      }).toList();

  List<dynamic> get _filterCompleted => _schedules.where((item) {
        final status = (item['status'] ?? '').toString().toUpperCase();
        return status == 'SUCCESS' || status == 'FAILED';
      }).toList();

  Widget _buildScheduleList(List<dynamic> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No videos found'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final schedule = items[index];
        final status = (schedule['status'] ?? '').toString().toUpperCase();
        final scheduledAt = DateTime.tryParse(schedule['scheduledAt']?.toString() ?? '') ?? DateTime.now();
        return GlassCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(Icons.play_circle_outline_rounded, size: 36, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule['title'] ?? 'Untitled', style: AppTextStyles.bodyLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.sm),
                    Text(DateFormat('MMM d, yyyy • hh:mm a').format(scheduledAt), style: AppTextStyles.bodySmall),
                    const SizedBox(height: AppSpacing.sm),
                    _buildStatusChip(status),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'PENDING':
        color = Colors.grey;
        break;
      case 'UPLOADING':
        color = AppColors.primary;
        break;
      case 'SUCCESS':
        color = AppColors.success;
        break;
      case 'FAILED':
        color = AppColors.error;
        break;
      default:
        color = AppColors.textMuted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(status.toLowerCase(), style: TextStyle(color: color, fontSize: 11)),
    );
  }
}
