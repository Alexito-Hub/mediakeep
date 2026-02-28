package com.mediakeep.aur;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import androidx.core.content.FileProvider;
import java.io.File;

public class NotificationReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();

        if ("SHARE_FILE".equals(action)) {
            String filepath = intent.getStringExtra("filepath");
            if (filepath != null) {
                shareFile(context, filepath);
            }
        } else if ("OPEN_HISTORY".equals(action)) {
            openHistory(context);
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
