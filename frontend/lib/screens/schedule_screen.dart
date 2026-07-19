import 'dart:io';
import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/screens/upload_progress_screen.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.videoFile,
    this.title = '',
    this.description = '',
    this.tags = '',
  });

  final File videoFile;
  final String title;
  final String description;
  final String tags;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  late DateTime _scheduledDate;
  late TimeOfDay _scheduledTime;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scheduledDate = DateTime.now();
    _scheduledTime = TimeOfDay.now();
    _titleController.text = widget.title;
    _descriptionController.text = widget.description;
    _tagsController.text = widget.tags;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _scheduledDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _scheduledTime);
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  void _scheduleVideo() {
    final scheduledAt = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadProgressScreen(
          file: widget.videoFile,
          title: _titleController.text,
          description: _descriptionController.text,
          tags: _tagsController.text,
          scheduledAt: scheduledAt,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheduledAt = DateTime(
      _scheduledDate.year,
      _scheduledDate.month,
      _scheduledDate.day,
      _scheduledTime.hour,
      _scheduledTime.minute,
    );
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Schedule Video', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xl),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickDate,
                            child: _buildDateTile('Date', '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickTime,
                            child: _buildDateTile('Time', _scheduledTime.format(context)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        const Icon(Icons.public_rounded, color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: AppSpacing.sm),
                        Text('Timezone: ${DateTime.now().timeZoneName}', style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text('Upload Cost: 10 Diamonds', style: AppTextStyles.bodyLarge.copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Details', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Title', _titleController),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Description', _descriptionController, maxLines: 3),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Tags', _tagsController),
              const SizedBox(height: AppSpacing.xl),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text('Scheduled for: ${scheduledAt.toString()}', style: AppTextStyles.bodySmall),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GradientButton(text: 'Schedule Video', onPressed: _scheduleVideo),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.glassBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
