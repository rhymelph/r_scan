package com.rhyme.r_scan;

import android.content.Context;
import android.content.ContextWrapper;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Handler;
import android.util.Log;


import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.RGBLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.HybridBinarizer;
import com.google.zxing.qrcode.QRCodeReader;

import java.io.File;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.cert.CertificateException;
import java.security.cert.X509Certificate;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

import javax.net.ssl.HttpsURLConnection;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.X509TrustManager;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ImageScanHelper extends ContextWrapper {

    private MultiFormatReader reader = new MultiFormatReader();
    private Executor executor = Executors.newSingleThreadExecutor();
    private Handler handler = new Handler();

    public ImageScanHelper(Context base) {
        super(base);
    }

    private static byte[] yuvs;

    /**
     * 根据Bitmap的ARGB值生成YUV420SP数据。
     *
     * @param inputWidth  image width
     * @param inputHeight image height
     * @param scaled      bmp
     * @return YUV420SP数组
     */
    public byte[] getYUV420sp(int inputWidth, int inputHeight, Bitmap scaled) {
        int[] argb = new int[inputWidth * inputHeight];
        scaled.getPixels(argb, 0, inputWidth, 0, 0, inputWidth, inputHeight);
        /**
         * 需要转换成偶数的像素点，否则编码YUV420的时候有可能导致分配的空间大小不够而溢出。
         */
        int requiredWidth = inputWidth % 2 == 0 ? inputWidth : inputWidth + 1;
        int requiredHeight = inputHeight % 2 == 0 ? inputHeight : inputHeight + 1;
        int byteLength = requiredWidth * requiredHeight * 3 / 2;
        if (yuvs == null || yuvs.length < byteLength) {
            yuvs = new byte[byteLength];
        } else {
            Arrays.fill(yuvs, (byte) 0);
        }
        encodeYUV420SP(yuvs, argb, inputWidth, inputHeight);
        scaled.recycle();
        return yuvs;
    }

    /**
     * RGB转YUV420sp
     *
     * @param yuv420sp inputWidth * inputHeight * 3 / 2
     * @param argb     inputWidth * inputHeight
     * @param width    image width
     * @param height   image height
     */
    private void encodeYUV420SP(byte[] yuv420sp, int[] argb, int width, int height) {
        // 帧图片的像素大小
        final int frameSize = width * height;
        // ---YUV数据---
        int Y, U, V;
        // Y的index从0开始
        int yIndex = 0;
        // UV的index从frameSize开始
        int uvIndex = frameSize;
        // ---颜色数据---
        int R, G, B;
        int rgbIndex = 0;
        // ---循环所有像素点，RGB转YUV---
        for (int j = 0; j < height; j++) {
            for (int i = 0; i < width; i++) {
                R = (argb[rgbIndex] & 0xff0000) >> 16;
                G = (argb[rgbIndex] & 0xff00) >> 8;
                B = (argb[rgbIndex] & 0xff);
                //
                rgbIndex++;
                // well known RGB to YUV algorithm
                Y = ((66 * R + 129 * G + 25 * B + 128) >> 8) + 16;
                U = ((-38 * R - 74 * G + 112 * B + 128) >> 8) + 128;
                V = ((112 * R - 94 * G - 18 * B + 128) >> 8) + 128;
                Y = Math.max(0, Math.min(Y, 255));
                U = Math.max(0, Math.min(U, 255));
                V = Math.max(0, Math.min(V, 255));
                // NV21 has a plane of Y and interleaved planes of VU each sampled by a factor of 2
                // meaning for every 4 Y pixels there are 1 V and 1 U. Note the sampling is every other
                // pixel AND every other scan line.
                // ---Y---
                yuv420sp[yIndex++] = (byte) Y;
                // ---UV---
                if ((j % 2 == 0) && (i % 2 == 0)) {
                    //
                    yuv420sp[uvIndex++] = (byte) V;
                    //
                    yuv420sp[uvIndex++] = (byte) U;
                }
            }
        }
    }

    private Result scanBitmapToResult(Bitmap bitmap) {
        int height = bitmap.getHeight();
        int width = bitmap.getWidth();
        Map<DecodeHintType, Object> hints = new EnumMap<>(DecodeHintType.class);
        hints.put(DecodeHintType.TRY_HARDER, Boolean.TRUE);
        byte[] array = getYUV420sp(width, height, bitmap);
        PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(array,
                width,
                height,
                0,
                0,
                width,
                height,
                false);
        BinaryBitmap binaryBitmap = new BinaryBitmap(new HybridBinarizer(source));
        try {
            return reader.decode(binaryBitmap, hints);
        } catch (NotFoundException e) {
//            e.printStackTrace();
            binaryBitmap = new BinaryBitmap(new GlobalHistogramBinarizer(source));
            try {
                return reader.decode(binaryBitmap, hints);
            } catch (NotFoundException ex) {
//                ex.printStackTrace();
            }
        } finally {
            bitmap.recycle();
        }
        return null;
    }

    private void scanBitmap(Bitmap bitmap, MethodChannel.Result result) {
        Result scanResult = scanBitmapToResult(bitmap);
        if (scanResult != null) {
            Log.d("result", "analyze: decode:" + scanResult.toString());
        }
        handler.post(new Runnable() {
            @Override
            public void run() {
                result.success(RScanResultUtils.toMap(scanResult));
            }
        });
    }

    public void scanImagePath(MethodCall call, final MethodChannel.Result result) {
        final String path = call.argument("path");
        if (path == null) {
            result.error("1001", "please enter your file path", null);
            return;
        }
        final File file = new File(path);
        if (file.isFile()) {
            executor.execute(new Runnable() {
                @Override
                public void run() {
                    Bitmap bitmap = BitmapFactory.decodeFile(path);
                    scanBitmap(bitmap, result);
                }
            });
        } else {
            result.success("");
        }
    }

    public void scanImageUrl(MethodCall call, final MethodChannel.Result result) {
        final String url = call.argument("url");
        if (url == null) {
            result.error("1002", "please enter your url", null);
            return;
        }
        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    URL myUrl = new URL(url);
                    Bitmap bitmap;

                    if (url.startsWith("https")) {
                        HttpsURLConnection connection = (HttpsURLConnection) myUrl.openConnection();
                        connection.setReadTimeout(6 * 60 * 1000);
                        connection.setConnectTimeout(6 * 60 * 1000);
                        connection.setSSLSocketFactory((SSLSocketFactory) SSLSocketFactory.getDefault());
                        connection.connect();
                        bitmap = BitmapFactory.decodeStream(connection.getInputStream());
                    } else {
                        HttpURLConnection connection = (HttpURLConnection) myUrl.openConnection();
                        connection.setReadTimeout(6 * 60 * 1000);
                        connection.setConnectTimeout(6 * 60 * 1000);
                        connection.connect();
                        bitmap = BitmapFactory.decodeStream(connection.getInputStream());
                    }
                    scanBitmap(bitmap, result);
                } catch (Exception e) {
                    Log.d("result", "analyze: error");
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            result.success(null);
                        }
                    });
                }
            }
        });
    }

    public void scanImageMemory(MethodCall call, final MethodChannel.Result result) {
        final byte[] uint8list = call.argument("uint8list");
        if (uint8list == null) {
            result.error("1003", "uint8list is not null", null);
            return;
        }
        executor.execute(new Runnable() {
            @Override
            public void run() {
                try {
                    Bitmap bitmap = BitmapFactory.decodeByteArray(uint8list, 0, uint8list.length);
                    scanBitmap(bitmap, result);
                } catch (Exception e) {
                    Log.d("result", "analyze: error");
                    handler.post(new Runnable() {
                        @Override
                        public void run() {
                            result.success(null);
                        }
                    });
                }
            }
        });
    }
}
