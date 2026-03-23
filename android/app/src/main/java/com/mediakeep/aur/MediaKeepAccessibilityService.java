package com.mediakeep.aur;

import android.accessibilityservice.AccessibilityService;
import android.content.ClipboardManager;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.util.Patterns;
import android.view.accessibility.AccessibilityEvent;
import android.util.Log;

/**
 * MediaKeepAccessibilityService
 *
 * Listens to clipboard changes via ClipboardManager.OnPrimaryClipChangedListener.
 * Accessibility services are allowed to read the clipboard on Android 10+
 * without the overlay workaround.
 *
 * When a valid, supported URL is detected, it dispatches it to
 * ClipboardMonitorService with action PROCESS_URL (no polling, no overlay).
 */
public class MediaKeepAccessibilityService extends AccessibilityService {

    private static final String TAG = "MKAccessibilityService";
    private ClipboardManager clipboardManager;
    private String lastUrl = "";

    private final ClipboardManager.OnPrimaryClipChangedListener clipListener =
            this::onClipboardChanged;

    @Override
    public void onServiceConnected() {
        super.onServiceConnected();
        clipboardManager = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboardManager != null) {
            clipboardManager.addPrimaryClipChangedListener(clipListener);
            Log.d(TAG, "Clipboard listener registered");
        }
    }

    private void onClipboardChanged() {
        try {
            if (clipboardManager == null || !clipboardManager.hasPrimaryClip()) return;

            ClipData clip = clipboardManager.getPrimaryClip();
            if (clip == null || clip.getItemCount() == 0) return;

            CharSequence text = clip.getItemAt(0).getText();
            if (text == null) return;

            String fullText = text.toString();
            String extractedUrl = extractSupportedUrl(fullText);

            if (extractedUrl != null) {
                if (extractedUrl.equals(lastUrl)) return; // already processed
                Log.d(TAG, "Valid URL extracted: " + extractedUrl);
                lastUrl = extractedUrl;

                Intent intent = new Intent(this, ClipboardMonitorService.class);
                intent.setAction("PROCESS_URL");
                intent.putExtra("url", extractedUrl);

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                    startForegroundService(intent);
                } else {
                    startService(intent);
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error reading clipboard: " + e.getMessage());
        }
    }

    private String extractSupportedUrl(String text) {
        if (text == null || text.isEmpty()) return null;

        java.util.regex.Matcher matcher = Patterns.WEB_URL.matcher(text);
        while (matcher.find()) {
            String url = matcher.group();
            if (url == null) continue;

            String lower = url.toLowerCase();
            if (lower.contains("tiktok.com") ||
                lower.contains("instagram.com") ||
                lower.contains("facebook.com") ||
                lower.contains("fb.watch") ||
                lower.contains("youtube.com") ||
                lower.contains("youtu.be") ||
                lower.contains("twitter.com") ||
                lower.contains("x.com") ||
                lower.contains("spotify.com") ||
                lower.contains("threads.net")) {
                return url;
            }
        }
        return null;
    }

    private final android.os.Handler handler = new android.os.Handler(android.os.Looper.getMainLooper());
    private final Runnable checkRunnable = this::checkClipboardSafe;
    private long lastClipTimestamp = -1;

    private void checkClipboardSafe() {
        Log.d(TAG, "checkClipboardSafe() executed");
        if (clipboardManager == null) return;

        // Skip hasPrimaryClip() block as Android 14 MIUI sometimes returns false erroneously
        // or just wait for the actual data.
        
        try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.S) {
                android.content.ClipDescription desc = clipboardManager.getPrimaryClipDescription();
                if (desc != null) {
                    long ts = desc.getTimestamp();
                    if (lastClipTimestamp == ts) return; // Unchanged
                    lastClipTimestamp = ts;
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "Error checking description: " + e.getMessage());
        }
        
        Log.d(TAG, "Proceeding to read actual clipboard data...");
        onClipboardChanged();
    }

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        if (event == null) return;
        int type = event.getEventType();

        if (type == AccessibilityEvent.TYPE_VIEW_CLICKED ||
            type == AccessibilityEvent.TYPE_NOTIFICATION_STATE_CHANGED ||
            type == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED ||
            type == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            
            // Debounce and delay: 500ms allows the app like TikTok to actually write the URL 
            // into the clipboard manager before we attempt to parse it. 
            // Synchronous checks fail because the clipboard is still empty at 0ms!
            handler.removeCallbacks(checkRunnable);
            handler.postDelayed(checkRunnable, 500);
        }
    }


    @Override
    public void onInterrupt() {
        Log.d(TAG, "Service interrupted");
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        if (clipboardManager != null) {
            clipboardManager.removePrimaryClipChangedListener(clipListener);
        }
        Log.d(TAG, "Service destroyed, clipboard listener removed");
    }
}
