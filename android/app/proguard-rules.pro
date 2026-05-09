# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Flutter deferred components reference Play Core, which we don't bundle
# (we don't ship dynamic feature modules). Tell R8 to ignore those refs.
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }

# Embedding deferred-components stubs — keep their entry points so R8 doesn't
# try to resolve through them.
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-keep class io.flutter.app.FlutterPlayStoreSplitApplication { *; }

# Google ML Kit Text Recognition
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-dontwarn com.google.mlkit.**

# flutter_local_notifications
-keep class com.dexterous.** { *; }
-keepclassmembers class * extends androidx.appcompat.app.AppCompatActivity { *; }

# Hive (offline DB)
-keep class hive.** { *; }
-keep class * extends hive.HiveObject { *; }
-keepclassmembers class * extends hive.HiveObject { *; }

# Workmanager
-keep class be.tramckrijte.workmanager.** { *; }
-keep class androidx.work.** { *; }

# Kotlin metadata
-keep class kotlin.Metadata { *; }

# Suppress harmless warnings
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**
