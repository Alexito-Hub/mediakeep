package com.mediakeep.aur;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.TextView;

import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;

import java.util.Map;

import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory;

class ListTileNativeAdFactory implements NativeAdFactory {
    private final Context context;

    ListTileNativeAdFactory(Context context) {
        this.context = context;
    }

    @Override
    public NativeAdView createNativeAd(
            NativeAd nativeAd, Map<String, Object> customOptions) {
        NativeAdView adView = (NativeAdView) LayoutInflater.from(context)
                .inflate(R.layout.list_tile_native_ad, null);

        TextView headlineView = adView.findViewById(R.id.ad_headline);
        TextView bodyView = adView.findViewById(R.id.ad_body);
        ImageView iconView = adView.findViewById(R.id.ad_app_icon);
        Button callToActionView = adView.findViewById(R.id.ad_call_to_action);

        headlineView.setText(nativeAd.getHeadline());
        adView.setHeadlineView(headlineView);

        if (nativeAd.getBody() == null) {
            bodyView.setVisibility(View.INVISIBLE);
        } else {
            bodyView.setVisibility(View.VISIBLE);
            bodyView.setText(nativeAd.getBody());
            adView.setBodyView(bodyView);
        }

        if (nativeAd.getIcon() == null) {
            iconView.setVisibility(View.GONE);
        } else {
            iconView.setVisibility(View.VISIBLE);
            iconView.setImageDrawable(nativeAd.getIcon().getDrawable());
            adView.setIconView(iconView);
        }

        if (nativeAd.getCallToAction() == null) {
            callToActionView.setVisibility(View.INVISIBLE);
        } else {
            callToActionView.setVisibility(View.VISIBLE);
            callToActionView.setText(nativeAd.getCallToAction());
            adView.setCallToActionView(callToActionView);
        }

        adView.setNativeAd(nativeAd);

        return adView;
    }
}
