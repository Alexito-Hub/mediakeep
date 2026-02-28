package com.mediakeep.aur;

import android.content.Intent;
import android.content.SharedPreferences;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import android.os.Build;
import androidx.annotation.RequiresApi;

@RequiresApi(api = Build.VERSION_CODES.N)
public class MediaKeepTileService extends TileService {

    private static final String PREFS_NAME = "MediaKeepPrefs";
    private static final String KEY_AUTO_DOWNLOAD = "auto_download_enabled";

    @Override
    public void onTileAdded() {
        super.onTileAdded();
        updateTileState();
    }

    @Override
    public void onStartListening() {
        super.onStartListening();
        updateTileState();
    }

    @Override
    public void onClick() {
        super.onClick();

        boolean isEnabled = isAutoDownloadEnabled();
        setAutoDownloadEnabled(!isEnabled);

        if (!isEnabled) {
            // Activar
            startClipboardMonitoring();
        } else {
            // Desactivar
            stopClipboardMonitoring();
        }

        updateTileState();
    }

    private boolean isAutoDownloadEnabled() {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        return prefs.getBoolean(KEY_AUTO_DOWNLOAD, false);
    }

    private void setAutoDownloadEnabled(boolean enabled) {
        SharedPreferences prefs = getSharedPreferences(PREFS_NAME, MODE_PRIVATE);
        prefs.edit().putBoolean(KEY_AUTO_DOWNLOAD, enabled).apply();
    }

    private void startClipboardMonitoring() {
        Intent serviceIntent = new Intent(this, ClipboardMonitorService.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent);
        } else {
            startService(serviceIntent);
        }
    }

    private void stopClipboardMonitoring() {
        Intent serviceIntent = new Intent(this, ClipboardMonitorService.class);
        stopService(serviceIntent);
    }

    private void updateTileState() {
        Tile tile = getQsTile();
        if (tile != null) {
            boolean isEnabled = isAutoDownloadEnabled();

            if (isEnabled) {
                tile.setState(Tile.STATE_ACTIVE);
                tile.setLabel("Auto-Download ON");
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    tile.setSubtitle("Monitoreando...");
                }
            } else {
                tile.setState(Tile.STATE_INACTIVE);
                tile.setLabel("Auto-Download OFF");
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    tile.setSubtitle("Toca para activar");
                }
            }

            tile.updateTile();
        }
    }
}
