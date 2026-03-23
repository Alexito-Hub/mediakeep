package com.mediakeep.aur;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.FlutterInjector;
import io.flutter.plugin.common.MethodChannel;

/**
 * ClipboardMonitorService (simplified)
 *
 * This is now a thin foreground service that:
 *  1. Shows a persistent notification (required to keep the process alive).
 *  2. Receives PROCESS_URL intents dispatched by MediaKeepAccessibilityService.
 *  3. Forwards the URL to the background Flutter engine via MethodChannel.
 *
 * Overlay and polling logic have been removed — the AccessibilityService handles
 * clipboard detection instead.
 */
@SuppressWarnings("deprecation")
public class ClipboardMonitorService extends Service {
    private static final String CHANNEL_ID = "clipboard_monitor_channel";
    private static final int NOTIFICATION_ID = 1001;
    private static final String BACKGROUND_CHANNEL_NAME = "com.mediakeep.aur/background";
    private static final String TAG = "ClipboardMonitorService";

    private Handler mainHandler;
    private FlutterEngine flutterEngine;
    private MethodChannel backgroundChannel;
    private android.graphics.Bitmap largeIcon;
    private String pendingUrl = null;

    @Override
    public void onCreate() {
        super.onCreate();
        android.util.Log.d(TAG, "Service onCreate()");

        mainHandler = new Handler(Looper.getMainLooper());
        initFlutterEngine();
        createNotificationChannel();
        startForeground(NOTIFICATION_ID, createNotification("Esperando enlace..."));

        try {
            largeIcon = android.graphics.BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher);
        } catch (Exception e) {
            android.util.Log.e(TAG, "Icon decode error: " + e.getMessage());
        }

        android.util.Log.d(TAG, "Service initialized");
    }

    private void initFlutterEngine() {
        mainHandler.post(() -> {
            try {
                if (flutterEngine == null) {
                    flutterEngine = new FlutterEngine(this);

                    DartExecutor.DartEntrypoint entrypoint = new DartExecutor.DartEntrypoint(
                            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                            "backgroundMain");
                    flutterEngine.getDartExecutor().executeDartEntrypoint(entrypoint);

                    backgroundChannel = new MethodChannel(
                            flutterEngine.getDartExecutor().getBinaryMessenger(),
                            BACKGROUND_CHANNEL_NAME);

                    backgroundChannel.setMethodCallHandler((call, result) -> {
                        switch (call.method) {
                            case "downloadComplete": {
                                String filename = call.argument("filename");
                                String filepath = call.argument("filepath");
                                String title = call.argument("title");
                                updateNotification("Descarga completada");
                                mainHandler.postDelayed(() -> updateNotification("Esperando enlace..."), 3000);
                                NotificationHelper.showDownloadCompletionNotification(this, filename, filepath, title);
                                result.success(null);
                                break;
                            }
                            case "downloadError": {
                                String message = call.argument("message");
                                android.util.Log.e(TAG, "Download Error: " + message);
                                updateNotification(message);
                                mainHandler.postDelayed(() -> updateNotification("Esperando enlace..."), 5000);
                                result.success(null);
                                break;
                            }
                            case "updateStatus": {
                                String status = call.argument("status");
                                updateNotification(status);
                                result.success(null);
                                break;
                            }
                            default:
                                result.notImplemented();
                        }
                    });

                    android.util.Log.d(TAG, "FlutterEngine initialized");

                    // Process any pending URL that arrived while Engine was initializing
                    if (pendingUrl != null) {
                        String urlToProcess = pendingUrl;
                        pendingUrl = null;
                        processUrl(urlToProcess);
                    }
                }
            } catch (Exception e) {
                android.util.Log.e(TAG, "Error initializing FlutterEngine: " + e.getMessage());
            }
        });
    }

    /** Process a URL received from the AccessibilityService */
    private void processUrl(String url) {
        mainHandler.post(() -> {
            android.util.Log.d(TAG, "Processing URL: " + url);
            updateNotification("Iniciando descarga...");
            if (backgroundChannel != null) {
                backgroundChannel.invokeMethod("startDownload", url, new MethodChannel.Result() {
                    @Override
                    public void success(Object result) {
                        android.util.Log.d(TAG, "Dart startDownload returned success");
                    }

                    @Override
                    public void error(String code, String msg, Object details) {
                        android.util.Log.e(TAG, "Dart startDownload Error: " + msg);
                    }

                    @Override
                    public void notImplemented() {
                        android.util.Log.e(TAG, "Dart method not implemented!");
                    }
                });
            } else {
                android.util.Log.w(TAG, "backgroundChannel not ready — queuing URL for later");
                pendingUrl = url;
            }
        });
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null) return START_STICKY;

        final String action = intent.getAction();
        if ("STOP_SERVICE".equals(action)) {
            stopForeground(true);
            stopSelf();
            return START_NOT_STICKY;
        }

        if ("PROCESS_URL".equals(action)) {
            final String url = intent.getStringExtra("url");
            if (url != null && !url.isEmpty()) {
                processUrl(url);
            }
        }

        return START_STICKY;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Auto-Download Monitor",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("Monitoreo de portapapeles");
            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private void updateNotification(String status) {
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.notify(NOTIFICATION_ID, createNotification(status));
        }
    }

    private Notification createNotification(String status) {
        Intent stopIntent = new Intent(this, ClipboardMonitorService.class);
        stopIntent.setAction("STOP_SERVICE");
        PendingIntent stopPendingIntent = PendingIntent.getService(
                this, 0, stopIntent, PendingIntent.FLAG_IMMUTABLE);

        Intent mainIntent = new Intent(this, MainActivity.class);
        PendingIntent mainPendingIntent = PendingIntent.getActivity(
                this, 0, mainIntent, PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                .setContentTitle("Media Keep")
                .setContentText(status)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentIntent(mainPendingIntent)
                .addAction(android.R.drawable.ic_delete, "Detener", stopPendingIntent)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setSound(null)
                .setSilent(true)
                .setShowWhen(false);

        if (largeIcon != null) {
            builder.setLargeIcon(largeIcon);
        }

        return builder.build();
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (flutterEngine != null) {
            flutterEngine.destroy();
            flutterEngine = null;
        }
        android.util.Log.d(TAG, "Service destroyed");
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
