# Flutter Core & Embedding
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep native methods and JNI
-keepclasseswithmembers class * {
    native <methods>;
}

-keepclassmembers class * extends java.lang.Enum {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep annotations, signatures and inner classes for reflection
-keepattributes *Annotation*,InnerClasses,EnclosingMethod,Signature,Exceptions

# Desugaring & R8 optimization
-dontwarn java.lang.invoke.**
-dontwarn com.android.tools.r8.**
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn com.google.android.play.core.**

# Supabase & Network libraries
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn io.github.jan.supabase.**

# PDF & Printing
-keep class com.tom_roush.fontbox.** { *; }
-dontwarn com.tom_roush.fontbox.**
-keep class net.nfet.flutter.printing.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Flutter Background Service
-keep class id.flutter.flutter_background_service.** { *; }
-dontwarn id.flutter.flutter_background_service.**

# Geolocator
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# Audio Players
-keep class xyz.luan.audioplayers.** { *; }
-dontwarn xyz.luan.audioplayers.**

# Image Picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# URL Launcher
-keep class io.flutter.plugins.urllauncher.** { *; }

# AndroidX EdgeToEdge & Lifecycle
-keep class androidx.activity.** { *; }
-keep class androidx.fragment.app.** { *; }
-keep class androidx.core.view.** { *; }
