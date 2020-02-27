package com.rhyme.r_scan;

import android.app.Activity;

import androidx.annotation.NonNull;

import com.rhyme.r_scan.RScanCamera.RScanCameraMethodHandler;
import com.rhyme.r_scan.RScanCamera.RScanPermissions;
import com.rhyme.r_scan.RScanView.RScanViewPlugin;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.view.TextureRegistry;

public class MethodCallHandlerImpl implements MethodChannel.MethodCallHandler {
    private ImageScanHelper scanHelper;
    private final Activity activity;
    private final BinaryMessenger messenger;
    private final RScanPermissions cameraPermissions;
    private final RScanPermissions.PermissionsRegistry permissionsRegistry;
    private final TextureRegistry textureRegistry;
    private final MethodChannel methodChannel;
    private final PlatformViewRegistry platformViewRegistry;

    public MethodCallHandlerImpl(
            Activity activity,
            BinaryMessenger messenger,
            RScanPermissions cameraPermissions,
            RScanPermissions.PermissionsRegistry permissionsAdder,
            TextureRegistry textureRegistry,
            PlatformViewRegistry platformViewRegistry) {
        this.activity = activity;
        this.messenger = messenger;
        this.cameraPermissions = cameraPermissions;
        this.permissionsRegistry = permissionsAdder;
        this.textureRegistry = textureRegistry;
        this.platformViewRegistry = platformViewRegistry;

        scanHelper = new ImageScanHelper(activity);
        methodChannel = new MethodChannel(messenger, "com.rhyme_lph/r_scan");
        methodChannel.setMethodCallHandler(this);

        //注册老方式
        RScanViewPlugin.registerWith(this.platformViewRegistry, this.messenger);

        //注册新的方式
        new RScanCameraMethodHandler(
                activity,
                messenger,
                cameraPermissions,
                permissionsAdder,
                textureRegistry
        );

    }

    void stopListening() {
        methodChannel.setMethodCallHandler(null);
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        if (call.method.equals("scanImagePath")) {
            scanHelper.scanImagePath(call, result);
        } else if (call.method.equals("scanImageUrl")) {
            scanHelper.scanImageUrl(call, result);
        } else if (call.method.equals("scanImageMemory")) {
            scanHelper.scanImageMemory(call, result);
        } else {
            result.notImplemented();
        }
    }
}
