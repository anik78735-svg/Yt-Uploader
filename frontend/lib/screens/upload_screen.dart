import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/screens/schedule_screen.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _videoFile;
  String? _fileName;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.pickFiles(type: FileType.video);
    if (result == null || result.files.single.path == null) return;
    setState(() {
      _videoFile = File(result.files.single.path!);
      _fileName = result.files.single.name;
    });
  }

  void _goToSchedule() {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a video file first')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleScreen(
          videoFile: _videoFile!,
          title: _titleController.text,
          description: _descriptionController.text,
          tags: _tagsController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Video', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: _pickVideo,
                child: GlassCard(
                  height: 200,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.cloud_upload_rounded, size: 48, color: AppColors.primary),
                      const SizedBox(height: AppSpacing.lg),
                      Text(_fileName ?? 'Select or drag video file', style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.md),
                      Text('MP4, WebM, AVI up to 100MB', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Video Details', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Title', controller: _titleController, maxLength: 100),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Description', controller: _descriptionController, maxLines: 3, maxLength: 500),
              const SizedBox(height: AppSpacing.lg),
              _buildTextField('Tags (comma separated)', controller: _tagsController),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: GradientButton(text: 'Next', onPressed: _goToSchedule),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, {required TextEditingController controller, int maxLines = 1, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.body),
            if (maxLength != null) ...[
              const Spacer(),
              Text('${controller.text.length}/$maxLength', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          buildCounter: maxLength == null ? null : (_, {required currentLength, required isFocused, maxLength}) => Text('$currentLength/$maxLength', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
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
