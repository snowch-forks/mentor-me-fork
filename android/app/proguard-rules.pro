# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /usr/local/Cellar/android-sdk/24.3.3/tools/proguard/proguard-android.txt

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep application classes
-keep class com.example.ai_mentor_coach.** { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# HTTP and networking
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# SharedPreferences
-keep class androidx.preference.** { *; }

# Gson (if used for JSON)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes for serialization
-keep class * extends java.io.Serializable { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Optimize
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Keep line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# ADDED: Google Play Core library rules
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep Play Core split install classes
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# LiteRT LLM (Google AI Edge) - Keep all classes and members
-keep class com.google.ai.edge.litertlm.** { *; }
-keepclassmembers class com.google.ai.edge.litertlm.** { *; }
-keepattributes *Annotation*
-dontwarn com.google.ai.edge.litertlm.**

# Kotlin reflection support (required by LiteRT LLM)
-keep class kotlin.reflect.** { *; }
-keep class kotlin.reflect.full.** { *; }
-keep class kotlin.reflect.jvm.** { *; }
-keepclassmembers class kotlin.Metadata {
    *;
}
-dontwarn kotlin.reflect.**

# TensorFlow Lite (required by MediaPipe) - Keep everything
-keep class org.tensorflow.** { *; }
-keepclassmembers class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Google Protobuf (used by MediaPipe internally)
-keep class com.google.protobuf.** { *; }
-keepclassmembers class com.google.protobuf.** { *; }
-dontwarn com.google.protobuf.**

# Flatbuffers (used by TFLite)
-keep class com.google.flatbuffers.** { *; }
-keepclassmembers class com.google.flatbuffers.** { *; }
-dontwarn com.google.flatbuffers.**

# Keep all native library loaders
-keep class * {
    static void loadLibrary(java.lang.String);
}

# Keep model-related classes
-keep class * extends com.google.mediapipe.tasks.core.BaseOptions { *; }

# Prevent obfuscation of enum classes (MediaPipe uses many enums)
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Ignore annotation processing classes (compile-time only, not needed on Android)
-dontwarn javax.lang.model.**
-dontwarn javax.annotation.processing.**
-dontwarn autovalue.shaded.**
-dontwarn com.google.auto.value.**

# Keep JNI methods for native libraries
-keepclasseswithmembernames class * {
    native <methods>;
}