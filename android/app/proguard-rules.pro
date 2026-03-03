# GetX 混淆规则喵✨
-keep class com.getrx.** { *; }
-dontwarn com.getrx.**

# Dio 混淆规则喵awa
-keep class com.dio.** { *; }
-dontwarn com.dio.**

# Flutter 插件通用规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Webview 保护规则喵✨
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 🪄 核心修复：屏蔽 Google Play Core 相关的 R8 警告喵✨
# 这些类是 Flutter 引擎可选引用的，找不到不影响正常功能 awa
-dontwarn com.google.android.play.core.**
