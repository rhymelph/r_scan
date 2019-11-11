package com.rhyme.r_scan;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;

import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.qrcode.QRCodeReader;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.util.EnumMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * RScanPlugin
 */
public class RScanPlugin implements MethodCallHandler {
    private ImageScanHelper scanHelper;

    private RScanPlugin(Registrar registrar) {
        scanHelper = new ImageScanHelper(registrar.context());
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "r_scan");
        channel.setMethodCallHandler(new RScanPlugin(registrar));
        RScanViewPlugin.registerWith(registrar);
    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        if (call.method.equals("scanImagePath")) {
            scanHelper.scanImagePath(call,result);
        } else if(call.method.equals("scanImageUrl")){
            scanHelper.scanImageUrl(call,result);
        } else if(call.method.equals("scanImageMemory")){
            scanHelper.scanImageMemory(call,result);
        }else {
            result.notImplemented();
        }
    }
}
