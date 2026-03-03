package com.astrbot.astrbot_android;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.webkit.ValueCallback;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.FragmentActivity;
import androidx.fragment.app.FragmentManager;
import io.flutter.embedding.android.FlutterFragment;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

public class MainActivity extends FragmentActivity {
    private static final String TAG_FLUTTER_FRAGMENT = "flutter_fragment";
    private static final String ENGINE_ID = "my_engine_id";
    private static final int FILE_CHOOSER_REQUEST_CODE = 1;

    private FlutterFragment flutterFragment;
    private ValueCallback<Uri[]> filePathCallback;
    private Context mContext;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mContext = this;
        setContentView(R.layout.my_activity_layout);

        FragmentManager fragmentManager = getSupportFragmentManager();
        FlutterEngine flutterEngine = FlutterEngineCache.getInstance().get(ENGINE_ID);
        
        if (flutterEngine == null) {
            flutterEngine = new FlutterEngine(this);
            flutterEngine.getDartExecutor().executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault());
            GeneratedPluginRegistrant.registerWith(flutterEngine);
            setupMethodChannel(flutterEngine);
            FlutterEngineCache.getInstance().put(ENGINE_ID, flutterEngine);
        }

        flutterFragment = (FlutterFragment) fragmentManager.findFragmentByTag(TAG_FLUTTER_FRAGMENT);
        if (flutterFragment == null) {
            flutterFragment = FlutterFragment.withCachedEngine(ENGINE_ID).build();
            fragmentManager.beginTransaction().add(R.id.fl_container, flutterFragment, TAG_FLUTTER_FRAGMENT).commit();
        }
    }

    private void setupMethodChannel(FlutterEngine engine) {
        new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), "astrbot_channel")
            .setMethodCallHandler((call, result) -> {
                if ("lib_path".equals(call.method)) {
                    result.success(mContext.getApplicationContext().getApplicationInfo().nativeLibraryDir);
                } else {
                    result.notImplemented();
                }
            });
    }

    // 🪄 核心修正：移除原生拦截，让返回键事件流向 Flutter 喵✨
    @Override
    public void onBackPressed() {
        // 不再显示 Toast，直接交给父类处理（即转发给 FlutterFragment）
        super.onBackPressed();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST_CODE && filePathCallback != null) {
            Uri[] results = null;
            if (resultCode == Activity.RESULT_OK && data != null) {
                if (data.getDataString() != null) results = new Uri[]{Uri.parse(data.getDataString())};
                else if (data.getClipData() != null) {
                    int count = data.getClipData().getItemCount();
                    results = new Uri[count];
                    for (int i = 0; i < count; i++) results[i] = data.getClipData().getItemAt(i).getUri();
                }
            }
            filePathCallback.onReceiveValue(results);
            filePathCallback = null;
        }
        if (flutterFragment != null) flutterFragment.onActivityResult(requestCode, resultCode, data);
    }

    public void openFileChooser(ValueCallback<Uri[]> callback) {
        filePathCallback = callback;
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.addCategory(Intent.CATEGORY_OPENABLE);
        intent.setType("*/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        startActivityForResult(Intent.createChooser(intent, "选择文件"), FILE_CHOOSER_REQUEST_CODE);
    }

    @Override public void onPostResume() { super.onPostResume(); if (flutterFragment != null) flutterFragment.onPostResume(); }
    @Override protected void onNewIntent(@NonNull Intent intent) { super.onNewIntent(intent); if (flutterFragment != null) flutterFragment.onNewIntent(intent); }
    @Override public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) { super.onRequestPermissionsResult(requestCode, permissions, grantResults); if (flutterFragment != null) flutterFragment.onRequestPermissionsResult(requestCode, permissions, grantResults); }
}
