package com.rhyme.r_scan;


import android.app.Activity;

import androidx.annotation.NonNull;

import com.rhyme.r_scan.RScanCamera.RScanPermissions;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugin.platform.PlatformViewRegistry;
import io.flutter.view.TextureRegistry;

/**
 * RScanPlugin
 */
//public class RScanPlugin implements MethodChannel.MethodCallHandler {
//    private ImageScanHelper scanHelper;
//
//    private RScanPlugin(Registrar registrar) {
//        scanHelper = new ImageScanHelper(registrar.context());
//    }
//
//    public static void registerWith(Registrar registrar) {
//        final MethodChannel channel = new MethodChannel(registrar.messenger(), "r_scan");
//        channel.setMethodCallHandler(new RScanPlugin(registrar));
//        RScanViewPlugin.registerWith(registrar);
//    }
//
//    @Override
//    public void onMethodCall(MethodCall call, Result result) {
//        if (call.method.equals("scanImagePath")) {
//            scanHelper.scanImagePath(call,result);
//        } else if(call.method.equals("scanImageUrl")){
//            scanHelper.scanImageUrl(call,result);
//        } else if(call.method.equals("scanImageMemory")){
//            scanHelper.scanImageMemory(call,result);
//        } else {
//            result.notImplemented();
//        }
//    }
//}

/**
 * RScanPlugin
 */
public class RScanPlugin implements FlutterPlugin, ActivityAware {
    private MethodCallHandlerImpl methodCallHandler;
    private FlutterPluginBinding flutterPluginBinding;


    public static void registerWith(Registrar registrar) {
        RScanPlugin plugin = new RScanPlugin();
        plugin.maybeStartListening(
                registrar.activity(),
                registrar.messenger(),
                registrar::addRequestPermissionsResultListener,
                registrar.view(), registrar.platformViewRegistry());

    }

    private void maybeStartListening(
            Activity activity,
            BinaryMessenger messenger,
            RScanPermissions.PermissionsRegistry permissionsRegistry,
            TextureRegistry textureRegistry, PlatformViewRegistry platformViewRegistry) {
        methodCallHandler =
                new MethodCallHandlerImpl(
                        activity, messenger, new RScanPermissions(), permissionsRegistry, textureRegistry, platformViewRegistry);
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = binding;

    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        this.flutterPluginBinding = null;

    }

    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {

        maybeStartListening(
                binding.getActivity(),
                flutterPluginBinding.getBinaryMessenger(),
                binding::addRequestPermissionsResultListener,
                flutterPluginBinding.getTextureRegistry(),
                flutterPluginBinding.getPlatformViewRegistry());
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();

    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);

    }

    @Override
    public void onDetachedFromActivity() {
        if (methodCallHandler == null) {
            // Could be on too low of an SDK to have started listening originally.
            return;
        }
        methodCallHandler.stopListening();
        methodCallHandler = null;
    }
}
