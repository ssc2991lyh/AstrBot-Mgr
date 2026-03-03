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

# 🪄 修正：移除无法识别的占位符类名，改用通用的 Webview 保护规则
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
