package com.mediakeep.aur;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import androidx.core.app.NotificationCompat;

public class NotificationHelper {
    private static final String DOWNLOAD_CHANNEL_ID = "download_completion_channel";
    private static final int DOWNLOAD_NOTIFICATION_ID = 2001;
    private static final String SHARE_CONFIRM_CHANNEL_ID = "share_download_confirmation_channel";
    private static final int SHARE_CONFIRM_BASE_ID = 3000;

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

    private static void createShareConfirmationChannel(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    SHARE_CONFIRM_CHANNEL_ID,
                    "Confirmaciones de descarga",
                    NotificationManager.IMPORTANCE_DEFAULT);
            channel.setDescription("Solicitudes de descarga desde enlaces compartidos");

            NotificationManager manager = context.getSystemService(NotificationManager.class);
            if (manager != null) {
                manager.createNotificationChannel(channel);
            }
        }
    }

    private static int buildShareNotificationId(String url) {
        return SHARE_CONFIRM_BASE_ID + Math.abs(url.hashCode() % 1000);
    }

    public static void showDownloadCompletionNotification(Context context, String filename, String filepath) {
        showDownloadCompletionNotification(context, filename, filepath, filename);
    }

    public static void showDownloadCompletionNotification(Context context, String filename, String filepath,
            String title) {
        createNotificationChannel(context);

        // Intent para compartir
        Intent shareIntent = new Intent(context, NotificationReceiver.class);
        shareIntent.setAction(NotificationReceiver.ACTION_SHARE_FILE);
        shareIntent.putExtra(NotificationReceiver.EXTRA_FILEPATH, filepath);
        PendingIntent sharePendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                shareIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        // Intent para ver historial
        Intent historyIntent = new Intent(context, NotificationReceiver.class);
        historyIntent.setAction(NotificationReceiver.ACTION_OPEN_HISTORY);
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

    public static void showShareDownloadConfirmationNotification(Context context, String url) {
        if (url == null || url.trim().isEmpty()) {
            return;
        }

        String normalizedUrl = url.trim();
        int notificationId = buildShareNotificationId(normalizedUrl);
        createShareConfirmationChannel(context);

        Intent yesIntent = new Intent(context, NotificationReceiver.class);
        yesIntent.setAction(NotificationReceiver.ACTION_SHARE_DOWNLOAD_YES);
        yesIntent.putExtra(NotificationReceiver.EXTRA_URL, normalizedUrl);
        yesIntent.putExtra(NotificationReceiver.EXTRA_NOTIFICATION_ID, notificationId);
        PendingIntent yesPendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId,
                yesIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        Intent noIntent = new Intent(context, NotificationReceiver.class);
        noIntent.setAction(NotificationReceiver.ACTION_SHARE_DOWNLOAD_NO);
        noIntent.putExtra(NotificationReceiver.EXTRA_NOTIFICATION_ID, notificationId);
        PendingIntent noPendingIntent = PendingIntent.getBroadcast(
                context,
                notificationId + 1,
                noIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        Intent mainIntent = new Intent(context, MainActivity.class);
        PendingIntent mainPendingIntent = PendingIntent.getActivity(
                context,
                notificationId + 2,
                mainIntent,
                PendingIntent.FLAG_IMMUTABLE | PendingIntent.FLAG_UPDATE_CURRENT);

        String previewText = normalizedUrl.length() > 60
                ? normalizedUrl.substring(0, 57) + "..."
                : normalizedUrl;

        NotificationCompat.Builder builder = new NotificationCompat.Builder(context, SHARE_CONFIRM_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.stat_sys_download_done)
                .setContentTitle("¿Descargar este contenido?")
                .setContentText(previewText)
                .setContentIntent(mainPendingIntent)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_DEFAULT)
                .addAction(android.R.drawable.checkbox_on_background, "Si", yesPendingIntent)
                .addAction(android.R.drawable.ic_delete, "No", noPendingIntent);

        NotificationManager notificationManager = (NotificationManager) context
                .getSystemService(Context.NOTIFICATION_SERVICE);
        if (notificationManager != null) {
            notificationManager.notify(notificationId, builder.build());
        }
    }
}
