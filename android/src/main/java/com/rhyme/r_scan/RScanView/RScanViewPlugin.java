package com.rhyme.r_scan.RScanView;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.platform.PlatformViewRegistry;

public class RScanViewPlugin {

    public static void registerWith(PlatformViewRegistry platformViewRegistry, BinaryMessenger messenger) {
        platformViewRegistry
                .registerViewFactory("com.rhyme_lph/r_scan_view", new RScanViewFactory(messenger));
    }
}
