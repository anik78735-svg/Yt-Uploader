import 'package:shared_preferences/shared_preferences.dart';

class RatingService {
  static const _copyCountKey = 'copy_count';
  static const _hasRatedKey = 'has_rated_app';
  static const _userRatingKey = 'user_rating_value';
  static const _promptShownKey = 'rating_prompt_shown';

  /// Har copy action pe call karo. True return kare to popup dikhao.
  static Future<bool> registerCopyAndCheckShouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final bool hasRated = prefs.getBool(_hasRatedKey) ?? false;
    final bool alreadyShown = prefs.getBool(_promptShownKey) ?? false;

    int count = (prefs.getInt(_copyCountKey) ?? 0) + 1;
    await prefs.setInt(_copyCountKey, count);

    if (hasRated || alreadyShown) return false;

    if (count >= 3) {
      await prefs.setBool(_promptShownKey, true);
      return true;
    }
    return false;
  }

  /// User ki rating device storage me save karo
  static Future<void> saveRating(int stars) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userRatingKey, stars);
    await prefs.setBool(_hasRatedKey, true);
  }

  static Future<int?> getSavedRating() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userRatingKey);
  }
}
