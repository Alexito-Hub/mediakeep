package com.mediakeep.aur;

import android.app.NotificationManager;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import androidx.core.content.FileProvider;
import java.io.File;

public class NotificationReceiver extends BroadcastReceiver {
    public static final String ACTION_SHARE_FILE = "SHARE_FILE";
    public static final String ACTION_OPEN_HISTORY = "OPEN_HISTORY";
    public static final String ACTION_SHARE_DOWNLOAD_YES = "CONFIRM_SHARE_DOWNLOAD_YES";
    public static final String ACTION_SHARE_DOWNLOAD_NO = "CONFIRM_SHARE_DOWNLOAD_NO";

    public static final String EXTRA_FILEPATH = "filepath";
    public static final String EXTRA_URL = "url";
    public static final String EXTRA_NOTIFICATION_ID = "notification_id";

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();

        if (ACTION_SHARE_FILE.equals(action)) {
            String filepath = intent.getStringExtra(EXTRA_FILEPATH);
            if (filepath != null) {
                shareFile(context, filepath);
            }
        } else if (ACTION_OPEN_HISTORY.equals(action)) {
            openHistory(context);
        } else if (ACTION_SHARE_DOWNLOAD_YES.equals(action)) {
            handleShareDownloadConfirmation(context, intent, true);
        } else if (ACTION_SHARE_DOWNLOAD_NO.equals(action)) {
            handleShareDownloadConfirmation(context, intent, false);
        }
    }

    private void handleShareDownloadConfirmation(Context context, Intent intent, boolean confirmed) {
        int notificationId = intent.getIntExtra(EXTRA_NOTIFICATION_ID, -1);
        if (notificationId >= 0) {
            NotificationManager manager = (NotificationManager) context
                    .getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                manager.cancel(notificationId);
            }
        }

        if (!confirmed) {
            return;
        }

        String url = intent.getStringExtra(EXTRA_URL);
        if (url == null || url.trim().isEmpty()) {
            return;
        }

        Intent serviceIntent = new Intent(context, ExplicitDownloadService.class);
        serviceIntent.setAction(ExplicitDownloadService.ACTION_START_DOWNLOAD);
        serviceIntent.putExtra(ExplicitDownloadService.EXTRA_URL, url.trim());
        serviceIntent.putExtra(
                ExplicitDownloadService.EXTRA_TRIGGER,
                ExplicitDownloadService.TRIGGER_SHARE_CONFIRMATION);

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent);
        } else {
            context.startService(serviceIntent);
        }
    }

    private void shareFile(Context context, String filepath) {
        try {
            File file = new File(filepath);
            if (file.exists()) {
                Uri fileUri = FileProvider.getUriForFile(
                        context,
                        context.getPackageName() + ".fileprovider",
                        file);

                Intent shareIntent = new Intent(Intent.ACTION_SEND);
                shareIntent.setType(getMimeType(filepath));
                shareIntent.putExtra(Intent.EXTRA_STREAM, fileUri);
                shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
                shareIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                Intent chooser = Intent.createChooser(shareIntent, "Compartir archivo");
                chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(chooser);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void openHistory(Context context) {
        Intent intent = new Intent(context, MainActivity.class);
        intent.setAction("OPEN_HISTORY");
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        context.startActivity(intent);
    }

    private String getMimeType(String filepath) {
        String extension = filepath.substring(filepath.lastIndexOf(".") + 1).toLowerCase();
        switch (extension) {
            case "mp4":
            case "mov":
            case "avi":
                return "video/*";
            case "jpg":
            case "jpeg":
            case "png":
            case "gif":
                return "image/*";
            case "mp3":
            case "m4a":
            case "wav":
                return "audio/*";
            default:
                return "*/*";
        }
    }
}
