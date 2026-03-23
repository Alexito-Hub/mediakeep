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

        boolean isCurrentlyEnabled = isAutoDownloadEnabled();

        if (!isCurrentlyEnabled) {
            // Trying to enable. First check if AccessibilityService is active!
            if (!isAccessibilityServiceEnabled()) {
                // Not enabled. Open settings and don't enable the tile.
                Intent accIntent = new Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS);
                accIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                if (android.os.Build.VERSION.SDK_INT >= 34) {
                    android.app.PendingIntent pendingIntent = android.app.PendingIntent.getActivity(
                            this, 0, accIntent,
                            android.app.PendingIntent.FLAG_IMMUTABLE | android.app.PendingIntent.FLAG_UPDATE_CURRENT
                    );
                    startActivityAndCollapse(pendingIntent);
                } else {
                    startActivityAndCollapse(accIntent);
                }
                return;
            }

            // It's active, we can proceed
            setAutoDownloadEnabled(true);
            startClipboardMonitoring();
        } else {
            // Trying to disable
            setAutoDownloadEnabled(false);
            stopClipboardMonitoring();
        }

        updateTileState();
    }

    private boolean isAccessibilityServiceEnabled() {
        android.content.ComponentName expectedComponentName = new android.content.ComponentName(this, MediaKeepAccessibilityService.class);
        String enabledServicesSetting = android.provider.Settings.Secure.getString(getContentResolver(), android.provider.Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        if (enabledServicesSetting == null) return false;
        android.text.TextUtils.SimpleStringSplitter colonSplitter = new android.text.TextUtils.SimpleStringSplitter(':');
        colonSplitter.setString(enabledServicesSetting);
        while (colonSplitter.hasNext()) {
            String componentNameString = colonSplitter.next();
            android.content.ComponentName enabledService = android.content.ComponentName.unflattenFromString(componentNameString);
            if (enabledService != null && enabledService.equals(expectedComponentName)) {
                return true;
            }
        }
        return false;
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
