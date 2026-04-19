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
import io.flutter.FlutterInjector;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;

public class ExplicitDownloadService extends Service {
    public static final String ACTION_START_DOWNLOAD = "com.mediakeep.aur.action.START_DOWNLOAD";
    public static final String EXTRA_URL = "url";
    public static final String EXTRA_TRIGGER = "trigger";
    public static final String TRIGGER_SHARE_CONFIRMATION = "share_confirmation";

    private static final String CHANNEL_ID = "explicit_download_channel";
    private static final int NOTIFICATION_ID = 3010;
    private static final String BACKGROUND_CHANNEL_NAME = "com.mediakeep.aur/background";
    private static final String TAG = "ExplicitDownloadService";

    private Handler mainHandler;
    private FlutterEngine flutterEngine;
    private MethodChannel backgroundChannel;
    private String pendingUrl;
    private String pendingTrigger;

    @Override
    public void onCreate() {
        super.onCreate();
        mainHandler = new Handler(Looper.getMainLooper());
        createNotificationChannel();
        startForeground(NOTIFICATION_ID, createNotification("Preparando descarga..."));
        initFlutterEngine();
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
                        if ("downloadComplete".equals(call.method)) {
                            String filename = call.argument("filename");
                            String filepath = call.argument("filepath");
                            String title = call.argument("title");
                            NotificationHelper.showDownloadCompletionNotification(this, filename, filepath, title);
                            updateNotification("Descarga completada");
                            scheduleStop();
                            result.success(null);
                        } else if ("downloadError".equals(call.method)) {
                            String message = call.argument("message");
                            updateNotification(message == null || message.isEmpty()
                                    ? "Error en la descarga"
                                    : message);
                            scheduleStop();
                            result.success(null);
                        } else if ("updateStatus".equals(call.method)) {
                            String status = call.argument("status");
                            updateNotification(status == null || status.isEmpty()
                                    ? "Procesando descarga..."
                                    : status);
                            result.success(null);
                        } else {
                            result.notImplemented();
                        }
                    });

                    if (pendingUrl != null && pendingTrigger != null) {
                        String queuedUrl = pendingUrl;
                        String queuedTrigger = pendingTrigger;
                        pendingUrl = null;
                        pendingTrigger = null;
                        processUrl(queuedUrl, queuedTrigger);
                    }
                }
            } catch (Exception e) {
                android.util.Log.e(TAG, "Error initializing FlutterEngine", e);
                updateNotification("No se pudo iniciar la descarga");
                scheduleStop();
            }
        });
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null || !ACTION_START_DOWNLOAD.equals(intent.getAction())) {
            scheduleStop();
            return START_NOT_STICKY;
        }

        String url = intent.getStringExtra(EXTRA_URL);
        String trigger = intent.getStringExtra(EXTRA_TRIGGER);
        if (url == null || url.trim().isEmpty() || !TRIGGER_SHARE_CONFIRMATION.equals(trigger)) {
            android.util.Log.w(TAG, "Rejected background download without explicit confirmation");
            scheduleStop();
            return START_NOT_STICKY;
        }

        processUrl(url.trim(), trigger);
        return START_NOT_STICKY;
    }

    private void processUrl(String url, String trigger) {
        mainHandler.post(() -> {
            updateNotification("Iniciando descarga...");

            if (backgroundChannel == null) {
                pendingUrl = url;
                pendingTrigger = trigger;
                return;
            }

            Map<String, Object> payload = new HashMap<>();
            payload.put("url", url);
            payload.put("trigger", trigger);

            backgroundChannel.invokeMethod("startDownload", payload, new MethodChannel.Result() {
                @Override
                public void success(Object result) {
                    android.util.Log.d(TAG, "startDownload delivered to Dart background isolate");
                }

                @Override
                public void error(String code, String message, Object details) {
                    android.util.Log.e(TAG, "startDownload failed: " + message);
                    updateNotification("No se pudo iniciar la descarga");
                    scheduleStop();
                }

                @Override
                public void notImplemented() {
                    android.util.Log.e(TAG, "startDownload not implemented in Dart isolate");
                    updateNotification("Descarga no disponible");
                    scheduleStop();
                }
            });
        });
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Descargas en segundo plano",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("Estado de descargas iniciadas por el usuario");

            NotificationManager manager = getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private Notification createNotification(String status) {
        Intent mainIntent = new Intent(this, MainActivity.class);
        PendingIntent mainPendingIntent = PendingIntent.getActivity(
                this,
                0,
                mainIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download)
                .setContentTitle("Media Keep")
                .setContentText(status)
                .setContentIntent(mainPendingIntent)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setOngoing(true)
                .setSilent(true)
                .build();
    }

    private void updateNotification(String status) {
        NotificationManager manager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager != null) {
            manager.notify(NOTIFICATION_ID, createNotification(status));
        }
    }

    private void scheduleStop() {
        mainHandler.postDelayed(() -> {
            stopForeground(true);
            stopSelf();
        }, 1500);
    }

    @Override
    public void onDestroy() {
        if (flutterEngine != null) {
            flutterEngine.destroy();
            flutterEngine = null;
        }
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
