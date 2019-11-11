package com.rhyme.r_scan;

import io.flutter.plugin.common.PluginRegistry;

public class RScanViewPlugin {
    public static void registerWith(PluginRegistry.Registrar registrar) {
        registrar.platformViewRegistry()
                .registerViewFactory("com.rhyme/r_scan_view", new RScanViewFactory(registrar.messenger()));
    }
}
