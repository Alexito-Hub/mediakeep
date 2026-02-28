package com.mediakeep.aur;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import androidx.core.app.NotificationCompat;
import androidx.core.content.FileProvider;
import java.io.File;

public class NotificationHelper {
    private static final String DOWNLOAD_CHANNEL_ID = "download_completion_channel";
    private static final int DOWNLOAD_NOTIFICATION_ID = 2001;

    public static void createNotificationChannel(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    DOWNLOAD_CHANNEL_ID,
                    "Descargas Completadas",
                    NotificationManager.IMPORTANCE_LOW);
            channel.setDescription("Notificaciones cuando se completa una descarga");
            channel.setSound(null, null);
            channel.enableVibration(false);

            NotificationManager manager = context.getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    public static void showDownloadCompletionNotification(Context context, String filename, String filepath) {
        showDownloadCompletionNotification(context, filename, filepath, filename);
    }

    public static void showDownloadCompletionNotification(Context context, String filename, String filepath,
            String title) {
        createNotificationChannel(context);

        // Intent para compartir
        Intent shareIntent = new Intent(context, NotificationReceiver.class);
        shareIntent.setAction("SHARE_FILE");
        shareIntent.putExtra("filepath", filepath);
        PendingIntent sharePendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                shareIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        // Intent para ver historial
        Intent historyIntent = new Intent(context, NotificationReceiver.class);
        historyIntent.setAction("OPEN_HISTORY");
        PendingIntent historyPendingIntent = PendingIntent.getBroadcast(
                context,
                1,
                historyIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        // Intent al tocar la notificación (abrir app)
        Intent mainIntent = new Intent(context, MainActivity.class);
        PendingIntent mainPendingIntent = PendingIntent.getActivity(
                context,
                0,
                mainIntent,
                PendingIntent.FLAG_IMMUTABLE);

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, DOWNLOAD_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download_done)
                .setContentTitle("Descarga completada")
                .setContentText(title != null && !title.isEmpty() ? title : filename)
                .setContentIntent(mainPendingIntent)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .setSound(null)
                .setSilent(true)
                .setAutoCancel(true)
                .addAction(android.R.drawable.ic_menu_share, "Compartir", sharePendingIntent)
                .addAction(android.R.drawable.ic_menu_recent_history, "Historial", historyPendingIntent);

        NotificationManager notificationManager = (NotificationManager) context
                .getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.notify(DOWNLOAD_NOTIFICATION_ID, builder.build());
        }
    }
}
