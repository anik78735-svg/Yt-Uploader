/// Cloudinary video URL se automatically thumbnail (poster frame) URL banata hai.
String getVideoThumbnail(String videoUrl) {
  if (videoUrl.isEmpty) return '';
  final lastDot = videoUrl.lastIndexOf('.');
  if (lastDot == -1) return videoUrl;
  return "${videoUrl.substring(0, lastDot)}.jpg";
}
