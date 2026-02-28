package com.mediakeep.aur;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.ClipboardManager;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Patterns;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.view.MotionEvent;
import android.graphics.PixelFormat;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.dart.DartExecutor;
import io.flutter.FlutterInjector;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@SuppressWarnings("deprecation")
public class ClipboardMonitorService extends Service {
    private static final String CHANNEL_ID = "clipboard_monitor_channel";
    private static final int NOTIFICATION_ID = 1001;
    private static final String BACKGROUND_CHANNEL_NAME = "com.mediakeep.aur/background";

    private static final String TAG = "ClipboardMonitor";

    private ClipboardManager clipboardManager;
    private String lastClipboard = "";
    private long lastClipTimestamp = 0; // Track timestamp to avoid unnecessary focus stealing
    private ScheduledExecutorService executor;
    private Handler mainHandler;
    private FlutterEngine flutterEngine;
    private MethodChannel backgroundChannel;
    private WindowManager windowManager;
    private View overlayView;
    private WindowManager.LayoutParams overlayParams;
    private android.graphics.Bitmap largeIcon; // Cache icon
    private long lastInteractionTime = 0; // Track user touches

    @Override
    public void onCreate() {
        super.onCreate();
        android.util.Log.d(TAG, "Service onCreate() called");

        clipboardManager = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        mainHandler = new Handler(Looper.getMainLooper());

        // Setup Overlay for Clipboard Access
        setupOverlay();

        // Initialize Flutter Engine for background execution
        initFlutterEngine();

        createNotificationChannel();
        startForeground(NOTIFICATION_ID, createNotification());

        // Start "Smart" Polling
        startClipboardPolling();

        // Pre-decode icon
        try {
            largeIcon = android.graphics.BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher);
        } catch (Exception e) {
            android.util.Log.e(TAG, "Icon decode error: " + e.getMessage());
        }

        android.util.Log.d(TAG, "Service initialized with Smart Polling");
    }

    private void setupOverlay() {
        try {
            windowManager = (WindowManager) getSystemService(WINDOW_SERVICE);
            int type = WindowManager.LayoutParams.TYPE_PHONE;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY;
            }

            overlayParams = new WindowManager.LayoutParams(
                    1, 1, // 1x1 pixel
                    type,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                            WindowManager.LayoutParams.FLAG_ALT_FOCUSABLE_IM | // Try to keep keyboard open
                            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL |
                            WindowManager.LayoutParams.FLAG_WATCH_OUTSIDE_TOUCH,
                    PixelFormat.TRANSLUCENT);
            overlayParams.gravity = Gravity.TOP | Gravity.START;
            overlayParams.x = 0;
            overlayParams.y = 0;

            overlayView = new View(this);
            // Smart Back-off: Detect touches outside
            overlayView.setOnTouchListener((v, event) -> {
                if (event.getAction() == MotionEvent.ACTION_OUTSIDE) {
                    lastInteractionTime = System.currentTimeMillis();
                }
                return false;
            });

            windowManager.addView(overlayView, overlayParams);
            android.util.Log.d("ClipboardMonitor", "Overlay view created for clipboard access");
        } catch (Exception e) {
            android.util.Log.e("ClipboardMonitor", "Failed to create overlay: " + e.getMessage());
        }
    }

    private void updateOverlayFocus(boolean focusable) {
        if (windowManager != null && overlayView != null && overlayParams != null) {
            try {
                if (focusable) {
                    overlayParams.flags &= ~WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
                } else {
                    overlayParams.flags |= WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE;
                }
                windowManager.updateViewLayout(overlayView, overlayParams);
            } catch (Exception e) {
                android.util.Log.e("ClipboardMonitor", "Error updating overlay focus: " + e.getMessage());
            }
        }
    }

    private void initFlutterEngine() {
        // Run on UI thread as required by Flutter
        mainHandler.post(() -> {
            try {
                if (flutterEngine == null) {
                    flutterEngine = new FlutterEngine(this);

                    // Start executing the Dart entry point "backgroundMain"
                    DartExecutor.DartEntrypoint entrypoint = new DartExecutor.DartEntrypoint(
                            FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                            "backgroundMain");
                    flutterEngine.getDartExecutor().executeDartEntrypoint(entrypoint);

                    // Setup MethodChannel
                    backgroundChannel = new MethodChannel(
                            flutterEngine.getDartExecutor().getBinaryMessenger(),
                            BACKGROUND_CHANNEL_NAME);

                    backgroundChannel.setMethodCallHandler((call, result) -> {
                        if (call.method.equals("downloadComplete")) {
                            String filename = call.argument("filename");
                            String filepath = call.argument("filepath");
                            String title = call.argument("title");

                            updateNotification("Descarga completada");
                            mainHandler.postDelayed(() -> updateNotification("Esperando enlace..."), 3000);

                            NotificationHelper.showDownloadCompletionNotification(this, filename, filepath, title);
                            result.success(null);
                        } else if (call.method.equals("downloadError")) {
                            String message = call.argument("message");
                            android.util.Log.e("ClipboardMonitor", "Download Error: " + message);
                            updateNotification(message); // Show exact message
                            mainHandler.postDelayed(() -> updateNotification("Esperando enlace..."), 5000); // 5s to
                                                                                                            // read
                            result.success(null);
                        } else if (call.method.equals("updateStatus")) {
                            String status = call.argument("status");
                            updateNotification(status);
                            result.success(null);
                        } else {
                            result.notImplemented();
                        }
                    });

                    android.util.Log.d("ClipboardMonitor", "FlutterEngine initialized for background");
                }
            } catch (Exception e) {
                android.util.Log.e("ClipboardMonitor", "Error initializing FlutterEngine: " + e.getMessage());
            }
        });
    }

    private void startClipboardPolling() {
        android.util.Log.d("ClipboardMonitor", "Starting clipboard polling (every 1s)...");
        executor = Executors.newSingleThreadScheduledExecutor();
        executor.scheduleAtFixedRate(() -> smartCheckClipboard(), 0, 1000, TimeUnit.MILLISECONDS);
    }

    // Checks clipboard metadata WITHOUT stealing focus first
    private void smartCheckClipboard() {
        boolean timestampChanged = false;

        try {
            // Android 8.0+ (API 26) allows checking timestamp
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                android.content.ClipDescription desc = clipboardManager.getPrimaryClipDescription();
                if (desc != null) {
                    long timestamp = desc.getTimestamp();
                    // If timestamp matches last processed one, skip!
                    if (timestamp != lastClipTimestamp) {
                        android.util.Log.d("ClipboardMonitor", "New Clip Timestamp detected: " + timestamp);
                        lastClipTimestamp = timestamp;
                        timestampChanged = true;
                    }
                }
            }
        } catch (Exception e) {
            // If we can't read description, fall through to safe check
        }

        // Smart Logic:
        // 1. If timestamp CHANGED (High Confidence) -> Pulse IMMEDIATELY (Ignore
        // interaction)
        // 2. If timestamp SAME (Low Confidence) -> Pulse ONLY if Idle (Fallback)

        if (timestampChanged) {
            performPulseCheck();
        } else {
            // Smart Back-off: If user interacted recently, SKIP fallback check
            if (System.currentTimeMillis() - lastInteractionTime > 2000) {
                // Optional: Only fallback on older Android or if we really need to.
                // For now, keeping it to ensure reliability on old devices.
                performPulseCheck();
            }
        }
    }

    private void performPulseCheck() {
        // Execute pulse on Main Thread to update UI/Window flags
        mainHandler.post(() -> {
            try {
                // 1. Focus the overlay (allows clipboard read)
                updateOverlayFocus(true);

                // 2. Wait briefly for WindowManager to apply focus (critical for Android 10+)
                mainHandler.postDelayed(() -> {
                    try {
                        performClipboardCheck();
                    } finally {
                        // 3. Immediately Unfocus (to prevent blocking back button)
                        updateOverlayFocus(false);
                    }
                }, 50); // Minimal delay
            } catch (Exception e) {
                android.util.Log.e("ClipboardMonitor", "Pulse Error: " + e.getMessage());
            }
        });
    }

    private void performClipboardCheck() {
        // android.util.Log.d("ClipboardMonitor", "Checking clipboard with pulse...");
        try {
            if (clipboardManager != null && clipboardManager.hasPrimaryClip()) {
                ClipData clipData = clipboardManager.getPrimaryClip();
                if (clipData != null && clipData.getItemCount() > 0) {
                    ClipData.Item item = clipData.getItemAt(0);
                    CharSequence text = item.getText();

                    if (text != null) {
                        String clipText = text.toString().trim();

                        if (!clipText.equals(lastClipboard)) {
                            android.util.Log.d("ClipboardMonitor",
                                    "New clipboard text detected: String content change");

                            // Double check: if we are on older android (no timestamp), we rely on string
                            // compare
                            // If we are on new android, the timestamp check already passed

                            if (isValidUrl(clipText)) {
                                android.util.Log.d("ClipboardMonitor", "Valid URL matched: " + clipText);
                                lastClipboard = clipText;
                                updateNotification("Enlace detectado");
                                processUrl(clipText);
                            } else {
                                android.util.Log.d("ClipboardMonitor", "Ignored URL (invalid domain): " + clipText);
                                // updateNotification("URL no soportada/reconocida");
                                lastClipboard = clipText; // Update
                            }
                        }
                    }
                }
            }
        } catch (SecurityException se) {
            android.util.Log.e("ClipboardMonitor", "SecurityException reading clipboard: " + se.getMessage());
            updateNotification("Error: Acceso denegado al portapapeles");
        } catch (Exception e) {
            android.util.Log.e("ClipboardMonitor", "Error performClipboardCheck: " + e.getMessage());
        }
    }

    private boolean isValidUrl(String text) {
        if (text == null || text.isEmpty())
            return false;
        if (!Patterns.WEB_URL.matcher(text).matches())
            return false;

        String lowerText = text.toLowerCase();
        return lowerText.contains("tiktok.com") ||
                lowerText.contains("instagram.com") ||
                lowerText.contains("facebook.com") ||
                lowerText.contains("fb.watch") ||
                lowerText.contains("youtube.com") ||
                lowerText.contains("youtu.be") ||
                lowerText.contains("twitter.com") ||
                lowerText.contains("x.com") ||
                lowerText.contains("spotify.com") ||
                lowerText.contains("threads.net");
    }

    private void processUrl(String url) {
        // Ejecutar en hilo principal (UI Thread)
        mainHandler.post(() -> {
            updateNotification("Iniciando descarga...");
            if (backgroundChannel != null) {
                android.util.Log.d("ClipboardMonitor", "Sending URL to Background Flutter Engine: " + url);
                // Reset timestamp tracking to allow re-copy of same link after some time if
                // needed?
                // lastClipTimestamp = 0; // Don't reset, allow only one trigger per copy
                // action.

                backgroundChannel.invokeMethod("startDownload", url, new MethodChannel.Result() {
                    @Override
                    public void success(Object result) {
                        android.util.Log.d("ClipboardMonitor", "Dart startDownload returned success");
                    }

                    @Override
                    public void error(String code, String msg, Object details) {
                        android.util.Log.e("ClipboardMonitor", "Dart startDownload Error: " + msg);
                    }

                    @Override
                    public void notImplemented() {
                        android.util.Log.e("ClipboardMonitor", "Dart method not implemented!");
                    }
                });
            } else {
                android.util.Log.e("ClipboardMonitor", "Background Channel is null/not ready!");
                initFlutterEngine();
            }
        });
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

    private Notification createNotification() {
        return createNotification("Esperando enlace...");
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && "STOP_SERVICE".equals(intent.getAction())) {
            stopForeground(true);
            stopSelf();
            return START_NOT_STICKY;
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (executor != null) {
            executor.shutdownNow();
        }
        if (flutterEngine != null) {
            flutterEngine.destroy();
            flutterEngine = null;
        }
        if (windowManager != null && overlayView != null) {
            try {
                windowManager.removeView(overlayView);
            } catch (Exception e) {
                android.util.Log.e("ClipboardMonitor", "Error removing overlay: " + e.getMessage());
            }
        }
        android.util.Log.d("ClipboardMonitor", "Service destroyed");
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
