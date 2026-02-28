package com.mediakeep.aur;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.widget.RemoteViews;

import android.view.View;
import org.json.JSONArray;
import org.json.JSONObject;

public class MediaKeepWidgetProvider extends AppWidgetProvider {

    private static final String ACTION_DOWNLOAD = "com.mediakeep.aur.mediakeep.DOWNLOAD_FROM_WIDGET";
    private static final String ACTION_HISTORY = "com.mediakeep.aur.mediakeep.OPEN_HISTORY";
    private static final String ACTION_SETTINGS = "com.mediakeep.aur.mediakeep.OPEN_SETTINGS";

    @Override
    public void onUpdate(Context context, AppWidgetManager appWidgetManager, int[] appWidgetIds) {
        for (int appWidgetId : appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId);
        }
    }

    static void updateAppWidget(Context context, AppWidgetManager appWidgetManager, int appWidgetId) {
        // Obtener datos de SharedPreferences
        SharedPreferences prefs = context.getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE);
        int totalDownloads = prefs.getInt("total_downloads", 0);
        String recentItemsJson = prefs.getString("recent_downloads", "[]");

        // Crear el layout del widget
        RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.widget_layout);

        // Actualizar textos
        views.setTextViewText(R.id.total_downloads, totalDownloads + " Descargas");

        // Manejar descargas recientes
        try {
            JSONArray items = new JSONArray(recentItemsJson);
            if (items.length() > 0) {
                views.setViewVisibility(R.id.empty_state_text, View.GONE);
                views.setViewVisibility(R.id.recent_container, View.VISIBLE);

                // Item 1
                if (items.length() >= 1) {
                    JSONObject item = items.getJSONObject(0);
                    views.setViewVisibility(R.id.item_1, View.VISIBLE);
                    views.setTextViewText(R.id.text_1, item.optString("fileName", "Video..."));
                } else {
                    views.setViewVisibility(R.id.item_1, View.GONE);
                }

                // Item 2
                if (items.length() >= 2) {
                    JSONObject item = items.getJSONObject(1);
                    views.setViewVisibility(R.id.item_2, View.VISIBLE);
                    views.setTextViewText(R.id.text_2, item.optString("fileName", "Video..."));
                } else {
                    views.setViewVisibility(R.id.item_2, View.GONE);
                }
            } else {
                views.setViewVisibility(R.id.empty_state_text, View.VISIBLE);
                views.setViewVisibility(R.id.recent_container, View.GONE);
            }
        } catch (Exception e) {
            views.setViewVisibility(R.id.empty_state_text, View.VISIBLE);
            views.setViewVisibility(R.id.recent_container, View.GONE);
        }

        // Configurar el clic del botón de descarga
        Intent downloadIntent = new Intent(context, MainActivity.class);
        downloadIntent.setAction(ACTION_DOWNLOAD);
        downloadIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);

        // Portapapeles
        ClipboardManager clipboard = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboard != null && clipboard.hasPrimaryClip()) {
            ClipData clipData = clipboard.getPrimaryClip();
            if (clipData != null && clipData.getItemCount() > 0) {
                CharSequence text = clipData.getItemAt(0).getText();
                if (text != null) {
                    downloadIntent.putExtra("clipboard_url", text.toString());
                }
            }
        }

        PendingIntent downloadPI = PendingIntent.getActivity(context, appWidgetId, downloadIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.download_button, downloadPI);

        // Botón Historial
        Intent historyIntent = new Intent(context, MainActivity.class);
        historyIntent.setAction(ACTION_HISTORY);
        historyIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent historyPI = PendingIntent.getActivity(context, appWidgetId + 100, historyIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.btn_history, historyPI);

        // Botón Ajustes
        Intent settingsIntent = new Intent(context, MainActivity.class);
        settingsIntent.setAction(ACTION_SETTINGS);
        settingsIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        PendingIntent settingsPI = PendingIntent.getActivity(context, appWidgetId + 200, settingsIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        views.setOnClickPendingIntent(R.id.btn_settings, settingsPI);

        // Actualizar el widget
        appWidgetManager.updateAppWidget(appWidgetId, views);
    }

    @Override
    public void onEnabled(Context context) {
        // Widget agregado por primera vez
    }

    @Override
    public void onDisabled(Context context) {
        // Último widget removido
    }
}
