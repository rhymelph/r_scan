package com.rhyme.r_scan.RScanCamera;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.SurfaceTexture;
import android.hardware.Camera;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import android.media.Image;
import android.media.ImageReader;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Size;
import android.view.Surface;

import androidx.annotation.NonNull;

import com.google.zxing.BinaryBitmap;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.PlanarYUVLuminanceSource;
import com.google.zxing.Result;
import com.google.zxing.common.GlobalHistogramBinarizer;
import com.google.zxing.common.HybridBinarizer;

import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;


import io.flutter.plugin.common.MethodChannel;
import io.flutter.view.TextureRegistry;

import static com.rhyme.r_scan.RScanCamera.CameraUtils.computeBestPreviewSize;

class RScanCamera {
    private final String TAG = "RScanCamera";

    private final TextureRegistry.SurfaceTextureEntry flutterTexture;
    private final CameraManager cameraManager;
    private final String cameraName;
    private final Size previewSize;

    private CameraDevice cameraDevice;
    private CameraCaptureSession cameraCaptureSession;
    private ImageReader imageStreamReader;
    private MultiFormatReader reader = new MultiFormatReader();
    private RScanMessenger rScanMessenger;
    private CaptureRequest.Builder captureRequestBuilder;
    private boolean isPlay = true;
    private long lastCurrentTimestamp = 0L;//最后一次的扫描
    private Handler handler = new Handler();
    private Executor executor = Executors.newSingleThreadExecutor();
    private boolean isAutoOpenFlash = false;

    // 上次环境亮度记录的索引
    private int mAmbientBrightnessDarkIndex = 0;
    // 环境亮度历史记录的数组，255 是代表亮度最大值
    private static final long[] AMBIENT_BRIGHTNESS_DARK_LIST = new long[]{255, 255, 255, 255};
    // 亮度低的阀值
    private static final int AMBIENT_BRIGHTNESS_DARK = 600;

    void startScan() {
        isPlay = true;
    }

    void stopScan() {
        isPlay = false;
    }

    void enableTorch(boolean b) throws CameraAccessException {
        if (b) {
            captureRequestBuilder.set(
                    CaptureRequest.FLASH_MODE, CameraMetadata.FLASH_MODE_TORCH);
            cameraCaptureSession.setRepeatingRequest(captureRequestBuilder.build(), null, null);

        } else {
            captureRequestBuilder.set(
                    CaptureRequest.FLASH_MODE, CameraMetadata.FLASH_MODE_OFF);
            cameraCaptureSession.setRepeatingRequest(captureRequestBuilder.build(), null, null);

        }
    }

    void setAutoFlash(boolean b) {
        isAutoOpenFlash = b;
    }


    boolean isTorchOn() {
        try {
            return captureRequestBuilder.get(CaptureRequest.FLASH_MODE) != CaptureRequest.FLASH_MODE_OFF;
        } catch (NullPointerException e) {
            return false;
        }
    }

    // Mirrors camera.dart
    public enum ResolutionPreset {
        low,
        medium,
        high,
        veryHigh,
        ultraHigh,
        max,
    }

    RScanCamera(
            final Activity activity,
            final TextureRegistry.SurfaceTextureEntry flutterTexture,
            final RScanMessenger rScanMessenger,
            final String cameraName,
            final String resolutionPreset) {
        if (activity == null) {
            throw new IllegalStateException("No activity available!");
        }

        this.cameraName = cameraName;
        this.flutterTexture = flutterTexture;
        this.rScanMessenger = rScanMessenger;
        this.cameraManager = (CameraManager) activity.getSystemService(Context.CAMERA_SERVICE);

        //获取预览大小
        ResolutionPreset preset = ResolutionPreset.valueOf(resolutionPreset);
        previewSize = computeBestPreviewSize(cameraName, preset);

    }


    @SuppressLint("MissingPermission")
    void open(@NonNull final MethodChannel.Result result) throws CameraAccessException {

        // Used to steam image byte data to dart side.
        imageStreamReader =
                ImageReader.newInstance(
                        previewSize.getWidth(), previewSize.getHeight(), ImageFormat.YUV_420_888, 2);


        cameraManager.openCamera(
                cameraName,
                new CameraDevice.StateCallback() {
                    @Override
                    public void onOpened(@NonNull CameraDevice device) {
                        cameraDevice = device;
                        try {
                            startPreview();
                        } catch (CameraAccessException e) {
                            result.error("CameraAccess", e.getMessage(), null);
                            close();
                            return;
                        }
                        Map<String, Object> reply = new HashMap<>();
                        reply.put("textureId", flutterTexture.id());
                        reply.put("previewWidth", previewSize.getWidth());
                        reply.put("previewHeight", previewSize.getHeight());
                        result.success(reply);
                    }

                    @Override
                    public void onClosed(@NonNull CameraDevice camera) {
//                        rScanMessenger.sendCameraClosingEvent();
                        super.onClosed(camera);
                    }

                    @Override
                    public void onDisconnected(@NonNull CameraDevice cameraDevice) {
                        close();
//                        rScanMessenger.send(DartMessenger.EventType.ERROR, "The camera was disconnected.");
                    }

                    @Override
                    public void onError(@NonNull CameraDevice cameraDevice, int errorCode) {
                        close();
//                        String errorDescription;
//                        switch (errorCode) {
//                            case ERROR_CAMERA_IN_USE:
//                                errorDescription = "The camera device is in use already.";
//                                break;
//                            case ERROR_MAX_CAMERAS_IN_USE:
//                                errorDescription = "Max cameras in use";
//                                break;
//                            case ERROR_CAMERA_DISABLED:
//                                errorDescription = "The camera device could not be opened due to a device policy.";
//                                break;
//                            case ERROR_CAMERA_DEVICE:
//                                errorDescription = "The camera device has encountered a fatal error";
//                                break;
//                            case ERROR_CAMERA_SERVICE:
//                                errorDescription = "The camera service has encountered a fatal error.";
//                                break;
//                            default:
//                                errorDescription = "Unknown camera error";
//                        }
//                        rScanMessenger.send(DartMessenger.EventType.ERROR, errorDescription);
                    }
                },
                null);

    }


    private void createCaptureSession(
            Surface... surfaces)
            throws CameraAccessException {
        // Close any existing capture session.
        closeCaptureSession();

        // Create a new capture builder.
        captureRequestBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);

        // Build Flutter surface to render to
        SurfaceTexture surfaceTexture = flutterTexture.surfaceTexture();
        surfaceTexture.setDefaultBufferSize(previewSize.getWidth(), previewSize.getHeight());
        Surface flutterSurface = new Surface(surfaceTexture);
        captureRequestBuilder.addTarget(flutterSurface);

        List<Surface> remainingSurfaces = Arrays.asList(surfaces);
        // If it is not preview mode, add all surfaces as targets.
        for (Surface surface : remainingSurfaces) {
            captureRequestBuilder.addTarget(surface);
        }

        // Prepare the callback
        CameraCaptureSession.StateCallback callback =
                new CameraCaptureSession.StateCallback() {
                    @Override
                    public void onConfigured(@NonNull CameraCaptureSession session) {
                        try {
                            if (cameraDevice == null) {
//                                rScanMessenger.send(
//                                        DartMessenger.EventType.ERROR, "The camera was closed during configuration.");
                                return;
                            }
                            cameraCaptureSession = session;
//                            captureRequestBuilder.set(
//                                    CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO);
                            cameraCaptureSession.setRepeatingRequest(captureRequestBuilder.build(), null, null);
                        } catch (CameraAccessException | IllegalStateException | IllegalArgumentException e) {
//                            rScanMessenger.send(DartMessenger.EventType.ERROR, e.getMessage());
                        }
                    }

                    @Override
                    public void onConfigureFailed(@NonNull CameraCaptureSession cameraCaptureSession) {
//                        rScanMessenger.send(
//                                DartMessenger.EventType.ERROR, "Failed to configure camera session.");
                    }
                };

        // Collect all surfaces we want to render to.
        List<Surface> surfaceList = new ArrayList<>();
        surfaceList.add(flutterSurface);
        surfaceList.addAll(remainingSurfaces);
        // Start the session
        cameraDevice.createCaptureSession(surfaceList, callback, null);
    }


    private void startPreview() throws CameraAccessException {
        startPreviewWithImageStream();
    }

    private void setAutoOpenFlash(int width, int height, byte[] array) {
        if (!isAutoOpenFlash) return;
        //像素点的总亮度
        long pixelLightCount = 0L;
        //像素点总数
        long pixelCount = width * height;
        //采集步长
        int step = 10;
//        if(Math.abs(array.length - pixelCount * 1.5f) < 0.00001f){
        for (int i = 0; i < pixelCount; i++) {
            pixelLightCount += (long) array[i] & 0xFFL;
        }
        long cameraLight = pixelLightCount / (pixelCount / step);
        int lightSize = AMBIENT_BRIGHTNESS_DARK_LIST.length;
        AMBIENT_BRIGHTNESS_DARK_LIST[mAmbientBrightnessDarkIndex = mAmbientBrightnessDarkIndex % lightSize] = cameraLight;
        mAmbientBrightnessDarkIndex++;
        boolean isDarkEnv = true;
        // 判断在时间范围 AMBIENT_BRIGHTNESS_WAIT_SCAN_TIME * lightSize 内是不是亮度过暗
        for (long ambientBrightness : AMBIENT_BRIGHTNESS_DARK_LIST) {
            if (ambientBrightness > AMBIENT_BRIGHTNESS_DARK) {
                isDarkEnv = false;
                break;
            }
        }
        Log.d(TAG, "decodeImage: light:" + cameraLight);
        if (isDarkEnv && !isTorchOn()) {
            try {
                enableTorch(Boolean.TRUE);
            } catch (CameraAccessException e) {
                e.printStackTrace();
            }
        }
//        }
    }

    private Result decodeImage(Image image) {
        ByteBuffer buffer = image.getPlanes()[0].getBuffer();
        byte[] array = new byte[buffer.remaining()];
        buffer.get(array);

        //图片宽度
        int width = image.getWidth();
        //图片高度
        int height = image.getHeight();

        setAutoOpenFlash(width, height, array);

        PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(array,
                width,
                height,
                0,
                0,
                width,
                height,
                false);
        BinaryBitmap binaryBitmap = new BinaryBitmap(new GlobalHistogramBinarizer(source));
        try {
            return reader.decode(binaryBitmap);
        } catch (Exception e) {
            binaryBitmap = new BinaryBitmap(new GlobalHistogramBinarizer(source));
            try {
                return reader.decode(binaryBitmap);
            } catch (NotFoundException ex) {
//                ex.printStackTrace();
            }
//            Log.d(TAG, "decodeImage: rotate45");
//            binaryBitmap = binaryBitmap.rotateCounterClockwise45();
//            try {
//                return reader.decodeWithState(binaryBitmap);
//            } catch (NotFoundException ex) {
//                Log.d(TAG, "decodeImage: rotate90");
//                //          Log.d(TAG, "analyze: error ");
//                binaryBitmap = binaryBitmap.rotateCounterClockwise45();
//                try {
//                    return reader.decodeWithState(binaryBitmap);
//                } catch (NotFoundException ex2) {
//                    //          Log.d(TAG, "analyze: error ");
//
//                }
//            }
//          Log.d(TAG, "analyze: error ");
        } finally {
            buffer.clear();
            reader.reset();
        }
        return null;
    }


    private synchronized void startPreviewWithImageStream()
            throws CameraAccessException {
        createCaptureSession(imageStreamReader.getSurface());

        imageStreamReader.setOnImageAvailableListener(new ImageReader.OnImageAvailableListener() {
            @Override
            public void onImageAvailable(ImageReader imageReader) {
                executor.execute(new Runnable() {
                    @Override
                    public void run() {
                        long currentTimestamp = System.currentTimeMillis();
                        if (currentTimestamp - lastCurrentTimestamp >= 1L && isPlay == Boolean.TRUE) {
                            Image image = imageReader.acquireLatestImage();
                            if (image == null) return;
                            if (ImageFormat.YUV_420_888 != image.getFormat()) {
                                Log.d(TAG, "analyze: " + image.getFormat());
                                return;
                            }
                            ByteBuffer buffer = image.getPlanes()[0].getBuffer();
                            byte[] array = new byte[buffer.remaining()];
                            buffer.get(array);
                            int height = image.getHeight();
                            int width = image.getWidth();
                            //优先图片翻转解析（主要解决习惯性竖屏扫条码问题，二维码不受影响）
                            PlanarYUVLuminanceSource source = new PlanarYUVLuminanceSource(getRotatedData(array, width, height),
                                    height,
                                    width,
                                    0,
                                    0,
                                    height,
                                    width,
                                    true);
                            BinaryBitmap binaryBitmap = new BinaryBitmap(new HybridBinarizer(source));
                            try {
                                final Result decode = reader.decode(binaryBitmap);
                                if (decode != null) {
                                    handler.post(new Runnable() {
                                        @Override
                                        public void run() {
                                            rScanMessenger.send(decode);
                                        }
                                    });
                                }
                            } catch (NotFoundException e) {
                                //原图解析
                                source = new PlanarYUVLuminanceSource(array,
                                        width,
                                        height,
                                        0,
                                        0,
                                        width,
                                        height,
                                        false);
                                binaryBitmap = new BinaryBitmap(new HybridBinarizer(source));
                                try {
                                    final Result decode = reader.decode(binaryBitmap);
                                    if (decode != null) {
                                        handler.post(new Runnable() {
                                            @Override
                                            public void run() {
                                                rScanMessenger.send(decode);
                                            }
                                        });
                                    }
                                } catch (Exception e1) {
                                    buffer.clear();
                                }
                            } catch (Exception e) {
                                buffer.clear();
                            }
                            lastCurrentTimestamp = currentTimestamp;
                            image.close();
                        }
                    }
                });
            }}, handler);
    }

    private byte[] getRotatedData(byte[] data, int width, int height) {
        byte[] rotatedData = new byte[data.length];
        for (int y = 0; y < height; y++) {
            for (int x = 0; x < width; x++)
                rotatedData[x * height + height - y - 1] = data[x + y * width];
        }
        return rotatedData;
    }

    private void closeCaptureSession() {
        if (cameraCaptureSession != null) {
            cameraCaptureSession.close();
            cameraCaptureSession = null;
        }
    }

    void close() {
        closeCaptureSession();

        if (cameraDevice != null) {
            cameraDevice.close();
            cameraDevice = null;
        }
        if (imageStreamReader != null) {
            imageStreamReader.close();
            imageStreamReader = null;
        }
    }

    void dispose() {
        close();
        flutterTexture.release();
    }

}
