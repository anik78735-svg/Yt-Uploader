import 'package:flutter/material.dart';
import 'package:yt_uploader_frontend/theme/app_theme.dart';
import 'package:yt_uploader_frontend/widgets/common_widgets.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LoadingOverlay(
        isLoading: _isUploading,
        message: 'Uploading... ${(_uploadProgress * 100).toStringAsFixed(0)}%',
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Upload Video', style: AppTextStyles.heading2),
                const SizedBox(height: AppSpacing.xl),
                _buildDragDropZone(),
                const SizedBox(height: AppSpacing.xl),
                _buildVideoDetails(),
                const SizedBox(height: AppSpacing.xl),
                _buildUploadButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragDropZone() {
    return GlassCard(
      height: 200,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: AppSpacing.lg),
          const Text('Select or drag video file', style: AppTextStyles.body),
          const SizedBox(height: AppSpacing.md),
          Text('MP4, WebM, AVI up to 100MB', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildVideoDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Video Details', style: AppTextStyles.heading3),
        const SizedBox(height: AppSpacing.lg),
        _buildTextField('Title'),
        const SizedBox(height: AppSpacing.lg),
        _buildTextField('Description', maxLines: 3),
        const SizedBox(height: AppSpacing.lg),
        _buildTextField('Tags (comma separated)'),
      ],
    );
  }

  Widget _buildTextField(String label, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.md),
        TextField(
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

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        text: 'Upload Video',
        onPressed: () {
          setState(() {
            _isUploading = true;
            _uploadProgress = 0.0;
          });
          // Simulate upload
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _isUploading = false);
            }
          });
        },
        isLoading: _isUploading,
      ),
    );
  }
}
