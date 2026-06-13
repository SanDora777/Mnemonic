# Flutter / Play release — safe defaults if you later enable minification (R8).
# With isMinifyEnabled = false, this file is unused but kept for future tightening.

-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Gson / Firebase (common reflection issues if minify is enabled)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.errorprone.annotations.**
