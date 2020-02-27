package com.rhyme.r_scan.RScanCamera;

import androidx.annotation.Nullable;

import com.google.zxing.Result;
import com.rhyme.r_scan.RScanResultUtils;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;

class RScanMessenger {
    @Nullable
    private EventChannel.EventSink eventSink;
    private static final String scanViewType = "com.rhyme_lph/r_scan_camera";


    RScanMessenger(BinaryMessenger messenger, long eventChannelId) {
        new EventChannel(messenger, scanViewType+"_" + eventChannelId+"/event")
                .setStreamHandler(
                        new EventChannel.StreamHandler() {
                            @Override
                            public void onListen(Object arguments, EventChannel.EventSink sink) {
                                eventSink = sink;
                            }

                            @Override
                            public void onCancel(Object arguments) {
                                eventSink = null;
                            }
                        });
    }


    void send(Result decode) {
        if (eventSink == null) {
            return;
        }
        eventSink.success(RScanResultUtils.toMap(decode));
    }

}
