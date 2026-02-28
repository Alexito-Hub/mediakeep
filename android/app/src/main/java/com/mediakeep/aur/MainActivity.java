package com.mediakeep.aur;

import android.content.Intent;
import android.os.Bundle;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.mediakeep.aur/widget_actions";
    private String initialAction = null;
    private String initialUrl = null;

    private FlutterEngine flutterEngineInstance;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        handleIntent(getIntent());
    }

    @Override
    public void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.getAction() != null) {
            String action = intent.getAction();
            if (action.contains("OPEN_HISTORY") || action.contains("OPEN_SETTINGS")
                    || action.contains("DOWNLOAD_FROM_WIDGET")) {
                initialAction = action;
                initialUrl = intent.getStringExtra("clipboard_url");

                // If engine is already running, send action immediately
                if (flutterEngineInstance != null) {
                    sendActionToFlutter(action, initialUrl);
                }
            }
        }
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        this.flutterEngineInstance = flutterEngine;

        GoogleMobileAdsPlugin.registerNativeAdFactory(
                flutterEngine, "listTile", new ListTileNativeAdFactory(getContext()));

        // Widget actions channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("getInitialAction")) {
                        if (initialAction != null) {
                            result.success(initialAction + (initialUrl != null ? "|" + initialUrl : ""));
                            initialAction = null; // Clear after sending
                            initialUrl = null;
                        } else {
                            result.success(null);
                        }
                    } else {
                        result.notImplemented();
                    }
                });

        // Notification channel for download completion
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "com.mediakeep.aur/notifications")
                .setMethodCallHandler((call, result) -> {
                    if (call.method.equals("showDownloadNotification")) {
                        String filename = (String) call.argument("filename");
                        String filepath = (String) call.argument("filepath");
                        String title = call.hasArgument("title") ? (String) call.argument("title") : filename;
                        NotificationHelper.showDownloadCompletionNotification(this.getApplicationContext(), filename,
                                filepath, title);
                        result.success(true);
                    } else {
                        result.notImplemented();
                    }
                });
    }

    private void sendActionToFlutter(String action, String url) {
        if (flutterEngineInstance != null) {
            new MethodChannel(flutterEngineInstance.getDartExecutor().getBinaryMessenger(), CHANNEL)
                    .invokeMethod("onWidgetAction", action + (url != null ? "|" + url : ""));
        }
    }

    @Override
    public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.cleanUpFlutterEngine(flutterEngine);
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile");
    }
}
