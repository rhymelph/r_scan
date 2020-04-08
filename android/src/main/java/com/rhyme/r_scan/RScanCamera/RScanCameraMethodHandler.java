package com.rhyme.r_scan.RScanCamera;


import android.app.Activity;
import android.hardware.camera2.CameraAccessException;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.camera.core.CameraX;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;


import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

public class RScanCameraMethodHandler implements MethodChannel.MethodCallHandler {
    private static final String scanViewType = "com.rhyme_lph/r_scan_camera";
    private final TextureRegistry textureRegistry;
    private final Activity activity;
    private final RScanPermissions rScanPermissions;
    private final RScanPermissions.PermissionsRegistry permissionsRegistry;
    private final BinaryMessenger messenger;
    private RScanCamera rScanCamera;


    public RScanCameraMethodHandler(
            Activity activity,
            BinaryMessenger messenger,
            RScanPermissions rScanPermissions,
            RScanPermissions.PermissionsRegistry permissionsAdder,
            TextureRegistry textureRegistry) {
        this.activity = activity;
        this.messenger = messenger;

        this.rScanPermissions = rScanPermissions;
        this.permissionsRegistry = permissionsAdder;
        this.textureRegistry = textureRegistry;

        MethodChannel methodChannel = new MethodChannel(messenger, scanViewType + "/method");
        methodChannel.setMethodCallHandler(this);

//        Log.d(TAG, "FlutterRScanView: " + outMetrics.toString());
//        mPreview = buildPreView(outMetrics.widthPixels, outMetrics.heightPixels);
//        CameraX.bindToLifecycle(this, mPreview, buildImageAnalysis());


    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        switch (call.method) {
            case "availableCameras":
                try {
                    result.success(CameraUtils.getAvailableCameras(activity));
                } catch (Exception e) {
                    handleException(e, result);
                }
                break;
            case "initialize":
                if (rScanCamera != null) {
                    rScanCamera.close();
                }
                //请求权限
                rScanPermissions.requestPermissions(
                        activity,
                        permissionsRegistry,
                        (String errCode, String errDesc) -> {
                            if (errCode == null) {
                                try {
                                    instantiateCamera(call, result);
                                } catch (Exception e) {
                                    handleException(e, result);
                                }
                            } else {
                                result.error(errCode, errDesc, null);
                            }
                        });
                break;
            case "startScan":
                if (rScanCamera != null) {
                    rScanCamera.startScan();
                }
                result.success(null);
                break;
            case "stopScan":
                if (rScanCamera != null) {
                    rScanCamera.stopScan();
                }
                result.success(null);
                break;
            case "setAutoFlashMode":
                Boolean isAuto = call.<Boolean>argument("isAuto");
                if (rScanCamera != null) {
                    rScanCamera.setAutoFlash(isAuto == Boolean.TRUE);
                    result.success(true);
                } else {
                    result.success(true);
                }
                break;
            case "setFlashMode":
                Boolean isOpen = call.<Boolean>argument("isOpen");
                if (rScanCamera != null) {
                    try {
                        rScanCamera.enableTorch(isOpen == Boolean.TRUE);
                    } catch (CameraAccessException e) {
                        e.printStackTrace();
                    }
                    result.success(true);
                } else {
                    result.success(true);
                }
                break;
            case "getFlashMode":
                if (rScanCamera != null) {
                    result.success(rScanCamera.isTorchOn());
                } else {
                    result.success(false);
                }
                break;
            case "dispose": {
                if (rScanCamera != null) {
                    rScanCamera.dispose();
                }
                result.success(null);
                break;
            }
            default:
                result.notImplemented();
                break;
        }
    }

    //初始化相机
    private void instantiateCamera(MethodCall call, MethodChannel.Result result) throws CameraAccessException {
        String cameraName = call.argument("cameraName");
        String resolutionPreset = call.argument("resolutionPreset");
        TextureRegistry.SurfaceTextureEntry flutterSurfaceTexture =
                textureRegistry.createSurfaceTexture();

        RScanMessenger rScanMessenger = new RScanMessenger(messenger, flutterSurfaceTexture.id());

        rScanCamera = new RScanCamera(activity, flutterSurfaceTexture, rScanMessenger, cameraName, resolutionPreset);
        rScanCamera.open(result);
    }

    // We move catching CameraAccessException out of onMethodCall because it causes a crash
    // on plugin registration for sdks incompatible with Camera2 (< 21). We want this plugin to
    // to be able to compile with <21 sdks for apps that want the camera and support earlier version.
    @SuppressWarnings("ConstantConditions")
    private void handleException(Exception exception, MethodChannel.Result result) {
        if (exception instanceof CameraAccessException) {
            result.error("CameraAccess", exception.getMessage(), null);
        }
        throw (RuntimeException) exception;
    }

}
