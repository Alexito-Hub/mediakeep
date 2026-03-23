package com.mediakeep.aur;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.mediakeep.aur/widget_actions";
    private static final String PREFS_NAME = "MediaKeepPrefs";
    private static final String KEY_AUTO_DOWNLOAD = "auto_download_enabled";
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

        // Widget actions channel
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    switch (call.method) {
                        case "getInitialAction":
                            if (initialAction != null) {
                                result.success(initialAction + (initialUrl != null ? "|" + initialUrl : ""));
                                initialAction = null;
                                initialUrl = null;
                            } else {
                                result.success(null);
                            }
                            break;

                        case "openAccessibilitySettings":
                            Intent accIntent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
                            accIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                            startActivity(accIntent);
                            result.success(null);
                            break;

                        case "setAutoDownloadEnabled": {
                            // Write to MediaKeepPrefs (same store as TileService)
                            Boolean enabled = call.argument("enabled");
                            if (enabled == null) { result.error("INVALID_ARG", "enabled is null", null); break; }
                            SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
                            prefs.edit().putBoolean(KEY_AUTO_DOWNLOAD, enabled).apply();
                            // Also start or stop the foreground service
                            if (enabled) {
                                startClipboardService();
                            } else {
                                stopClipboardService();
                            }
                            result.success(null);
                            break;
                        }

                        case "getAutoDownloadEnabled": {
                            SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
                            result.success(prefs.getBoolean(KEY_AUTO_DOWNLOAD, false));
                            break;
                        }

                        default:
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

    private void startClipboardService() {
        Intent serviceIntent = new Intent(this, ClipboardMonitorService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }
    }

    private void stopClipboardService() {
        stopService(new Intent(this, ClipboardMonitorService.class));
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
    }
}


