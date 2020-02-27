package com.rhyme.r_scan.RScanView;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public class RScanViewFactory extends PlatformViewFactory {
    private final BinaryMessenger messenger;

    RScanViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger=messenger;
    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
        return new FlutterRScanView(context,messenger,i,o);
    }
}
