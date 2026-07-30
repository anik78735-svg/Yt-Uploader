/// Har category ke liye ek decorative background image URL deta hai
String categoryBackgroundImage(String category) {
  final seed = Uri.encodeComponent(category);
  return "https://picsum.photos/seed/$seed/400/300";
}
