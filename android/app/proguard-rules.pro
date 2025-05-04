# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in android/sdk/tools/proguard/proguard-android.txt

# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# Preserve line number information for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Play Core Library rules
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep all native methods and classes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Firebase rules
-keepattributes Signature
-keepattributes *Annotation*

# For GetX 
-keep class com.getkeepsafe.relinker.** { *; }

# For SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# For model classes
-keep class com.app.mi_expense.models.** { *; }

# For image_picker plugin
-keep class androidx.core.app.CoreComponentFactory { *; }

# For speech_to_text plugin
-keep class android.speech.** { *; }

# Optimize more aggressively
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontskipnonpubliclibraryclassmembers
-dontpreverify
-verbose
-optimizations !code/simplification/arithmetic,!field/*,!class/merging/*

# Remove debug logs in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}