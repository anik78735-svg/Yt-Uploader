# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Google Sign-In
-keep class com.google.android.gms.auth.** { *; }

# OneSignal
-keep class com.onesignal.** { *; }

# Fix for missing Play Core split install classes (deferred components not used)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
